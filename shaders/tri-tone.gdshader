shader_type canvas_item;

uniform vec4 shadow_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform vec4 mid_tone_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.9, 0.9, 0.9, 1.0);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.33;
uniform float highlight_threshold : hint_range(0.0, 1.0) = 0.66;
uniform float black_threshold : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    if (original_color.a > 0.1) {
        float brightness = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));
        
        if (brightness < black_threshold) {
            COLOR = original_color; // Keep outline black
        } else {
            vec3 final_color;
            if (brightness < shadow_threshold) {
                final_color = shadow_color.rgb;
            } else if (brightness < highlight_threshold) {
                final_color = mid_tone_color.rgb;
            } else {
                final_color = highlight_color.rgb;
            }
            COLOR = vec4(final_color, original_color.a);
        }
    } else {
        discard;
    }
}