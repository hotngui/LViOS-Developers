#include <metal_stdlib>
using namespace metal;

// All three compute kernels accept an input texture, an output texture, and
// optional uniforms. Threadgroup size is set Swift-side (16 x 16).

kernel void grayscale_kernel(texture2d<half, access::read>  inTex  [[texture(0)]],
                             texture2d<half, access::write> outTex [[texture(1)]],
                             uint2 gid                              [[thread_position_in_grid]])
{
    if (gid.x >= outTex.get_width() || gid.y >= outTex.get_height()) { return; }

    half4 c    = inTex.read(gid);
    half  luma = dot(c.rgb, half3(0.299h, 0.587h, 0.114h));
    outTex.write(half4(luma, luma, luma, c.a), gid);
}

kernel void box_blur_kernel(texture2d<half, access::read>  inTex  [[texture(0)]],
                            texture2d<half, access::write> outTex [[texture(1)]],
                            constant int                  &radius [[buffer(0)]],
                            uint2 gid                              [[thread_position_in_grid]])
{
    int w = (int)inTex.get_width();
    int h = (int)inTex.get_height();
    if ((int)gid.x >= w || (int)gid.y >= h) { return; }

    half4 sum   = half4(0);
    int   count = 0;
    for (int dy = -radius; dy <= radius; ++dy) {
        for (int dx = -radius; dx <= radius; ++dx) {
            int x = clamp((int)gid.x + dx, 0, w - 1);
            int y = clamp((int)gid.y + dy, 0, h - 1);
            sum += inTex.read(uint2(x, y));
            count += 1;
        }
    }
    outTex.write(sum / half(count), gid);
}

kernel void sobel_kernel(texture2d<half, access::read>  inTex  [[texture(0)]],
                         texture2d<half, access::write> outTex [[texture(1)]],
                         uint2 gid                              [[thread_position_in_grid]])
{
    int w = (int)inTex.get_width();
    int h = (int)inTex.get_height();
    if ((int)gid.x >= w || (int)gid.y >= h) { return; }

    half g[9];
    int idx = 0;
    for (int dy = -1; dy <= 1; ++dy) {
        for (int dx = -1; dx <= 1; ++dx) {
            int x = clamp((int)gid.x + dx, 0, w - 1);
            int y = clamp((int)gid.y + dy, 0, h - 1);
            half4 c = inTex.read(uint2(x, y));
            g[idx++] = dot(c.rgb, half3(0.299h, 0.587h, 0.114h));
        }
    }

    half gx = -g[0] - 2.0h * g[3] - g[6] + g[2] + 2.0h * g[5] + g[8];
    half gy = -g[0] - 2.0h * g[1] - g[2] + g[6] + 2.0h * g[7] + g[8];
    half mag = clamp(sqrt(gx * gx + gy * gy), 0.0h, 1.0h);

    outTex.write(half4(mag, mag, mag, 1.0h), gid);
}
