shader_type canvas_item;

void fragment(){
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
	COLOR = vec4(1.0 - color.rgb, color.a);
}