#include <metal_stdlib>
using namespace metal;

// All three functions follow SwiftUI's `.colorEffect` signature:
//   half4 fn(float2 position, half4 currentColor, ...userArgs)
// where `userArgs` are supplied via `.float(...)` / `.float2(...)` calls in
// the Swift `Shader` builder.

static inline float hash21(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

[[ stitchable ]] half4 plasma(float2 position,
                              half4   currentColor,
                              float   time,
                              float2  size)
{
    float2 uv = position / size;
    float v = sin(uv.x * 10.0 + time)
            + sin(uv.y * 10.0 + time * 1.3)
            + sin((uv.x + uv.y) * 7.0 + time * 0.7);
    float3 col = 0.5 + 0.5 * cos(v + float3(0.0, 2.0, 4.0));
    return half4(half3(col), 1.0h);
}

[[ stitchable ]] half4 ripple(float2 position,
                              half4   currentColor,
                              float   time,
                              float2  size)
{
    float2 center = size * 0.5;
    float  r = distance(position, center) / max(size.x, size.y);
    float  wave = 0.5 + 0.5 * sin(r * 30.0 - time * 3.0);
    float3 col = mix(float3(0.10, 0.20, 0.50),
                     float3(0.95, 0.55, 0.85),
                     wave);
    return half4(half3(col), 1.0h);
}

[[ stitchable ]] half4 valueNoise(float2 position,
                                  half4   currentColor,
                                  float   time,
                                  float2  size)
{
    float2 uv = position / size * 8.0;
    float2 i  = floor(uv);
    float2 f  = fract(uv);
    float2 u  = f * f * (3.0 - 2.0 * f);

    float drift = time * 0.1;
    float a = hash21(i + float2(0.0, 0.0) + drift);
    float b = hash21(i + float2(1.0, 0.0) + drift);
    float c = hash21(i + float2(0.0, 1.0) + drift);
    float d = hash21(i + float2(1.0, 1.0) + drift);

    float n = mix(mix(a, b, u.x),
                  mix(c, d, u.x),
                  u.y);

    float3 col = mix(float3(0.05, 0.15, 0.20),
                     float3(0.95, 0.95, 0.85),
                     n);
    return half4(half3(col), 1.0h);
}
