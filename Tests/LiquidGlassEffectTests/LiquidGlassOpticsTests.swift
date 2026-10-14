import XCTest
import Metal
import UIKit
@testable import LiquidGlassEffect

/// These tests execute the production pipeline and MPS kernel on a Metal device.
/// Missing Metal, shader compilation, GPU errors and readback errors are failures.
final class LiquidGlassOpticsTests: XCTestCase {
    private var renderer: LiquidGlassRenderer!
    private var queue: MTLCommandQueue!

    override func setUpWithError() throws {
        try super.setUpWithError()
        renderer = try XCTUnwrap(LiquidGlassRenderer.shared, "The production Metal shader must load on the iOS simulator")
        queue = try XCTUnwrap(renderer.device.makeCommandQueue())
    }

    func testUniformLayoutMatchesMetalABI() {
        // Metal float2 alignment is 8; float4 and the rectangle array align to 16.
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.alignment, 16)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.size, 400)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.stride, 400)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.resolution), 0)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.contentsScale), 8)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.touchPoint), 16)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.shapeMergeSmoothness), 24)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.cornerRadius), 28)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.cornerRoundnessExponent), 32)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.materialTint), 48)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.glassThickness), 64)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.refractiveIndex), 68)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.dispersionStrength), 72)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.fresnelDistanceRange), 76)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.fresnelIntensity), 80)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.fresnelEdgeSharpness), 84)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.glareDistanceRange), 88)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.glareAngleConvergence), 92)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.glareOppositeSideBias), 96)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.glareIntensity), 100)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.glareEdgeSharpness), 104)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.glareDirectionOffset), 108)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.uvOffset), 112)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.uvScale), 120)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.rectangleCount), 128)
        XCTAssertEqual(MemoryLayout<LiquidGlassUniforms>.offset(of: \.rectangles), 144)
    }

    func testOverscanMappingPreservesCenterWithoutShrinkingBackdrop() throws {
        let view = CGRect(x: 100, y: 200, width: 200, height: 100)
        let capture = view.insetBy(dx: -10, dy: -5)
        let mapping = try XCTUnwrap(LiquidGlassSampling.mapping(viewRect: view, captureRect: capture))
        XCTAssertEqual(mapping.scale.x, 1 / 1.1, accuracy: 0.00001)
        XCTAssertEqual(mapping.scale.y, 1 / 1.1, accuracy: 0.00001)
        XCTAssertEqual(mapping.offset.x, 0.05 / 1.1, accuracy: 0.00001)
        XCTAssertEqual(mapping.offset.y, 0.05 / 1.1, accuracy: 0.00001)
        XCTAssertEqual(mapping.offset.x + mapping.scale.x / 2, 0.5, accuracy: 0.00001)
        XCTAssertEqual(mapping.offset.y + mapping.scale.y / 2, 0.5, accuracy: 0.00001)
    }

    func testMagnificationSamplesCenteredSubregion() throws {
        let view = CGRect(x: 50, y: 80, width: 200, height: 100)
        let mapping = try XCTUnwrap(LiquidGlassSampling.mapping(viewRect: view, captureRect: view, magnification: 2))
        XCTAssertEqual(mapping.offset, SIMD2<Float>(0.25, 0.25))
        XCTAssertEqual(mapping.scale, SIMD2<Float>(0.5, 0.5))
    }

    func testSharedCaptureMappingUsesTopLeftWindowCoordinates() throws {
        let mapping = try XCTUnwrap(LiquidGlassSampling.mapping(
            viewRect: CGRect(x: 60, y: 90, width: 100, height: 50),
            captureRect: CGRect(x: 10, y: 20, width: 500, height: 350)))
        XCTAssertEqual(mapping.offset.x, 0.1, accuracy: 0.00001)
        XCTAssertEqual(mapping.offset.y, 0.2, accuracy: 0.00001)
        XCTAssertEqual(mapping.scale.x, 0.2, accuracy: 0.00001)
        XCTAssertEqual(mapping.scale.y, 1 / 7, accuracy: 0.00001)
        XCTAssertNil(LiquidGlassSampling.mapping(viewRect: .zero, captureRect: CGRect(x: 0, y: 0, width: 50, height: 50)))
        XCTAssertNil(LiquidGlassSampling.mapping(viewRect: CGRect(x: 0, y: 0, width: 50, height: 50), captureRect: .zero))
        XCTAssertNil(LiquidGlassSampling.mapping(viewRect: CGRect(x: 0, y: 0, width: 50, height: 50), captureRect: CGRect(x: 0, y: 0, width: 50, height: 50), magnification: 0))
    }

    func testNeutralOpticsPreserveColorsAndTopLeftOrientationOnGPU() throws {
        let width = 64, height = 64
        let source = try texture(width: width, height: height) { x, y in
            switch (x < 32, y < 32) {
            case (true, true): return Pixel(r: 220, g: 35, b: 25)
            case (false, true): return Pixel(r: 20, g: 210, b: 55)
            case (true, false): return Pixel(r: 35, g: 65, b: 230)
            case (false, false): return Pixel(r: 230, g: 190, b: 40)
            }
        }
        let image = try render(source: source, uniforms: neutralUniforms(width: width, height: height))
        assertPixel(image[16, 16], equals: Pixel(r: 220, g: 35, b: 25))
        assertPixel(image[48, 16], equals: Pixel(r: 20, g: 210, b: 55))
        assertPixel(image[16, 48], equals: Pixel(r: 35, g: 65, b: 230))
        assertPixel(image[48, 48], equals: Pixel(r: 230, g: 190, b: 40))
        assertPixel(image[1, 30], equals: Pixel(r: 220, g: 35, b: 25))
    }

    func testShaderUsesSharpRimAndSeparateScatteredBodyTextures() throws {
        let sharp = try texture(width: 64, height: 64) { _, _ in Pixel(r: 240, g: 0, b: 0) }
        let scattered = try texture(width: 64, height: 64) { _, _ in Pixel(r: 0, g: 0, b: 220) }
        let image = try render(source: sharp, soft: scattered, uniforms: neutralUniforms(width: 64, height: 64))
        assertPixel(image[32, 32], equals: Pixel(r: 0, g: 0, b: 220))
        XCTAssertGreaterThan(image[32, 0].r, 235, "The outer rim must sample the sharp texture")
        XCTAssertLessThan(image[32, 0].b, 35, "The refracting rim must not be uniformly blurred")
    }

    func testGlareIntensityIsIndependentOfControlHeight() throws {
        // Equal point-space geometry at the top edge of a button and a tall panel.
        // The previous normalized-distance normal multiplied by 1414 produced
        // different brightness and clipped the short control to white.
        let scale = 3
        let width = 96 * scale
        var samples = [Pixel]()
        for pointHeight in [44, 120, 300] {
            let height = pointHeight * scale
            let source = try texture(width: width, height: height) { _, _ in Pixel(r: 100, g: 100, b: 100) }
            var u = neutralUniforms(width: width, height: height, scale: Float(scale))
            u.refractiveIndex = 1.2
            u.glareIntensity = 0.2
            u.glareDirectionOffset = 0
            u.glareOppositeSideBias = 0
            u.cornerRadius = 8
            u.rectangles.0 = SIMD4(4, 4, 88, Float(pointHeight - 8))
            let image = try render(source: source, uniforms: u)
            samples.append(image[48 * scale, 4 * scale + 1])
            assertPixel(image[48 * scale, height / 2], equals: Pixel(r: 100, g: 100, b: 100), tolerance: 2)
        }
        for pixel in samples {
            XCTAssertGreaterThan(pixel.r, 110, "The test must actually exercise a visible highlight")
            XCTAssertLessThan(pixel.r, 245, "The edge must not clip into an opaque white strip")
            assertPixel(pixel, equals: samples[0], tolerance: 1)
        }
    }

    func testCompactHighlightLipDoesNotLeaveAWhiteTailOnDarkBackdrop() throws {
        let scale = 3
        let u = compactEdgeUniforms(scale: scale)
        let background = Pixel(r: 64, g: 64, b: 64)
        let source = try texture(width: Int(u.resolution.x), height: Int(u.resolution.y)) { _, _ in background }
        let image = try render(source: source, uniforms: u)

        // Pixel centers are sampled at (row + 0.5) / scale. With a 4 pt
        // inset, this pixel is exactly 0.5 pt inside the directly lit top edge.
        let lip = image[48 * scale, 4 * scale + 1]
        XCTAssertGreaterThan(Int(lip.r), Int(background.r) + 15,
                             "The compact lip must remain visibly reflective, not simply turn glare off")
        XCTAssertLessThan(Int(lip.r), 245, "A dark backdrop must not become an opaque white border")
        XCTAssertEqual(Int(lip.a), 255)

        // Start at 2.167 pt and inspect every row through the flat interior.
        // This catches the former multi-point exponential white tail rather
        // than only checking one distant center pixel.
        for rowOffset in (2 * scale)..<(36 * scale) {
            assertPixel(image[48 * scale, 4 * scale + rowOffset], equals: background, tolerance: 3)
        }
    }

    func testWhiteBackdropHasAGentleInnerLineWithoutDimmingTheBody() throws {
        let scale = 3
        let u = compactEdgeUniforms(scale: scale)
        let white = Pixel(r: 255, g: 255, b: 255)
        let source = try texture(width: Int(u.resolution.x), height: Int(u.resolution.y)) { _, _ in white }
        let image = try render(source: source, uniforms: u)

        // The opposite, unlit bottom edge isolates inner occlusion from the
        // bright key. This averages centers at 0.833 and 1.167 pt depth.
        let line = edgeBandMean(image, scale: scale, from: 2.0 / 3.0, to: 4.0 / 3.0, fromBottom: true)
        XCTAssertGreaterThan(line, 230, "The inner line should be restrained, not a dark bevel")
        XCTAssertLessThan(line, 254, "A white backdrop needs a measurable inner line to convey thickness")
        for rowOffset in [6, 7, 10, 19] {
            let y = (80 - 4) * scale - 1 - rowOffset
            assertPixel(image[48 * scale, y], equals: white, tolerance: 3)
        }
        assertPixel(image[48 * scale, 40 * scale], equals: white)
    }

    func testCompactEdgeProfilesRemainPointSizedAtTwoAndThreeTimesScale() throws {
        var images: [(scale: Int, dark: Image, light: Image)] = []
        for scale in [2, 3] {
            let u = compactEdgeUniforms(scale: scale)
            let width = Int(u.resolution.x), height = Int(u.resolution.y)
            let dark = try texture(width: width, height: height) { _, _ in Pixel(r: 64, g: 64, b: 64) }
            let light = try texture(width: width, height: height) { _, _ in Pixel(r: 255, g: 255, b: 255) }
            images.append((scale, try render(source: dark, uniforms: u), try render(source: light, uniforms: u)))
        }

        // Integrate the same point-space bands rather than comparing unequal
        // pixel-center positions. Narrow bands allow sampling/quantization
        // differences; the recovered interior has a much tighter tolerance.
        let bands: [(start: Double, end: Double, tolerance: Double)] = [
            (0, 0.75, 18), (0.75, 1.5, 8), (2, 3, 3), (3, 5, 3)
        ]
        for band in bands {
            let dark2 = edgeBandMean(images[0].dark, scale: 2, from: band.start, to: band.end)
            let dark3 = edgeBandMean(images[1].dark, scale: 3, from: band.start, to: band.end)
            let light2 = edgeBandMean(images[0].light, scale: 2, from: band.start, to: band.end, fromBottom: true)
            let light3 = edgeBandMean(images[1].light, scale: 3, from: band.start, to: band.end, fromBottom: true)
            XCTAssertEqual(dark2, dark3, accuracy: band.tolerance,
                           "Dark edge profile must keep its point-space width in band \(band.start)...\(band.end)")
            XCTAssertEqual(light2, light3, accuracy: band.tolerance,
                           "Inner line must keep its point-space width in band \(band.start)...\(band.end)")
            if band.start == 0 {
                XCTAssertGreaterThan(dark2, 79)
                XCTAssertGreaterThan(dark3, 79)
            } else if band.start >= 2 {
                XCTAssertEqual(dark2, 64, accuracy: 3)
                XCTAssertEqual(dark3, 64, accuracy: 3)
                XCTAssertEqual(light2, 255, accuracy: 3)
                XCTAssertEqual(light3, 255, accuracy: 3)
            }
        }
    }

    func testRefractionConvergesContinuouslyToZeroForThinLayers() throws {
        let scale = 3
        let source = try texture(width: 96 * scale, height: 80 * scale) { x, _ in
            let gray = UInt8(min(x * 8, 255))
            return Pixel(r: gray, g: gray, b: gray)
        }
        var u = compactEdgeUniforms(scale: scale)
        u.glareIntensity = 0
        u.fresnelIntensity = 0
        u.refractiveIndex = 1.7
        let x = 4 * scale + 1, y = 40 * scale
        u.glassThickness = 0
        let neutral = try render(source: source, uniforms: u)[x, y]
        assertPixel(neutral, equals: Pixel(r: UInt8(x * 8), g: UInt8(x * 8), b: UInt8(x * 8)))
        for thickness in [Float(0.0001), 0.01, 0.1] {
            u.glassThickness = thickness
            let thin = try render(source: source, uniforms: u)[x, y]
            assertPixel(thin, equals: neutral, tolerance: 1)
        }
        u.glassThickness = 2
        let visible = try render(source: source, uniforms: u)[x, y]
        XCTAssertGreaterThan(Int(visible.r) - Int(neutral.r), 5,
                             "The gradient must exercise actual refraction, not a disabled shader")
    }

    func testZeroMergeMultipleRectanglesRetainTransparentGapAndStableEdges() throws {
        let source = try texture(width: 96, height: 64) { _, _ in Pixel(r: 255, g: 255, b: 255) }
        // Moving fractional-pixel edges exercise both interior and exterior AA.
        for x: Float in [8.75, 9.25, 10.75, 8.75] {
            var u = neutralUniforms(width: 96, height: 64)
            u.refractiveIndex = 1.25
            u.cornerRadius = 8
            u.shapeMergeSmoothness = 0
            u.rectangleCount = 3
            u.rectangles.0 = .zero // An invalid first entry must not poison the union.
            u.rectangles.1 = SIMD4(x, 8.75, 28, 42)
            u.rectangles.2 = SIMD4(57.25, 8.75, 28, 42)
            let image = try render(source: source, uniforms: u)
            assertPixel(image[22, 28], equals: Pixel(r: 255, g: 255, b: 255))
            assertPixel(image[70, 28], equals: Pixel(r: 255, g: 255, b: 255))
            assertPixel(image[47, 28], equals: Pixel(r: 0, g: 0, b: 0, a: 0))
            assertPixel(image[0, 0], equals: Pixel(r: 0, g: 0, b: 0, a: 0))
            var partialCount = 0
            var opaqueCount = 0
            for pixel in image.pixels {
                if pixel.a > 0 && pixel.a < 255 { partialCount += 1 }
                if pixel.a == 255 { opaqueCount += 1 }
                // White source with no tint/light remains white. Premultiplied
                // coverage requires every RGB channel == alpha, even outside
                // the contour; a NaN/black edge violates this invariant.
                XCTAssertEqual(Int(pixel.r), Int(pixel.a), accuracy: 2)
                XCTAssertEqual(Int(pixel.g), Int(pixel.a), accuracy: 2)
                XCTAssertEqual(Int(pixel.b), Int(pixel.a), accuracy: 2)
            }
            XCTAssertGreaterThan(partialCount, 50)
            XCTAssertGreaterThan(opaqueCount, 1800, "Both surfaces must be fully rendered, not just outlined")
        }
    }

    func testMPSBlurIsOutOfPlaceAndReducesCheckerboardContrast() throws {
        let source = try texture(width: 64, height: 64) { x, y in
            let v: UInt8 = ((x / 4 + y / 4) % 2 == 0) ? 0 : 255
            return Pixel(r: v, g: v, b: v)
        }
        let before = try read(source)
        let blur = LiquidGlassBlurPass()
        let command = try XCTUnwrap(queue.makeCommandBuffer())
        let output = try XCTUnwrap(blur.encode(source: source, radius: 2, pixelsPerPoint: 1, commandBuffer: command))
        XCTAssertFalse(output === source, "Blur must not mutate the shared sharp backdrop")
        try finish(command)
        let after = try read(source)
        let blurred = try read(output)
        XCTAssertEqual(after.bytes, before.bytes)
        let interior = (8..<56).flatMap { y in (8..<56).map { x in Double(blurred[x, y].r) } }
        let mean = interior.reduce(0, +) / Double(interior.count)
        let contrast = (try XCTUnwrap(interior.max())) - (try XCTUnwrap(interior.min()))
        XCTAssertEqual(mean, 127.5, accuracy: 6)
        XCTAssertLessThan(contrast, 100, "The actual MPS output must attenuate the 255-level checkerboard contrast")
        XCTAssertTrue(blurred.pixels.allSatisfy { $0.a >= 254 })
    }

    func testBlurInvalidationRefreshesReusedSourceTexture() throws {
        let source = try texture(width: 32, height: 32) { _, _ in Pixel(r: 240, g: 20, b: 10) }
        let blur = LiquidGlassBlurPass()
        var command = try XCTUnwrap(queue.makeCommandBuffer())
        var output = try XCTUnwrap(blur.encode(source: source, radius: 2, pixelsPerPoint: 1, commandBuffer: command))
        try finish(command)
        assertPixel(try read(output)[16, 16], equals: Pixel(r: 240, g: 20, b: 10), tolerance: 2)
        replace(source) { _, _ in Pixel(r: 10, g: 30, b: 230) }
        blur.invalidate()
        command = try XCTUnwrap(queue.makeCommandBuffer())
        output = try XCTUnwrap(blur.encode(source: source, radius: 2, pixelsPerPoint: 1, commandBuffer: command))
        try finish(command)
        assertPixel(try read(output)[16, 16], equals: Pixel(r: 10, g: 30, b: 230), tolerance: 2)
        assertPixel(try read(source)[16, 16], equals: Pixel(r: 10, g: 30, b: 230))
    }

    func testZeroBlurReturnsUnmodifiedSource() throws {
        let source = try texture(width: 16, height: 16) { _, _ in Pixel(r: 60, g: 120, b: 180) }
        let command = try XCTUnwrap(queue.makeCommandBuffer())
        let result = try XCTUnwrap(LiquidGlassBlurPass().encode(source: source, radius: 0, pixelsPerPoint: 3, commandBuffer: command))
        XCTAssertTrue(result === source)
    }

    // MARK: - Real GPU setup and readback

    private func compactEdgeUniforms(scale: Int) -> LiquidGlassUniforms {
        var u = neutralUniforms(width: 96 * scale, height: 80 * scale, scale: Float(scale))
        u.glassThickness = 12
        u.refractiveIndex = 1.45
        u.fresnelIntensity = 0.4
        u.glareIntensity = 0.28
        u.glareDirectionOffset = 0 // Top edge normal faces the key light.
        u.glareOppositeSideBias = 0
        u.cornerRadius = 8
        u.rectangles.0 = SIMD4(4, 4, 88, 72)
        return u
    }

    /// Read the production GPU image using a point-space interval. Each row is
    /// weighted by the overlap of its pixel footprint with the requested band;
    /// three horizontal pixels reduce incidental readback quantization noise.
    private func edgeBandMean(_ image: Image, scale: Int, from start: Double,
                              to end: Double, fromBottom: Bool = false) -> Double {
        var sum = 0.0
        var weight = 0.0
        let density = Double(scale)
        for row in Int(floor(start * density))..<Int(ceil(end * density)) {
            let overlap = max(0, min(end, Double(row + 1) / density) - max(start, Double(row) / density))
            let y = fromBottom ? image.height - 4 * scale - 1 - row : 4 * scale + row
            for x in (image.width / 2 - 1)...(image.width / 2 + 1) {
                let pixel = image[x, y]
                sum += (Double(pixel.r) + Double(pixel.g) + Double(pixel.b)) / 3 * overlap
                weight += overlap
            }
        }
        return sum / weight
    }

    private func neutralUniforms(width: Int, height: Int, scale: Float = 1) -> LiquidGlassUniforms {
        var u = LiquidGlassUniforms(glassThickness: 8, refractiveIndex: 1, dispersionStrength: 0,
                                   fresnelIntensity: 0, glareIntensity: 0)
        u.resolution = SIMD2(Float(width), Float(height))
        u.contentsScale = scale
        u.touchPoint = SIMD2(repeating: -1)
        u.cornerRadius = 0
        u.materialTint = .zero
        u.rectangleCount = 1
        u.rectangles.0 = SIMD4(0, 0, Float(width) / scale, Float(height) / scale)
        return u
    }

    private func texture(width: Int, height: Int, pixel: (Int, Int) -> Pixel) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        descriptor.storageMode = .shared
        let result = try XCTUnwrap(renderer.device.makeTexture(descriptor: descriptor))
        replace(result, pixel: pixel)
        return result
    }

    private func replace(_ texture: MTLTexture, pixel: (Int, Int) -> Pixel) {
        var bytes = [UInt8]()
        bytes.reserveCapacity(texture.width * texture.height * 4)
        for y in 0..<texture.height {
            for x in 0..<texture.width {
                let p = pixel(x, y)
                bytes.append(contentsOf: [p.b, p.g, p.r, p.a])
            }
        }
        bytes.withUnsafeBytes { raw in
            texture.replace(region: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0,
                            withBytes: raw.baseAddress!, bytesPerRow: texture.width * 4)
        }
    }

    private func render(source: MTLTexture, soft: MTLTexture? = nil, uniforms: LiquidGlassUniforms) throws -> Image {
        let width = Int(uniforms.resolution.x), height = Int(uniforms.resolution.y)
        let target = try texture(width: width, height: height) { _, _ in Pixel(r: 255, g: 0, b: 255) }
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = target
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        let command = try XCTUnwrap(queue.makeCommandBuffer())
        let encoder = try XCTUnwrap(command.makeRenderCommandEncoder(descriptor: descriptor))
        encoder.setRenderPipelineState(renderer.pipelineState)
        var uniforms = uniforms
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<LiquidGlassUniforms>.stride, index: 0)
        encoder.setFragmentTexture(source, index: 0)
        encoder.setFragmentTexture(soft ?? source, index: 1)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        try finish(command)
        return try read(target)
    }

    private func finish(_ command: MTLCommandBuffer) throws {
        command.commit()
        command.waitUntilCompleted()
        XCTAssertEqual(command.status, .completed, command.error?.localizedDescription ?? "Metal command did not complete")
        if let error = command.error { throw error }
    }

    private func read(_ texture: MTLTexture) throws -> Image {
        // MPS textures are private. A real GPU blit makes them CPU-readable;
        // aligned row strides also work on Apple GPU simulator hosts.
        let bytesPerRow = (texture.width * 4 + 255) & ~255
        let length = bytesPerRow * texture.height
        let buffer = try XCTUnwrap(renderer.device.makeBuffer(length: length, options: .storageModeShared))
        let command = try XCTUnwrap(queue.makeCommandBuffer())
        let blit = try XCTUnwrap(command.makeBlitCommandEncoder())
        blit.copy(from: texture, sourceSlice: 0, sourceLevel: 0,
                  sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                  sourceSize: MTLSize(width: texture.width, height: texture.height, depth: 1),
                  to: buffer, destinationOffset: 0, destinationBytesPerRow: bytesPerRow, destinationBytesPerImage: length)
        blit.endEncoding()
        try finish(command)
        let pointer = buffer.contents().assumingMemoryBound(to: UInt8.self)
        var bytes = [UInt8]()
        bytes.reserveCapacity(texture.width * texture.height * 4)
        for y in 0..<texture.height {
            bytes.append(contentsOf: UnsafeBufferPointer(start: pointer.advanced(by: y * bytesPerRow), count: texture.width * 4))
        }
        return Image(width: texture.width, height: texture.height, bytes: bytes)
    }

    private func assertPixel(_ actual: Pixel, equals expected: Pixel, tolerance: Int = 1, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(Int(actual.r), Int(expected.r), accuracy: tolerance, "red", file: file, line: line)
        XCTAssertEqual(Int(actual.g), Int(expected.g), accuracy: tolerance, "green", file: file, line: line)
        XCTAssertEqual(Int(actual.b), Int(expected.b), accuracy: tolerance, "blue", file: file, line: line)
        XCTAssertEqual(Int(actual.a), Int(expected.a), accuracy: tolerance, "alpha", file: file, line: line)
    }

    private struct Pixel {
        var r: UInt8
        var g: UInt8
        var b: UInt8
        var a: UInt8 = 255
    }

    private struct Image {
        let width: Int
        let height: Int
        let bytes: [UInt8]
        subscript(_ x: Int, _ y: Int) -> Pixel {
            let i = (y * width + x) * 4
            return Pixel(r: bytes[i + 2], g: bytes[i + 1], b: bytes[i], a: bytes[i + 3])
        }
        var pixels: [Pixel] {
            stride(from: 0, to: bytes.count, by: 4).map { i in
                Pixel(r: bytes[i + 2], g: bytes[i + 1], b: bytes[i], a: bytes[i + 3])
            }
        }
    }
}
