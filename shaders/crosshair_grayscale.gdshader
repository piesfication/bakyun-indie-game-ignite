shader_type canvas_item;

uniform float grayscale_amount : hint_range(0.0, 1.0) = 0.0;
uniform float value_blend : hint_range(0.0, 1.0) = 0.45;
uniform float min_gray : hint_range(0.0, 1.0) = 0.38;

void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	float value = max(max(color.r, color.g), color.b);
	float gray = mix(luminance, value, value_blend);
	gray = max(gray, min_gray);
	color.rgb = mix(color.rgb, vec3(gray), grayscale_amount);
	COLOR = color;
}
