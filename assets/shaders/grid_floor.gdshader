shader_type spatial;

uniform vec3 albedo : source_color = vec3(0.1, 0.1, 0.1);
uniform vec3 grid_color : source_color = vec3(0.5, 0.5, 0.5);
uniform float grid_size = 2.0;
uniform float line_thickness = 0.05;

void fragment() {
	vec2 uv = UV * (20.0 / grid_size); // Assuming plane size is 20
	vec2 grid = abs(fract(uv - 0.5) - 0.5) / fwidth(uv);
	float line = min(grid.x, grid.y);
	float alpha = 1.0 - smoothstep(line_thickness, line_thickness + 1.0, line);
	
	ALBEDO = mix(albedo, grid_color, alpha);
	ROUGHNESS = 0.8;
}
