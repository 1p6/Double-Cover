shader_type canvas_item;
render_mode blend_disabled;

//uniform sampler2D previousFrame : source_color, hint_screen_texture;
uniform sampler2D previousFrame : source_color;
uniform float fadeSpeed;
uniform vec4 cameraQuat;
uniform bool clear;
uniform float deltaTime;

void vertex() {
	// Called for every vertex the material is visible on.
}

vec3 uvToDir(in vec2 uv) {
	uv *= vec2(3,2);
	vec2 part = floor(uv);
	vec2 pos = fract(uv)*2.0 - 1.0;
	float side = part.y*2.0 - 1.0;
	vec3 res;
	if(part.x < 0.5) { // YZ plane
		res.yz = pos;
		res.x = side;
	} else if(part.x < 1.5) { // XZ plane
		res.xz = pos;
		res.y = side;
	} else { // XY plane
		res.xy = pos;
		res.z = side;
	}
	return res;
}

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

vec4 quatBetween(in vec3 from, in vec3 to) {
	// from https://github.com/godotengine/godot/blob/75ce4266c4774b30ed5df67e6c43365418fcce5f/core/math/quaternion.h#L143
	vec3 c = cross(from, to);
	float d = dot(from, to);

	if(d < 1e-8 - 1.0) {
		return vec4(0, 1, 0, 0);
	} else {
		float s = sqrt((1.0 + d) * 2.0);
		float rs = 1.0 / s;
		return vec4(c*rs, s * 0.5);
	}
}

vec3 quatXform(in vec4 quat, in vec3 pos) {
	// from https://github.com/godotengine/godot/blob/75ce4266c4774b30ed5df67e6c43365418fcce5f/core/math/quaternion.h#L90
	vec3 uv = cross(quat.xyz, pos);
	return pos + ((uv * quat.w) + cross(quat.xyz, uv)) * 2.0;
}

vec4 quatMult(in vec4 a, in vec4 b) {
	return vec4(a.w * b.xyz + a.xyz * b.w + cross(a.xyz, b.xyz),
				a.w * b.w - dot(a.xyz, b.xyz));
}

vec4 quatConj(in vec4 a) {
	return vec4(-a.xyz, a.w);
}

float hash(in vec4 a) {
	return sin(dot(a, vec4(827972.0, 137828.0, 894827.0, 198925.0)));
}

float moveTowards(float current, float target, float amount) {
	if(abs(current - target) < amount) return target;
	return current + sign(target - current) * amount;
}

void fragment() {
	// Called for every pixel the material is visible on.
	if(clear) {
		COLOR = vec4(0.5, 1, 0, 1);
	} else {
		vec4 prev = texture(previousFrame, UV);
		vec3 dir = normalize(uvToDir(UV));
		vec3 lookDir = quatXform(cameraQuat, vec3(0.0, 0.0, -1.0));
		vec4 directQuat = quatBetween(vec3(0,0,-1), dir);
		vec2 prevRot = prev.xy*2.0 - 1.0;
		float prevRotLen = length(prevRot);
		prevRot = prevRotLen < 1e-8 ? vec2(0,1) : prevRot / prevRotLen;
		vec4 prevQuat = quatMult(directQuat, vec4(0, 0, prevRot));
		vec4 currentQuat = quatMult(quatBetween(lookDir, dir), cameraQuat);
		float nextSide = prev.z;
		//if(dot(prevQuat, currentQuat)*10.0 < hash(vec4(dir, TIME))) {
		if(dot(prevQuat, currentQuat) < -0.2) {
			nextSide = 1.0-nextSide;
		}
		vec2 nextRot = normalize(quatMult(quatConj(directQuat), currentQuat).zw);

		vec3 nextColor;
		if(dot(dir, lookDir) > 0.0) { // pixel is visible
			nextColor = vec3(nextRot, nextSide);
		} else { // pixel is not visible
			nextColor = prev.xyz;
		}
		vec3 prevCenter = texture(previousFrame, dirToUV(lookDir)).xyz;
		vec3 fadeToColor = vec3(nextRot, round(prevCenter.z));
		float fadeAmount = fadeSpeed * deltaTime;
		COLOR = vec4(normalize(mix(nextColor.xy, fadeToColor.xy, fadeAmount)),
				moveTowards(nextColor.z, fadeToColor.z, fadeAmount), 1.0);
	}
	//COLOR = vec4(fract(prev.rgb + vec3(0.1, 0.2, 0.3)/60.0), 1.0);
	//COLOR = vec4(dirToUV(uvToDir(UV)), 0.0, 1.0);
	//COLOR = vec4(fract(VERTEX/2.0)*2.0, 0.0, 1.0);
	//COLOR = vec4(normalize(uvToDir(UV))/2.0+0.5, 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
