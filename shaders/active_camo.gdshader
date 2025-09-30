shader_type canvas_item;

// This render_mode is required to access the screen behind the sprite
render_mode blend_add;

uniform float distortion_strength : hint_range(0.0, 50.0) = 10.0;
uniform float distortion_speed : hint_range(0.0, 5.0) = 0.5;
uniform float visibility : hint_range(0.0, 1.0) = 0.1;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Simple procedural noise for distortion
float noise(vec2 uv) {
    return (sin(uv.x * 12.0) + sin(uv.y * 12.0)) * 0.5;
}

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    
    // Only apply effect where the sprite is visible
    if (original_color.a > 0.1) {
        // Calculate the distortion offset using scrolling noise
        vec2 distorted_uv = SCREEN_UV;
        distorted_uv.x += noise(vec2(UV.y * 5.0, TIME * distortion_speed)) * distortion_strength * SCREEN_PIXEL_SIZE.x;
        distorted_uv.y += noise(vec2(UV.x * 5.0, TIME * distortion_speed)) * distortion_strength * SCREEN_PIXEL_SIZE.y;

        // Get the color from behind the sprite with the distortion
        vec3 background_color = texture(SCREEN_TEXTURE, distorted_uv).rgb;
        
        // Blend the creature's original color with the distorted background
        vec3 final_color = mix(background_color, original_color.rgb, visibility);
        
        COLOR = vec4(final_color, 1.0); // Alpha is handled by the "Add" blend mode
    } else {
        discard;
    }
}