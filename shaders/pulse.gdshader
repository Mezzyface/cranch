shader_type canvas_item;

uniform float speed : hint_range(0.0, 2.0) = .5;
uniform float sweep_width : hint_range(0.0, 1.0) = 1;
uniform float black_threshold : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    if (original_color.a > 0.1) {
        float brightness = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));

        if (brightness < black_threshold) {
            COLOR = original_color; // Keep outline black
        } else {
            float sweep_position = fract(TIME * speed);
            vec3 inverted_color = 1.0 - original_color.rgb;
            float mix_factor = smoothstep(sweep_position - sweep_width, sweep_position, UV.x);
            vec3 final_color = mix(original_color.rgb, inverted_color, mix_factor);
            COLOR = vec4(final_color, original_color.a);
        }
    } else {
        discard;
    }
}