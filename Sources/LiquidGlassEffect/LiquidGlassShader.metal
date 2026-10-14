// LiquidGlassEffect — point-space lensing built on the project's credited
// LiquidGlassKit SDF foundation (https://github.com/DnV1eX/LiquidGlassKit).
#include <metal_stdlib>
using namespace metal;

constant int maxRectangles = 16;
struct VertexOutput { float4 position [[position]]; float2 uv; };
// Keep layout identical to LiquidGlassUniforms.swift (validated by GPU tests).
struct ShaderUniforms {
    float2 resolution;
    float contentsScale;
    float2 touchPoint;
    float shapeMergeSmoothness;
    float cornerRadius;
    float cornerRoundnessExponent;
    float4 materialTint;
    float glassThickness;
    float refractiveIndex;
    float dispersionStrength;
    float fresnelDistanceRange;
    float fresnelIntensity;
    float fresnelEdgeSharpness;
    float glareDistanceRange;
    float glareAngleConvergence;
    float glareOppositeSideBias;
    float glareIntensity;
    float glareEdgeSharpness;
    float glareDirectionOffset;
    float2 uvOffset;
    float2 uvScale;
    int rectangleCount;
    float4 rectangles[maxRectangles];
};
constant sampler textureSampler(coord::normalized, filter::linear, address::clamp_to_edge);

// All geometry and optical distances are in UIKit points, NOT normalized height.
float roundedRectangleSDF(float2 p, float4 rect, float radius, float exponent) {
    float2 halfSize = rect.zw * 0.5f;
    float r = clamp(radius, 0.0f, min(halfSize.x, halfSize.y));
    float2 q = abs(p - rect.xy - halfSize) - halfSize + r;
    float2 outside = max(q, 0.0f);
    float n = clamp(exponent, 2.0f, 6.0f);
    float corner = pow(pow(outside.x, n) + pow(outside.y, n), 1.0f / n);
    return corner + min(max(q.x, q.y), 0.0f) - r;
}
float shapeSDF(float2 p, constant ShaderUniforms& u) {
    float distance = 1e6f;
    // Preserve the public normalized merge control, but perform union in points.
    float k = max(u.shapeMergeSmoothness, 0.0f) * u.resolution.y / u.contentsScale;
    for (int i = 0; i < min(u.rectangleCount, maxRectangles); ++i) {
        float4 rect = u.rectangles[i];
        if (rect.z <= 0 || rect.w <= 0) continue;
        float d = roundedRectangleSDF(p, rect, u.cornerRadius, u.cornerRoundnessExponent);
        if (k > 0.0001f && distance < 1e5f) {
            float h = clamp(0.5f + 0.5f * (d - distance) / k, 0.0f, 1.0f);
            distance = mix(d, distance, h) - k * h * (1.0f - h);
        } else { distance = min(distance, d); }
    }
    return distance;
}
float2 surfaceNormal(float2 p, constant ShaderUniforms& u) {
    float e = 0.5f / u.contentsScale;
    float2 g = float2(shapeSDF(p + float2(e, 0), u) - shapeSDF(p - float2(e, 0), u),
                      shapeSDF(p + float2(0, e), u) - shapeSDF(p - float2(0, e), u));
    return g / max(length(g), 0.00001f);
}
float3 toLinear(float3 c) {
    return select(c / 12.92f, pow((c + 0.055f) / 1.055f, float3(2.4f)), c > 0.04045f);
}
float3 toSRGB(float3 c) {
    c = clamp(c, 0.0f, 1.0f);
    return select(c * 12.92f, 1.055f * pow(c, float3(1.0f / 2.4f)) - 0.055f, c > 0.0031308f);
}
float3 dispersed(texture2d<half> source, float2 uv, float2 shift, float dispersion) {
    // Dispersion is a small wavelength-dependent fraction, not a rainbow border.
    float d = clamp(dispersion * 0.0015f, 0.0f, 0.06f);
    return float3(source.sample(textureSampler, uv + shift * (1 + d)).r,
                  source.sample(textureSampler, uv + shift).g,
                  source.sample(textureSampler, uv + shift * (1 - d)).b);
}
vertex VertexOutput fullscreenQuad(uint id [[vertex_id]]) {
    const float2 positions[4] = { float2(-1,-1), float2(1,-1), float2(-1,1), float2(1,1) };
    // UIKit, CVPixelBuffer and texture rows all use a top-left origin.
    VertexOutput out;
    out.position = float4(positions[id], 0, 1);
    out.uv = positions[id] * float2(0.5f, -0.5f) + 0.5f;
    return out;
}
fragment half4 liquidGlassEffect(VertexOutput in [[stage_in]],
                                 constant ShaderUniforms& u [[buffer(0)]],
                                 texture2d<half> sharp [[texture(0)]],
                                 texture2d<half> soft [[texture(1)]]) {
    float2 size = u.resolution / max(u.contentsScale, 1.0f);
    float2 p = in.uv * size;
    float distance = shapeSDF(p, u);
    float aa = max(fwidth(distance), 1.0f / u.contentsScale);
    float coverage = 1.0f - smoothstep(-aa * 0.5f, aa * 0.5f, distance);
    if (coverage <= 0) return half4(0);

    float depth = max(-distance, 0.0f);
    float thickness = max(u.glassThickness, 0.0f);
    // The optical thickness must not also become a wide embossed border.
    // A compact shoulder bends the scene only within a few points of the edge.
    float bevel = max(min(clamp(thickness * 0.45f, 2.0f, 5.0f),
                          min(size.x, size.y) * 0.5f), 0.001f);
    float shoulder = 1.0f - smoothstep(0.0f, bevel, depth);
    // Continuous zero slope into the interior; bound the trigonometric domain.
    float sinI = shoulder * 0.88f;
    float n = max(u.refractiveIndex, 1.0f);
    float thetaI = asin(sinI);
    float thetaT = asin(sinI / n);
    float shiftPoints = min(tan(thetaI - thetaT) * bevel * 0.65f, bevel * 1.5f);
    // The compact shoulder has a minimum width, but an infinitesimal sheet
    // must still have infinitesimal optical displacement (no jump at zero).
    shiftPoints *= smoothstep(0.0f, 2.0f, thickness);
    float2 normal = surfaceNormal(p, u);
    float2 shift = -normal * shiftPoints / size * u.uvScale;
    float2 uv = in.uv * u.uvScale + u.uvOffset;
    float3 edgeColor = dispersed(sharp, uv, shift, u.dispersionStrength);
    float3 bodyColor = float3(soft.sample(textureSampler, uv + shift).rgb);
    // Scattering retains its independent optical-depth transition; narrowing the
    // surface shoulder must not blur away the sharp refracted edge sample.
    float scatterDepth = max(min(thickness, min(size.x, size.y) * 0.5f), 0.001f);
    float scattering = smoothstep(0.0f, scatterDepth * 1.2f, depth);
    float3 color = mix(toLinear(edgeColor), toLinear(bodyColor), scattering);
    color = mix(color, toLinear(clamp(u.materialTint.rgb, 0.0f, 1.0f)), clamp(u.materialTint.a, 0.0f, 1.0f));

    float cosI = sqrt(max(1.0f - sinI * sinI, 0.0f));
    float f0 = pow((n - 1.0f) / (n + 1.0f), 2.0f);
    float fresnel = f0 + (1.0f - f0) * pow(1.0f - cosI, 5.0f);
    // Reflections occupy the thin optical lip, not an exponential white haze.
    // Include the pixel footprint so sub-point highlights remain stable at 2x/3x.
    float fresnelWidth = clamp(u.fresnelDistanceRange * 0.006f, 0.25f, 0.65f)
                       * exp(-clamp(u.fresnelEdgeSharpness, -2.0f, 2.0f) * 0.35f);
    float fresnelSigma = sqrt(fresnelWidth * fresnelWidth + aa * aa * 0.25f);
    float fresnelBand = exp(-pow((depth - 0.15f) / fresnelSigma, 2.0f));
    float reflection = fresnel * fresnelBand * max(u.fresnelIntensity, 0.0f);

    // A directional key and quieter opposing highlight define thickness. Unit
    // normals keep their brightness identical on a button and on a large panel.
    float angle = u.glareDirectionOffset - M_PI_F * 0.5f;
    float2 light = float2(cos(angle), sin(angle));
    if (all(u.touchPoint >= 0.0f)) {
        float2 delta = (u.touchPoint - size * 0.5f) / max(size, float2(1));
        light = normalize(light + delta * 0.8f);
    }
    float power = 3.0f + max(u.glareAngleConvergence, 0.0f) * 4.0f;
    float key = pow(max(dot(normal, light), 0.0f), power);
    float opposite = pow(max(dot(normal, -light), 0.0f), power)
                   * clamp(u.glareOppositeSideBias, 0.0f, 1.0f) * 0.12f;
    float lipWidth = clamp(u.glareDistanceRange * 0.01f, 0.25f, 0.55f)
                   * exp(-clamp(u.glareEdgeSharpness, -2.0f, 2.0f) * 0.35f);
    float lipSigma = sqrt(lipWidth * lipWidth + aa * aa * 0.25f);
    float lip = exp(-pow((depth - 0.20f) / lipSigma, 2.0f));
    float highlight = (key + opposite) * lip * max(u.glareIntensity, 0.0f);

    // Separate the inner dark valley from the bright lip. It is local surface
    // shading, not a second UIView drawing an offset ring over the glass.
    float innerSigma = sqrt(0.42f * 0.42f + aa * aa * 0.25f);
    float innerBand = exp(-pow((depth - 1.0f) / innerSigma, 2.0f));
    float occlusion = innerBand * (0.4f + 0.6f * (1.0f - key))
                    * clamp(u.glareIntensity, 0.0f, 1.0f) * 0.28f;
    color *= 1.0f - occlusion;
    // One reflection budget: Fresnel and the key light no longer stack two white
    // blends. All optical controls at zero still produce exact scene passthrough.
    color = mix(color, float3(1), clamp(reflection + highlight, 0.0f, 0.45f));
    // CoreAnimation expects premultiplied alpha at the shape's AA boundary.
    return half4(half3(toSRGB(color) * coverage), half(coverage));
}
