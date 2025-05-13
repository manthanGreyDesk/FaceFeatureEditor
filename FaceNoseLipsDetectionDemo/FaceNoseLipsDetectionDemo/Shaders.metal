#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]]) {
    float2 positions[6] = {
        {-1.0, -1.0}, {1.0, -1.0}, {-1.0, 1.0},
        {1.0, -1.0}, {1.0, 1.0}, {-1.0, 1.0}
    };

    float2 texCoords[6] = {
        {0.0, 1.0}, {1.0, 1.0}, {0.0, 0.0},
        {1.0, 1.0}, {1.0, 0.0}, {0.0, 0.0}
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0, 1);
    out.texCoord = texCoords[vertexID];
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               texture2d<float> tex [[texture(0)]]) {
    constexpr sampler s(address::clamp_to_edge);
    return tex.sample(s, in.texCoord);
}
