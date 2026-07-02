shader_type canvas_item;

uniform sampler2D mask_texture;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float scale : hint_range(0.0, 10.0) = 0.0;

void fragment() {
    // Memusatkan UV agar membesar dari tengah
    vec2 uv = UV - vec2(0.5);
    uv /= max(scale, 0.0001); 
    uv += vec2(0.5);

    // Mencegah tekstur berulang di luar batas
    float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);

    // Mengambil nilai alpha dari mask (gunakan .r jika mask berupa gambar hitam-putih)
    float mask_alpha = texture(mask_texture, uv).a * inside;

    // Menampilkan warna ColorRect, dan melubanginya sesuai bentuk mask
    COLOR = vec4(color.rgb, color.a * (1.0 - mask_alpha));
}