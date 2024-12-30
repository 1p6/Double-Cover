shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D worldA : source_color;
uniform sampler2D worldB : source_color;
uniform sampler2D quatShader : source_color, filter_nearest;
uniform sampler2D underUI : source_color, hint_screen_texture;
uniform sampler2D noiseTex : source_color;
uniform mat3 camTransform;

varying vec3 posLinear;

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

float hash(in vec4 a, in float b) {
	return sin(dot(a, vec4(827.972, 137.828, 894.827, 198.925)) + b*981.7927);
}

vec3 hash3(in vec4 a) {
	return vec3(
		hash(a, 1.0),
		hash(a, 2.0),
		hash(a, 3.0)
	);
}

void vertex() {
	// Called for every vertex the material is visible on.
	posLinear = camTransform * vec3(UV*2.0-1.0, 1.0);
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec3 pos = normalize(posLinear);
	vec2 cubeUV = dirToUV(pos);
	float side = texture(quatShader, cubeUV).z;
	vec3 aColor = texture(worldA, UV).xyz;
	//vec4 aColor = vec4(vec3(texture(quatShader, dirToUV(pos)).z), 1.0);
	//vec4 aColor = texture(quatShader, dirToUV(pos));
	//vec4 aColor = vec4(vec3(max(dot(sin(pos*32.0), vec3(1.0)), 0.0)*pos)/2.0+0.5, 1.0);
	//vec4 aColor = vec4(vec3(pos.y)/2.0+0.5, 1.0);
	vec3 bColor = texture(worldB, UV).xyz;
	vec3 sinPos = sin(pos*200.0);
	//vec3 noise = vec3(sinPos.x*sinPos.y*sinPos.z/2.0+0.5);
	vec3 noise = texture(noiseTex, cubeUV).xyz;
	COLOR = vec4(mix(mix(aColor, bColor, side), noise, side*(1.0-side)*1.0), 1.0);

	vec4 under = texture(underUI, UV);
	vec3 crosshairDiff = under.xyz - vec3(1, 0, 1);
	if(dot(crosshairDiff, crosshairDiff) < 1e-3) {
		COLOR.xyz = 1.0 - COLOR.xyz;
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
