#include <metal_stdlib>
using namespace metal;

// Must mirror Swift's TriangleUniforms.
struct Uniforms {
    float  angle;
    float4 color0;
    float4 color1;
    float4 color2;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut triangle_vertex(uint vid [[vertex_id]],
                                 constant Uniforms &uniforms [[buffer(0)]])
{
    // Hard-coded equilateral triangle in clip space.
    const float2 positions[3] = {
        float2( 0.0,  0.6),
        float2(-0.6, -0.6),
        float2( 0.6, -0.6)
    };
    const float4 colors[3] = {
        uniforms.color0,
        uniforms.color1,
        uniforms.color2
    };

    float c = cos(uniforms.angle);
    float s = sin(uniforms.angle);
    float2 p = positions[vid];
    float2 rotated = float2(p.x * c - p.y * s,
                            p.x * s + p.y * c);

    VertexOut out;
    out.position = float4(rotated, 0.0, 1.0);
    out.color    = colors[vid];
    return out;
}

fragment float4 triangle_fragment(VertexOut in [[stage_in]]) {
    return in.color;
}
