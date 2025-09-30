shader_type canvas_item;

uniform float animation_speed : hint_range(0.0, 2.0, 0.05) = 0.5;
uniform float block_size : hint_range(1.0, 16.0, 1.0) = 4.0;
uniform float glitch_strength : hint_range(0.0, 20.0) = 5.0;
// CORRECTED: Typo fixed ("aberration" has one 'b')
uniform float chromatic_aberration : hint_range(0.0, 5.0) = 1.0;

// A simple pseudo-random number function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    
    if (original_color.a > 0.1) {
        float block_line = floor(UV.y * TEXTURE_PIXEL_SIZE.y * block_size);
        
        // CORRECTED: The math now multiplies by pixel size, not divides.
        // This keeps the offset within a reasonable range.
        float glitch_offset = (random(vec2(block_line, TIME * animation_speed)) - 0.5) * 2.0 * glitch_strength * TEXTURE_PIXEL_SIZE.x;
        
        vec2 glitch_uv = UV + vec2(glitch_offset, 0.0);
        
        // CORRECTED: Using the fixed variable name here as well.
        vec2 r_uv = glitch_uv + vec2(chromatic_aberration * TEXTURE_PIXEL_SIZE.x, 0.0);
        vec2 b_uv = glitch_uv - vec2(chromatic_aberration * TEXTURE_PIXEL_SIZE.x, 0.0);

        float r = texture(TEXTURE, r_uv).r;
        float g = texture(TEXTURE, glitch_uv).g;
        float b = texture(TEXTURE, b_uv).b;

        COLOR = vec4(r, g, b, original_color.a);
    } else {
        discard;
    }
}