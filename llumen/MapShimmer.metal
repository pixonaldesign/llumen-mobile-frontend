#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

namespace mapshimmer {

float hash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + float2(1, 0));
    float c = hash(i + float2(0, 1));
    float d = hash(i + float2(1, 1));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p = float2x2(0.8, -0.6, 0.6, 0.8) * p * 2.03 + 17.0;
        amplitude *= 0.5;
    }
    return value;
}

}

/// Drifting topographic contours with a soft light sweep, over the map's base color.
/// `position` and `size` are in points so the pattern keeps its scale on every widget size.
[[ stitchable ]] half4 mapShimmer(float2 position, half4 color, float2 size, float time) {
    using namespace mapshimmer;

    float2 drift = float2(time * 0.035, -time * 0.022);
    float2 p = position / 150.0 + drift;
    float height = fbm(p);

    // Distance to the nearest contour in points, so every line has the same width.
    float bands = height * 10.0;
    float e = 1.0 / 150.0;
    float2 gradient = float2(fbm(p + float2(e, 0)) - height, fbm(p + float2(0, e)) - height) * 10.0;
    float distanceToLine = abs(fract(bands + 0.5) - 0.5) / max(length(gradient), 1e-4);
    float contour = 1.0 - smoothstep(0.35, 1.1, distanceToLine);

    float diagonal = (position.x + position.y * 0.45) / max(size.x + size.y * 0.45, 1.0);
    float center = fract(time / 2.4) * 1.9 - 0.45;
    float sweep = exp(-pow((diagonal - center) / 0.16, 2.0));

    float3 tint = float3(0.78, 0.88, 1.0);
    float3 rgb = float3(color.rgb);
    rgb += tint * contour * (0.022 + 0.11 * sweep);
    rgb += tint * sweep * 0.03;
    rgb += (height - 0.5) * 0.035;
    rgb += (hash(position) - 0.5) / 255.0;

    return half4(half3(rgb), color.a);
}
