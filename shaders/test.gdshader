shader_type canvas_item;

// How fast the drip pattern changes.
uniform float drip_speed : hint_range(0.1, 20.0) = 5.0;
// How far the pixels can drip.
uniform float drip_strength : hint_range(0.0, 1.0) = 0.5;
// How many vertical "drip columns" there are.
uniform float density : hint_range(1.0, 100.0) = 40.0;
// Tints the color of the drips.
uniform vec4 drip_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    // Create vertical columns based on the x-coordinate.
    float column_x = floor(UV.x * density);
    
    // Create a pseudo-random value for each column that changes over time.
    float random_val = fract(sin(column_x * 13.7 + floor(TIME * drip_speed) * 41.1) * 2345.6);

    float drip_distance = pow(random_val, 2.0) * drip_strength;
    
    // Calculate the source of the drip (a spot vertically above the current pixel).
    vec2 source_uv = vec2(UV.x, UV.y - drip_distance);
    
    // --- THIS IS THE FIX ---
    // Clamp the UVs to prevent reading outside the texture, which causes errors.
    source_uv = clamp(source_uv, vec2(0.0), vec2(1.0));
    // ----------------------
    
    // Get the color from the now-safe source location and the original location.
    vec4 source_color = texture(TEXTURE, source_uv);
    vec4 original_color = texture(TEXTURE, UV);
    
    // If the current pixel is empty, BUT the pixel we are pulling from is visible...
    if (original_color.a < 0.1 && source_color.a > 0.1) {
        // ...then draw the dripped pixel here, tinted by the drip_color.
        COLOR = source_color * drip_color;
    } else {
        // ...otherwise, just draw the sprite as it is (or empty space).
        COLOR = original_color;
    }
}