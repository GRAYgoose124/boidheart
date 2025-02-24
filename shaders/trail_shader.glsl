#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
//uniform vec2 resolution;
uniform float decay;
//uniform float time;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = Texel(tex, texture_coords);
    
    // Apply decay to the existing pixel color to create trail effect
    vec3 trailColor = pixel.rgb * (1.0 - decay);
    
    return vec4(trailColor, 1.0);
}
#endif 