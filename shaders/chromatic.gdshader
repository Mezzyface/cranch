shader_type canvas_item;

uniform float max_strength : hint_range(0.0, 20.0) = 5.0;
uniform float speed : hint_range(0.0, 5.0) = 1.0;
uniform float black_threshold : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    if (original_color.a > 0.1) {
        float brightness = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));

        if (brightness < black_threshold) {
            COLOR = original_color; // Keep outline black and solid
        } else {
            float pulse = abs(sin(TIME * speed));
            float strength = pulse * max_strength * TEXTURE_PIXEL_SIZE.x;
            
            float r = texture(TEXTURE, UV + vec2(strength, 0.0)).r;
            float b = texture(TEXTURE, UV - vec2(strength, 0.0)).b;
            
            COLOR = vec4(r, original_color.g, b, original_color.a);
        }
    } else {
        discard;
    }
}