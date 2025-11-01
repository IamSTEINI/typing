shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform int pixel_size : hint_range(1, 16) = 4;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	
	vec2 pixelated_uv = floor(uv * screen_size / float(pixel_size)) * float(pixel_size) / screen_size;
	
	COLOR = texture(SCREEN_TEXTURE, pixelated_uv);
}