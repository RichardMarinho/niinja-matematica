shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(0.1, 1.0, 0.2, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.02, 0.5) = 0.18;

void fragment() {
	float distance_to_edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float edge_glow = 1.0 - smoothstep(0.0, edge_width, distance_to_edge);
	float alpha = edge_glow * strength * 0.38;
	COLOR = vec4(flash_color.rgb, alpha);
}
