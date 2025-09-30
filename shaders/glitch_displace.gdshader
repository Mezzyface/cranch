shader_type canvas_item;

// How often glitches happen (higher is more frequent).
uniform float glitch_frequency : hint_range(0.0, 20.0) = 1;
// How long each glitch lasts (as a fraction of the cycle).
uniform float glitch_duration = 10;
// The size of the block to copy (in pixels).
uniform vec2 block_size = vec2(30.0, 30.0);
// The maximum distance the block can be displaced (in pixels).
uniform float max_offset : hint_range(0.0, 256.0) = 60.0;

// A simple pseudo-random number function.
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // Start by drawing the original sprite.
    COLOR = texture(TEXTURE, UV);

    // Determine if we are currently inside a "glitch event" period.
    float cycle_progress = fract(TIME * glitch_frequency);

    if (cycle_progress < glitch_duration) {
        // Use a stable seed for the duration of this specific glitch.
        float seed = floor(TIME * glitch_frequency);
        
        // --- Generate random properties for this glitch event ---
        // 1. Random top-left corner for the source block (in UV space).
        vec2 source_pos_uv = vec2(random(vec2(seed, 1.0)), random(vec2(seed, 2.0)));
        
        // 2. Convert block size from pixels to UV space.
        vec2 block_size_uv = block_size * TEXTURE_PIXEL_SIZE;
        
        // 3. Random offset vector.
        vec2 offset_direction = vec2(random(vec2(seed, 3.0)) - 0.5, random(vec2(seed, 4.0)) - 0.5);
        vec2 offset = normalize(offset_direction) * max_offset * TEXTURE_PIXEL_SIZE.x;
        
        // --- Check if the current pixel should be part of the displaced block ---
        // Calculate which source pixel would land here after being offset.
        vec2 source_uv = UV - offset;
        
        // Check if that source_uv is inside our randomly chosen block.
        bool in_block_x = source_uv.x > source_pos_uv.x && source_uv.x < source_pos_uv.x + block_size_uv.x;
        bool in_block_y = source_uv.y > source_pos_uv.y && source_uv.y < source_pos_uv.y + block_size_uv.y;
        
        if (in_block_x && in_block_y) {
            // If it is, draw the pixel from the source block.
            COLOR = texture(TEXTURE, source_uv);
        }
    }
}