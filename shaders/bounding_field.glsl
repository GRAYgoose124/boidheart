#pragma language glsl3

#define MAX_BOIDS 100

uniform vec2 boids[MAX_BOIDS];
uniform int boidCount;
uniform vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / resolution;
    float field = 0.0;
    
    for(int i = 0; i < MAX_BOIDS; i++) {
        if (i >= boidCount) break;
        
        vec2 boidPos = boids[i];
        boidPos = boidPos / resolution;
        float distance = length(uv - boidPos);
        
        if (distance > 0.001 && distance < 0.5) {
            float influence = smoothstep(0.5, 0.0, distance);
            field += 0.01 * influence / (distance);
        }
    }
    
    vec4 fieldColor = vec4(0.2, 0.4, 1.0, 1.0);
    float intensity = min(field * 0.3, 1.0);
    return fieldColor * intensity * color.a;
}