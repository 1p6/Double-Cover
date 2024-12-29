shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D worldA : source_color;
uniform sampler2D worldB : source_color;
uniform sampler2D quatShader : source_color, filter_nearest;
uniform mat3 camTransform;

vec2 dirToUV(in vec3 dir) {
	vec3 mag = abs(dir);
	float part;
	if(mag.x > mag.y && mag.x > mag.z) { // YZ plane
		part = 0.0;
	} else if(mag.y > mag.z) { // XZ plane
		part = 1.0;
		mag = mag.yxz;
		dir = dir.yxz;
	} else { // XY plane
		part = 2.0;
		mag = mag.zxy;
		dir = dir.zxy;
	}
	return ((dir.yz/max(mag.x, 1e-6)+1.0)/2.0 + vec2(part, (sign(dir.x)+1.0)/2.0)) / vec2(3.0, 2.0);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec3 pos = normalize(camTransform * vec3(UV*2.0-1.0, 1.0));
	float side = round(texture(quatShader, dirToUV(pos)).z);
	vec4 aColor = texture(worldA, UV);
	//vec4 aColor = vec4(vec3(texture(quatShader, dirToUV(pos)).z), 1.0);
	//vec4 aColor = texture(quatShader, dirToUV(pos));
	//vec4 aColor = vec4(vec3(max(dot(sin(pos*32.0), vec3(1.0)), 0.0)*pos)/2.0+0.5, 1.0);
	//vec4 aColor = vec4(vec3(pos.y)/2.0+0.5, 1.0);
	vec4 bColor = texture(worldB, UV);
	COLOR = mix(aColor, bColor, side);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
