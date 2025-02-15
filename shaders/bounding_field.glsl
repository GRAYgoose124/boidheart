#pragma language glsl3

// Should be set to the maximum number of boids expected in the scene.
// For now this is usually equal to the number of boids in the scene.
// This source is modified dynamically.
#define MAX_BOIDS 100

uniform vec2 boids[MAX_BOIDS];
uniform vec2 velocities[MAX_BOIDS];
uniform int boidCount;
uniform vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / resolution;
    float field = 0.0;
    vec3 fieldColor = vec3(0.0);
    

    float fieldInfluence = float(boidCount);
    for(int i = 0; i < boidCount; i++) {
        if (i >= boidCount) break;
        
        vec2 boidPos = boids[i] / resolution;
        float distance = length(uv - boidPos);
        
        if (distance > 0.001 && distance < 0.5) {
            float influence = smoothstep(0.45, 0.0, distance);
            field += 0.001 * influence / distance;
            
            vec2 vel = normalize(velocities[i]);
            vec3 boidColor = vec3(
                abs(vel.x),
                abs(vel.y),
                (abs(vel.x * vel.y))
            );
            
            fieldColor += boidColor * influence;
        }
    }
    
    float intensity = min(field, 1.0);
    fieldColor = normalize(fieldColor + 0.001) * intensity;
    return vec4(fieldColor, 1.0) * color.a;
}