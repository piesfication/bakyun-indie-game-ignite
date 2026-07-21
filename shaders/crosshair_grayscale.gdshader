shader_type canvas_item;

uniform float grayscale_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	float luminance = dot(color.rgb, vec3(0.5, 0.587, 0.114));
	color.rgb = mix(color.rgb, vec3(luminance), grayscale_amount);
	COLOR = color;
}
