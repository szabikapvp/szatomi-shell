#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    vec4 maskRect;  // x, y, w, h in item pixels
    vec4 radii; // top left, top right, bottom right, bottom left
};

layout(binding = 1) uniform sampler2D source;

// Rounded rect distance computed per pixel, so no mask texture has to be rendered
void main() {
    vec2 hs = maskRect.zw * 0.5;
    vec2 d = qt_TexCoord0 * itemSize - maskRect.xy - hs;
    float r = d.x < 0.0 ? (d.y < 0.0 ? radii.x : radii.w) : (d.y < 0.0 ? radii.y : radii.z);
    r = min(r, min(hs.x, hs.y));
    vec2 q = abs(d) - hs + r;
    float dist = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
    fragColor = texture(source, qt_TexCoord0) * clamp(0.5 - dist, 0.0, 1.0) * qt_Opacity;
}
