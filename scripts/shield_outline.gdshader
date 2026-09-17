shader_type canvas_item;
// Shield outline glow (R7 §B side channel). Attached to the actor Sprite2D only
// while a shield value is active; alpha scales linearly with the shield value
// and drops to zero automatically when the shield breaks.
// Samples stay clamped inside the current atlas region so neighbouring
// illustration cells can never bleed into the outline.

uniform vec4 outline_color : source_color = vec4(0.56, 0.87, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 12.0) = 4.0;
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float glow_alpha : hint_range(0.0, 1.0) = 1.0;
uniform vec4 region_rect = vec4(0.0, 0.0, 1.0, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * outline_width;
	float alpha_sum = 0.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.7853981634;
		vec2 offset = vec2(cos(a), sin(a)) * px;
		vec2 sample_uv = clamp(UV + offset, region_rect.xy, region_rect.xy + region_rect.zw);
		alpha_sum += texture(TEXTURE, sample_uv).a;
	}
	float edge = step(0.05, alpha_sum) * (1.0 - base.a);
	float pulse = 0.82 + 0.18 * sin(TIME * 3.0);
	COLOR = base;
	COLOR.rgb += outline_color.rgb * edge * glow_intensity * pulse * glow_alpha;
	COLOR.a = max(base.a, edge * glow_alpha * 0.9);
}
