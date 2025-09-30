shader_type canvas_item;

uniform vec4 glimmer_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// How bright a pixel must be to sparkle.
uniform float brightness_threshold : hint_range(0.0, 1.0) = 0.8;
// How fast the sparkles flash.
uniform float speed : hint_range(0.1, 10.0) = 3.0;
// The size of the sparkle glint.
uniform float glint_size : hint_range(1.0, 10.0) = 5.0;

// A simple pseudo-random number function.
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    
    // Calculate the brightness of the original pixel.
    float brightness = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));

    if (brightness > brightness_threshold) {
        // Create a random offset for the time, so not all pixels sparkle in sync.
        float time_offset = random(UV) * 100.0;
        
        // Create a flashing effect using sin(time).
        float flash = (sin(TIME * speed + time_offset) - 0.95) * 20.0;
        flash = clamp(flash, 0.0, 1.0);

        // --- Procedurally draw a star/glint shape ---
        vec2 relative_uv = fract(UV * 200.0) - 0.5; // Center the coordinate
        float star_x = 1.0 - abs(relative_uv.x) * glint_size;
        float star_y = 1.0 - abs(relative_uv.y) * glint_size;
        float glint = max(star_x, star_y);
        glint = clamp(glint, 0.0, 1.0);

        // Add the flashing glint to the original color.
        COLOR.rgb = original_color.rgb + (glimmer_color.rgb * glint * flash);
        COLOR.a = original_color.a;
    } else {
        COLOR = original_color;
    }
}