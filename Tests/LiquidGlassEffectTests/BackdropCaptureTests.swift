import XCTest
import UIKit
import Metal
@testable import LiquidGlassEffect

@MainActor
final class BackdropCaptureTests: XCTestCase {
    private let captureRect = CGRect(x: 20, y: 30, width: 8, height: 8)

    func testCaptureUsesTopLeftUIKitCoordinates() throws {
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        let bridge = ZeroCopyBridge(device: device)
        bridge.setupBuffer(width: 8, height: 8)
        let frame = try XCTUnwrap(bridge.renderFrame(captureRect: captureRect) { context in
            context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 4))
            context.setFillColor(red: 0, green: 0, blue: 1, alpha: 1)
            context.fill(CGRect(x: 0, y: 4, width: 8, height: 4))
        })
        XCTAssertEqual(frame.captureRect, captureRect)
        let top = try pixel(frame.texture, x: 2, y: 1, device: device)
        let bottom = try pixel(frame.texture, x: 2, y: 6, device: device)
        XCTAssertGreaterThan(top[2], 240, "Top of the texture must contain UIKit's top red band")
        XCTAssertLessThan(top[0], 10)
        XCTAssertGreaterThan(bottom[0], 240, "Bottom of the texture must contain UIKit's bottom blue band")
        XCTAssertLessThan(bottom[2], 10)
    }

    func testRetainedFrameIsNotOverwrittenBySubsequentCaptures() throws {
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        let bridge = ZeroCopyBridge(device: device)
        bridge.setupBuffer(width: 8, height: 8)
        let original = try solidFrame(bridge, red: 1, green: 0, blue: 0)
        let initialPixel = try pixel(original.texture, x: 2, y: 2, device: device)
        // Exceed the old two-slot ring and the periodic texture-cache flush.
        for _ in 0..<40 {
            let replacement = try solidFrame(bridge, red: 0, green: 1, blue: 0)
            XCTAssertFalse(original.texture === replacement.texture)
        }
        XCTAssertEqual(try pixel(original.texture, x: 2, y: 2, device: device), initialPixel)
    }

    func testResizeAndReleasePreserveRetainedFrame() throws {
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        let bridge = ZeroCopyBridge(device: device)
        bridge.setupBuffer(width: 8, height: 8)
        let original = try solidFrame(bridge, red: 1, green: 0, blue: 0)
        let initialPixel = try pixel(original.texture, x: 1, y: 1, device: device)
        bridge.setupBuffer(width: 16, height: 16)
        let resized = try solidFrame(bridge, red: 0, green: 1, blue: 0)
        XCTAssertEqual(resized.texture.width, 16)
        bridge.releaseBuffers()
        XCTAssertEqual(try pixel(original.texture, x: 1, y: 1, device: device), initialPixel)
    }

    func testCompatibilityTextureOutlivesCaptureLease() throws {
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        let bridge = ZeroCopyBridge(device: device)
        bridge.setupBuffer(width: 8, height: 8)
        let texture = try XCTUnwrap(bridge.render { context in
            context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        })
        let initialPixel = try pixel(texture, x: 1, y: 1, device: device)
        for _ in 0..<5 { _ = try solidFrame(bridge, red: 0, green: 0, blue: 1) }
        bridge.releaseBuffers()
        XCTAssertEqual(try pixel(texture, x: 1, y: 1, device: device), initialPixel)
    }

    func testSharedBlurRemainsUsableAfterSuccessfulProducerCompletes() throws {
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        let bridge = ZeroCopyBridge(device: device)
        bridge.setupBuffer(width: 8, height: 8)
        let frame = try solidFrame(bridge, red: 1, green: 0, blue: 0)
        var entry: ScatteredBackdropTexture?
        weak var weakProducer: MTLCommandBuffer?

        try autoreleasepool {
            let queue = try XCTUnwrap(device.makeCommandQueue())
            let producer = try XCTUnwrap(queue.makeCommandBuffer())
            weakProducer = producer
            let pass = LiquidGlassBlurPass()
            let output = try XCTUnwrap(pass.encode(source: frame.texture, radius: 1,
                                                  pixelsPerPoint: 1, commandBuffer: producer))
            entry = ScatteredBackdropTexture(texture: output, producer: producer)
            producer.commit()
            producer.waitUntilCompleted()
            XCTAssertEqual(producer.status, .completed, String(describing: producer.error))
            XCTAssertTrue(try XCTUnwrap(entry).isUsable)
        }

        let completedEntry = try XCTUnwrap(entry)
        XCTAssertTrue(completedEntry.isUsable,
                      "Successful output must remain usable after the caller releases its producer")
        XCTAssertGreaterThan(try pixel(completedEntry.texture, x: 2, y: 2, device: device)[2], 240)
        // Metal may keep completed command buffers alive internally. Record
        // whether the weak reference cleared, but do not make driver retention
        // timing a flaky assertion. A cleared reference proves that the entry
        // itself did not retain its producer; source declares that link weak.
        let ownership = XCTAttachment(string: weakProducer == nil
            ? "Producer deallocated while its shared blur entry remained alive: verified weak ownership."
            : "Metal still retains the completed producer; entry remains usable. Producer deallocation timing is not asserted.")
        ownership.name = "Shared blur producer lifetime"
        ownership.lifetime = .keepAlways
        add(ownership)
    }

    func testFailedSharedBlurDoesNotInvalidateReplacementEntry() throws {
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        let bridge = ZeroCopyBridge(device: device)
        bridge.setupBuffer(width: 8, height: 8)
        let frame = try solidFrame(bridge, red: 1, green: 0, blue: 0)
        let queue = try XCTUnwrap(device.makeCommandQueue())
        let key = Float(1).bitPattern

        let originalProducer = try XCTUnwrap(queue.makeCommandBuffer())
        let originalOutput = try XCTUnwrap(LiquidGlassBlurPass().encode(
            source: frame.texture, radius: 1, pixelsPerPoint: 1, commandBuffer: originalProducer))
        let original = ScatteredBackdropTexture(texture: originalOutput, producer: originalProducer)
        originalProducer.commit()
        originalProducer.waitUntilCompleted()
        XCTAssertEqual(originalProducer.status, .completed, String(describing: originalProducer.error))
        frame.scatteredTextures[key] = original
        XCTAssertTrue(original.isUsable)

        // Exercise error bookkeeping directly; no GPU fault is induced or claimed.
        original.markFailed()
        XCTAssertFalse(original.isUsable)
        let replacementProducer = try XCTUnwrap(queue.makeCommandBuffer())
        let replacementOutput = try XCTUnwrap(LiquidGlassBlurPass().encode(
            source: frame.texture, radius: 1, pixelsPerPoint: 1, commandBuffer: replacementProducer))
        let replacement = ScatteredBackdropTexture(texture: replacementOutput, producer: replacementProducer)
        replacementProducer.commit()
        replacementProducer.waitUntilCompleted()
        XCTAssertEqual(replacementProducer.status, .completed, String(describing: replacementProducer.error))
        frame.scatteredTextures[key] = replacement

        // Model the late original completion: failure sticks to the old entry,
        // and identity-based cleanup must leave its replacement in the cache.
        original.markFailed()
        if frame.scatteredTextures[key] === original {
            frame.scatteredTextures.removeValue(forKey: key)
        }
        XCTAssertFalse(original.isUsable)
        XCTAssertTrue(replacement.isUsable)
        XCTAssertTrue(frame.scatteredTextures[key] === replacement)
        XCTAssertGreaterThan(try pixel(replacement.texture, x: 2, y: 2, device: device)[2], 240)
    }

    func testExternalShadowTracksSizeAndSameSizeRadiusUpdates() throws {
        let config = LiquidGlassConfig()
        let view = LiquidGlassView(config)
        XCTAssertTrue(view.isMetalAvailable)
        view.bounds = CGRect(x: 0, y: 0, width: 120, height: 60)
        view.updateCornerRadius(90)
        view.layoutIfNeeded()
        try assertDefaultShadowPath(view, radius: 30)
        XCTAssertEqual(view.layer.shadowRadius, 3.5)
        XCTAssertEqual(view.layer.shadowOffset, CGSize(width: 0, height: 1.5))
        XCTAssertEqual(view.layer.shadowOpacity, 0.10, accuracy: 0.0001)
        XCTAssertFalse(view.layer.masksToBounds)
        XCTAssertFalse(view.subviews.contains { $0 is ShadowView },
                       "The drop shadow must sit behind Metal, not in a ShadowView overlay")

        view.bounds = CGRect(x: 0, y: 0, width: 80, height: 40)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        try assertDefaultShadowPath(view, radius: 20)

        // Do not lay out after these same-size updates: the path must change
        // immediately rather than retaining the previous radius until layout.
        let unchangedBounds = view.bounds
        view.updateCornerRadius(8)
        XCTAssertEqual(view.bounds, unchangedBounds)
        try assertDefaultShadowPath(view, radius: 8)
        view.updateCornerRadius(1_000)
        XCTAssertEqual(view.bounds, unchangedBounds)
        try assertDefaultShadowPath(view, radius: 20)

        view.updateConfiguration(LiquidGlassConfig(shadowOverlay: false))
        XCTAssertEqual(view.layer.shadowOpacity, 0)
        XCTAssertNil(view.layer.shadowPath)
        view.updateConfiguration(config)
        XCTAssertEqual(view.layer.shadowOpacity, 0.10, accuracy: 0.0001)
        try assertDefaultShadowPath(view, radius: 20)
        XCTAssertFalse(view.subviews.contains { $0 is ShadowView })
    }

    func testCustomShapesUseMetalAlphaShadowAndRestoreDefaultPath() throws {
        let config = LiquidGlassConfig()
        let view = LiquidGlassView(config)
        XCTAssertTrue(view.isMetalAvailable)
        view.bounds = CGRect(x: 0, y: 0, width: 180, height: 100)
        view.updateCornerRadius(14)
        view.layoutIfNeeded()
        try assertDefaultShadowPath(view, radius: 14)

        view.frames = [CGRect(x: 10, y: 10, width: 50, height: 30),
                       CGRect(x: 80, y: 20, width: 60, height: 40)]
        XCTAssertNil(view.layer.shadowPath,
                     "A custom rectangle collection must not cast a whole-bounds shadow")
        XCTAssertEqual(view.layer.shadowOpacity, 0.10, accuracy: 0.0001)
        view.frames = []
        try assertDefaultShadowPath(view, radius: 14)

        var roundness = config.uniforms
        roundness.cornerRoundnessExponent = 4
        view.updateConfiguration(LiquidGlassConfig(uniforms: roundness))
        XCTAssertNil(view.layer.shadowPath,
                     "A noncircular corner must cast from the rendered alpha, not a circular path")
        XCTAssertEqual(view.layer.shadowOpacity, 0.10, accuracy: 0.0001)
        view.updateConfiguration(config)
        try assertDefaultShadowPath(view, radius: 14)

        var merged = config.uniforms
        merged.shapeMergeSmoothness = 0.1
        view.updateConfiguration(LiquidGlassConfig(uniforms: merged))
        XCTAssertNil(view.layer.shadowPath,
                     "Smooth-union geometry must use the Metal alpha silhouette")
        XCTAssertEqual(view.layer.shadowOpacity, 0.10, accuracy: 0.0001)
        view.updateConfiguration(config)
        try assertDefaultShadowPath(view, radius: 14)
    }

    private func assertDefaultShadowPath(_ view: LiquidGlassView, radius: CGFloat,
                                         file: StaticString = #filePath, line: UInt = #line) throws {
        let path = try XCTUnwrap(view.layer.shadowPath, file: file, line: line)
        let expected = UIBezierPath(roundedRect: view.bounds, cornerRadius: radius).cgPath
        XCTAssertTrue(path == expected, "Shadow must match the clamped circular glass contour",
                      file: file, line: line)
        // Bezier extrema can differ from the input bounds by floating-point
        // roundoff even when the complete CGPath is exactly equal above.
        let box = path.boundingBoxOfPath
        let accuracy: CGFloat = 1e-6
        XCTAssertEqual(box.minX, view.bounds.minX, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(box.minY, view.bounds.minY, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(box.width, view.bounds.width, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(box.height, view.bounds.height, accuracy: accuracy, file: file, line: line)
    }

    private func solidFrame(_ bridge: ZeroCopyBridge, red: CGFloat, green: CGFloat, blue: CGFloat) throws -> CapturedBackdrop {
        try XCTUnwrap(bridge.renderFrame(captureRect: captureRect) { context in
            context.setFillColor(red: red, green: green, blue: blue, alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
        })
    }

    private func pixel(_ texture: MTLTexture, x: Int, y: Int, device: MTLDevice) throws -> [UInt8] {
        let queue = try XCTUnwrap(device.makeCommandQueue())
        let command = try XCTUnwrap(queue.makeCommandBuffer())
        let readback = try XCTUnwrap(device.makeBuffer(length: 256, options: .storageModeShared))
        let encoder = try XCTUnwrap(command.makeBlitCommandEncoder())
        encoder.copy(from: texture, sourceSlice: 0, sourceLevel: 0,
                     sourceOrigin: MTLOrigin(x: x, y: y, z: 0),
                     sourceSize: MTLSize(width: 1, height: 1, depth: 1),
                     to: readback, destinationOffset: 0, destinationBytesPerRow: 256, destinationBytesPerImage: 256)
        encoder.endEncoding()
        command.commit()
        command.waitUntilCompleted()
        XCTAssertEqual(command.status, .completed, String(describing: command.error))
        return Array(UnsafeBufferPointer(start: readback.contents().assumingMemoryBound(to: UInt8.self), count: 4))
    }
}
