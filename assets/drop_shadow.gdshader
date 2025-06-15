shader_type canvas_item;

// Drop shadow properties
uniform float shadow_offset_x : hint_range(-5.0, 5.0, 0.0001) = 0.003;
uniform float shadow_offset_y : hint_range(-5.0, 5.0, 0.0001) = 0.003;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.6);
uniform float shadow_scale_x : hint_range(0.1, 2.0, 0.001) = 1.0;
uniform float shadow_scale_y : hint_range(0.1, 2.0, 0.001) = 0.5;
uniform bool use_original_alpha = true;

// Red tint properties
uniform bool enable_red_tint = false;
uniform float red_intensity : hint_range(0.0, 1.0, 0.01) = 0.7;
uniform vec4 red_color : source_color = vec4(1.0, 0.3, 0.3, 1.0);

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    vec2 shadow_uv = (UV - center) / vec2(shadow_scale_x, shadow_scale_y) + center;
    shadow_uv += vec2(shadow_offset_x, shadow_offset_y);

    vec4 shadow = texture(TEXTURE, shadow_uv);
    vec4 sprite = texture(TEXTURE, UV);

    // Use original sprite's alpha shape for consistent shadow
    if (use_original_alpha) {
        shadow.a = sprite.a * shadow_color.a;
    } else {
        shadow.a *= shadow_color.a;
    }
    shadow.rgb = shadow_color.rgb;

    // Combine shadow with sprite
    vec4 final_color = mix(shadow, sprite, sprite.a);

    // Apply red tint if enabled
    if (enable_red_tint) {
        // Mix the sprite color with red, preserving alpha
        final_color.rgb = mix(final_color.rgb, red_color.rgb, red_intensity * sprite.a);
    }

    COLOR = final_color;
}