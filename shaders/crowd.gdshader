shader_type spatial;

// Publikum. Die Sprungphase kann nicht aus dem Vertex-Alpha kommen: Blender
// exportiert COLOR_0 als VEC3, der Alphakanal geht dabei verloren. Stattdessen
// dient der Winkel um die Stadionmitte als Phase — er ist über alle Eckpunkte
// einer Figur praktisch konstant, sodass niemand auseinandergerissen wird.

uniform float excite : hint_range(0.0, 1.0) = 0.0;
uniform float jump_height = 0.45;
uniform float wave_height = 0.55;
uniform float idle_amount = 0.025;
uniform float wave_speed = 2.2;

void vertex() {
	float ang = atan(VERTEX.x, VERTEX.z);
	float idle = sin(TIME * 1.4 + ang * 9.0) * idle_amount;
	float jump = max(sin(TIME * 5.5 + ang * 7.0), 0.0) * jump_height * excite;
	float wave = smoothstep(0.72, 1.0, cos(ang - TIME * wave_speed));
	VERTEX.y += idle + jump + wave * wave_height * excite;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
}
