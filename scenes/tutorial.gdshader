shader_type canvas_item;

void fragment() {
    // Membalikkan transparansi kotak induk menjadi lubang transparan
    COLOR = vec4(0.0, 0.0, 0.0, 0.0);
}
