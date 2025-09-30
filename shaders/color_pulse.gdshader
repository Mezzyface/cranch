shader_type canvas_item;

uniform vec4 pulse_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform float speed : hint_range(0.1, 10.0) = 5.0;

void fragment() {
    // Get the original color and alpha of the sprite.
    vec4 original_color = texture(TEXTURE, UV);
    
    // Only run this code for the visible parts of the sprite.
    if (original_color.a > 0.1) {
        // Create a "breathing" effect using a sine wave.
        // This creates a smooth pulse from 0.0 to 1.0.
        float pulse = (sin(TIME * speed) + 1.0) * 0.5;
        
        // Mix the original color with the pulse color based on the pulse.
        vec3 final_rgb = mix(original_color.rgb, pulse_color.rgb, pulse);
        
        // Set the final color.
        COLOR = vec4(final_rgb, original_color.a);
        
    } else {
        // If the pixel is transparent, discard it.
        discard;
    }
}