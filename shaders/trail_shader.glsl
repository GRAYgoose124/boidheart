#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
uniform vec2 resolution;
uniform float decay;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = Texel(tex, texture_coords);
    
    // Add some variation based on screen position
    float distFromCenter = length((texture_coords - 0.5) * resolution) / length(resolution * 0.5);
    float fadeAtEdges = 1.0 - smoothstep(0.8, 1.0, distFromCenter);
    
    // Decay more at the edges of the screen
    float adjustedDecay = decay * (1.0 + distFromCenter * 0.5);
    
    // Apply decay and edge fading
    vec3 finalColor = pixel.rgb * (1.0 - adjustedDecay) * fadeAtEdges;
    
    return vec4(finalColor, 1.0);
}
#endif 