//
//  LiquidGlassShader.metal
//  LiquidGlassEffect
//
//  Based on LiquidGlassKit by Alexey Demin (DnV1eX)
//  https://github.com/DnV1eX/LiquidGlassKit
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

#define PI M_PI_F

// Refractive indices for chromatic dispersion
constant float refractiveIndexRed = 1.0f - 0.02f;
constant float refractiveIndexGreen = 1.0f;
constant float refractiveIndexBlue = 1.0f + 0.02f;

// Vertex output
struct VertexOutput {
    float4 position [[position]];
    half2 uv;
};

// Maximum number of rectangles
constant int maxRectangles = 16;

// Uniforms
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
    int rectangleCount;
    float4 rectangles[maxRectangles];
};

// Sampler
constant sampler textureSampler(
    filter::linear,
    mag_filter::linear,
    min_filter::linear,
    address::clamp_to_edge
);

// =============================================================================
// SDF Functions
// =============================================================================

float superellipseCornerSDF(float2 point, float radius, float exponent) {
    point = abs(point);
    float value = pow(pow(point.x, exponent) + pow(point.y, exponent), 1.0f / exponent);
    return value - radius;
}

float roundedRectangleSDF(float2 fragmentCoord, float4 rect, float cornerRadius, float roundnessExponent, constant ShaderUniforms& uniforms) {
    float2 rectOriginPx = rect.xy * uniforms.contentsScale;
    float2 rectSizePx = rect.zw * uniforms.contentsScale;
    float scaledCornerRadius = cornerRadius * uniforms.contentsScale;
    
    float2 rectCenterPx = rectOriginPx + rectSizePx * 0.5f;
    float2 point = fragmentCoord - rectCenterPx;
    float2 halfExtents = rectSizePx * 0.5f;
    float2 edgeDistance = abs(point) - halfExtents;
    
    float surfaceDistance;
    
    if (edgeDistance.x > -scaledCornerRadius && edgeDistance.y > -scaledCornerRadius) {
        float2 cornerCenter = sign(point) * (halfExtents - float2(scaledCornerRadius));
        float2 cornerRelativePoint = point - cornerCenter;
        surfaceDistance = superellipseCornerSDF(cornerRelativePoint, scaledCornerRadius, roundnessExponent);
    } else {
        surfaceDistance = min(max(edgeDistance.x, edgeDistance.y), 0.0f) + length(max(edgeDistance, 0.0f));
    }
    
    return surfaceDistance;
}

float smoothUnion(float distanceA, float distanceB, float smoothness) {
    float hermite = clamp(0.5f + 0.5f * (distanceB - distanceA) / smoothness, 0.0f, 1.0f);
    return mix(distanceB, distanceA, hermite) - smoothness * hermite * (1.0f - hermite);
}

float primaryShapeSDF(float2 fragmentCoord, constant ShaderUniforms& uniforms) {
    float combinedDistance = 1e10f;
    
    for (int i = 0; i < uniforms.rectangleCount && i < maxRectangles; ++i) {
        float4 rect = uniforms.rectangles[i];
        
        if (rect.z <= 0.0f || rect.w <= 0.0f) continue;
        
        float rectDistance = roundedRectangleSDF(
            fragmentCoord,
            rect,
            uniforms.cornerRadius,
            uniforms.cornerRoundnessExponent,
            uniforms
        );
        
        float normalizedRectDist = rectDistance / uniforms.resolution.y;
        
        if (i == 0) {
            combinedDistance = normalizedRectDist;
        } else {
            combinedDistance = smoothUnion(combinedDistance, normalizedRectDist, uniforms.shapeMergeSmoothness);
        }
    }
    
    return combinedDistance;
}

float2 computeSurfaceNormal(float2 fragmentCoord, constant ShaderUniforms& uniforms) {
    float2 epsilon = float2(
        max(abs(dfdx(fragmentCoord.x)), 0.0001f),
        max(abs(dfdy(fragmentCoord.y)), 0.0001f)
    );
    
    float2 gradient = float2(
        primaryShapeSDF(fragmentCoord + float2(epsilon.x, 0.0f), uniforms) -
        primaryShapeSDF(fragmentCoord - float2(epsilon.x, 0.0f), uniforms),
        primaryShapeSDF(fragmentCoord + float2(0.0f, epsilon.y), uniforms) -
        primaryShapeSDF(fragmentCoord - float2(0.0f, epsilon.y), uniforms)
    ) / (2.0f * epsilon);
    
    return gradient * 1.414213562f * 1000.0f;
}

// =============================================================================
// Color Space Utilities
// =============================================================================

constant float3 d65WhitePoint = float3(0.95045592705f, 1.0f, 1.08905775076f);
constant float3 whiteReference = d65WhitePoint;

constant float3x3 rgbToXyzMatrix = float3x3(
    float3(0.4124f, 0.3576f, 0.1805f),
    float3(0.2126f, 0.7152f, 0.0722f),
    float3(0.0193f, 0.1192f, 0.9505f)
);

constant float3x3 xyzToRgbMatrix = float3x3(
    float3( 3.2406255f, -1.537208f , -0.4986286f),
    float3(-0.9689307f,  1.8757561f,  0.0415175f),
    float3( 0.0557101f, -0.2040211f,  1.0569959f)
);

float linearizeSRGB(float channel) {
    return channel > 0.04045f ? pow((channel + 0.055f) / 1.055f, 2.4f) : channel / 12.92f;
}

float gammaCorrectSRGB(float linear) {
    return linear <= 0.0031308f ? 12.92f * linear : 1.055f * pow(linear, 0.41666666666f) - 0.055f;
}

half3 srgbToLinear(half3 srgb) {
    return half3(linearizeSRGB(srgb.x), linearizeSRGB(srgb.y), linearizeSRGB(srgb.z));
}

half3 linearToSrgb(half3 linear) {
    return half3(gammaCorrectSRGB(linear.x), gammaCorrectSRGB(linear.y), gammaCorrectSRGB(linear.z));
}

float3 linearRgbToXyz(float3 linearRgb) {
    return linearRgb * rgbToXyzMatrix;
}

float3 srgbToXyz(half3 srgb) {
    return linearRgbToXyz(float3(srgbToLinear(srgb)));
}

float xyzToLabNonlinear(float normalizedX) {
    return normalizedX > 0.00885645167f ? pow(normalizedX, 1.0f / 3.0f) : 7.78703703704f * normalizedX + 0.13793103448f;
}

float3 xyzToLab(float3 xyz) {
    float3 scaledXyz = xyz / whiteReference;
    scaledXyz = float3(
        xyzToLabNonlinear(scaledXyz.x),
        xyzToLabNonlinear(scaledXyz.y),
        xyzToLabNonlinear(scaledXyz.z)
    );
    return float3(
        116.0f * scaledXyz.y - 16.0f,
        500.0f * (scaledXyz.x - scaledXyz.y),
        200.0f * (scaledXyz.y - scaledXyz.z)
    );
}

float3 srgbToLab(half3 srgb) {
    return xyzToLab(srgbToXyz(srgb));
}

float3 labToLch(float3 lab) {
    float chroma = sqrt(dot(lab.yz, lab.yz));
    float hueDegrees = atan2(lab.z, lab.y) * (180.0f / PI);
    return float3(lab.x, chroma, hueDegrees);
}

float3 srgbToLch(half3 srgb) {
    return labToLch(srgbToLab(srgb));
}

float3 xyzToLinearRgb(float3 xyz) {
    return xyz * xyzToRgbMatrix;
}

half3 xyzToSrgb(float3 xyz) {
    return linearToSrgb(half3(xyzToLinearRgb(xyz)));
}

float labToXyzNonlinear(float transformed) {
    return transformed > 0.206897f ? transformed * transformed * transformed : 0.12841854934f * (transformed - 0.137931034f);
}

float3 labToXyz(float3 lab) {
    float whiteScaled = (lab.x + 16.0f) / 116.0f;
    return whiteReference * float3(
        labToXyzNonlinear(whiteScaled + lab.y / 500.0f),
        labToXyzNonlinear(whiteScaled),
        labToXyzNonlinear(whiteScaled - lab.z / 200.0f)
    );
}

half3 labToSrgb(float3 lab) {
    return xyzToSrgb(labToXyz(lab));
}

float3 lchToLab(float3 lch) {
    float hueRadians = lch.z * (PI / 180.0f);
    return float3(lch.x, lch.y * cos(hueRadians), lch.y * sin(hueRadians));
}

half3 lchToSrgb(float3 lch) {
    return labToSrgb(lchToLab(lch));
}

float vectorToAngle(float2 vector) {
    float angle = atan2(vector.y, vector.x);
    return (angle < 0.0f) ? angle + 2.0f * PI : angle;
}

half4 sampleWithDispersion(texture2d<half> texture, float2 baseUv, float2 offset, float dispersionFactor) {
    half4 color = half4(1.0h);
    color.r = texture.sample(textureSampler, baseUv + offset * (1.0f - (refractiveIndexRed - 1.0f) * dispersionFactor)).r;
    color.g = texture.sample(textureSampler, baseUv + offset * (1.0f - (refractiveIndexGreen - 1.0f) * dispersionFactor)).g;
    color.b = texture.sample(textureSampler, baseUv + offset * (1.0f - (refractiveIndexBlue - 1.0f) * dispersionFactor)).b;
    return color;
}

// =============================================================================
// Vertex Shader
// =============================================================================

vertex VertexOutput fullscreenQuad(uint vertexID [[vertex_id]]) {
    VertexOutput output;
    
    float2 positions[4] = {
        float2(-1.0f, -1.0f),
        float2( 1.0f, -1.0f),
        float2(-1.0f,  1.0f),
        float2( 1.0f,  1.0f)
    };
    
    float2 uvs[4] = {
        float2(0.0f, 0.0f),
        float2(1.0f, 0.0f),
        float2(0.0f, 1.0f),
        float2(1.0f, 1.0f)
    };
    
    output.position = float4(positions[vertexID], 0.0f, 1.0f);
    output.uv = half2(uvs[vertexID]);
    return output;
}

// =============================================================================
// Fragment Shader
// =============================================================================

fragment half4 liquidGlassEffect(VertexOutput input [[stage_in]],
                                 constant ShaderUniforms& uniforms [[buffer(0)]],
                                 texture2d<half> background [[texture(0)]]) {
    
    float2 logicalResolution = uniforms.resolution / uniforms.contentsScale;
    float2 fragmentPixelCoord = float2(input.uv) * uniforms.resolution;
    float shapeDistance = primaryShapeSDF(fragmentPixelCoord, uniforms);
    
    half4 outputColor;
    
    if (shapeDistance < 0.005f) {
        float normalizedDepth = -shapeDistance * logicalResolution.y;
        
        float depthRatio = 1.0f - normalizedDepth / uniforms.glassThickness;
        float incidentAngle = asin(pow(depthRatio, 2.0f));
        float transmittedAngle = asin(1.0f / uniforms.refractiveIndex * sin(incidentAngle));
        float edgeShiftFactor = -tan(transmittedAngle - incidentAngle);
        if (normalizedDepth >= uniforms.glassThickness) {
            edgeShiftFactor = 0.0f;
        }
        
        if (edgeShiftFactor <= 0.0f) {
            outputColor = background.sample(textureSampler, float2(input.uv));
            outputColor = mix(outputColor, half4(half3(uniforms.materialTint.rgb), 1.0h), half(uniforms.materialTint.a * 0.8f));
        } else {
            float2 surfaceNormal = computeSurfaceNormal(fragmentPixelCoord, uniforms);
            
            half2 offsetUv = half2(-surfaceNormal * edgeShiftFactor * 0.05f * uniforms.contentsScale * float2(
                uniforms.resolution.y / (logicalResolution.x * uniforms.contentsScale),
                1.0f
            ));
            half4 refractedWithDispersion = sampleWithDispersion(background, float2(input.uv), float2(offsetUv), uniforms.dispersionStrength);
            
            outputColor = mix(refractedWithDispersion, half4(half3(uniforms.materialTint.rgb), 1.0h), half(uniforms.materialTint.a * 0.8f));
            
            // Fresnel
            float fresnelValue = clamp(
                pow(
                    1.0f + shapeDistance * logicalResolution.y / 1500.0f * pow(500.0f / uniforms.fresnelDistanceRange, 2.0f) + uniforms.fresnelEdgeSharpness,
                    5.0f
                ),
                0.0f, 1.0f
            );
            
            half3 fresnelBaseTint = mix(half3(1.0h), half3(uniforms.materialTint.rgb), half(uniforms.materialTint.a * 0.5f));
            float3 fresnelLch = srgbToLch(fresnelBaseTint);
            fresnelLch.x += 20.0f * fresnelValue * uniforms.fresnelIntensity;
            fresnelLch.x = clamp(fresnelLch.x, 0.0f, 100.0f);
            
            outputColor = mix(
                outputColor,
                half4(lchToSrgb(fresnelLch), 1.0h),
                half(fresnelValue * uniforms.fresnelIntensity * 0.7f * length(surfaceNormal))
            );
            
            // Glare
            float glareGeometryValue = clamp(
                pow(
                    1.0f + shapeDistance * logicalResolution.y / 1500.0f * pow(500.0f / uniforms.glareDistanceRange, 2.0f) + uniforms.glareEdgeSharpness,
                    5.0f
                ),
                0.0f, 1.0f
            );
            
            float glareAngle = (vectorToAngle(normalize(surfaceNormal)) - PI / 4.0f + uniforms.glareDirectionOffset) * 2.0f;
            int isFarSide = 0;
            if ((glareAngle > PI * (2.0f - 0.5f) && glareAngle < PI * (4.0f - 0.5f)) || glareAngle < PI * (0.0f - 0.5f)) {
                isFarSide = 1;
            }
            float angularGlare = (0.5f + sin(glareAngle) * 0.5f) *
                                 (isFarSide == 1 ? 1.2f * uniforms.glareOppositeSideBias : 1.2f) *
                                 uniforms.glareIntensity;
            angularGlare = clamp(pow(angularGlare, 0.1f + uniforms.glareAngleConvergence * 2.0f), 0.0f, 1.0f);
            
            half3 baseGlare = mix(refractedWithDispersion.rgb, half3(uniforms.materialTint.rgb), half(uniforms.materialTint.a * 0.5f));
            float3 glareLch = srgbToLch(baseGlare);
            glareLch.x += 150.0f * angularGlare * glareGeometryValue;
            glareLch.y += 30.0f * angularGlare * glareGeometryValue;
            glareLch.x = clamp(glareLch.x, 0.0f, 120.0f);
            
            outputColor = mix(
                outputColor,
                half4(lchToSrgb(glareLch), 1.0h),
                half(angularGlare * glareGeometryValue * length(surfaceNormal))
            );
        }
    } else {
        outputColor = half4(0);
    }
    
    outputColor = mix(outputColor, half4(0), smoothstep(-0.01f, 0.005f, shapeDistance));
    
    return outputColor;
}
