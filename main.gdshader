shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D underUI : source_color, hint_screen_texture;
uniform vec4 camPos;
uniform vec4 camLook;
uniform vec4 camLookRhs;
uniform vec2 screenRes;

varying vec2 scaledUV;

const int iters = 80;
const float farPlane = 40.0;
const float tolerance = 1e-4;
const vec3 noHitColor = vec3(0.0);
const vec3 farColor = vec3(0.0);

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
	scaledUV = (UV-0.5) * 2.0 * screenRes / max(1e-6, min(screenRes.x, screenRes.y)) * vec2(1,-1);
}

vec4 sphere(vec4 pos, float radius, vec3 color) {
	return vec4(color, length(pos)-radius);
}
vec4 cube(vec4 pos, vec4 size) {
	vec3 col = vec3(1,0,0);
	pos = abs(pos);
	if(pos.x > pos.y && pos.x > pos.z && pos.x > pos.w) col = vec3(0,1,0);
	else if(pos.y > pos.z && pos.y > pos.w) col = vec3(0,0,1);
	else if(pos.z > pos.w) col = vec3(1,0,1);
	return sphere(max(pos-size,0.0), 0.0, col);
}
vec4 union(vec4 a, vec4 b) {
	return a.w < b.w ? a : b;
}
vec4 intersect(vec4 a, vec4 b) {
	return a.w < b.w ? b : a;
}

vec4 cliffordTorus(vec4 pos, vec2 radius, float thickness, vec3 color) {
	//return intersect(vec4(color1, length(pos.xy)-radius.x), vec4(color2, length(pos.zw)-radius.y));
	return vec4(color, length(vec2(length(pos.xy),length(pos.zw))-radius)-thickness);
}

vec4 sdf(vec4 pos) {
	vec4 res = cube(fract(pos)-0.5, vec4(0.2));

	//vec4 res = sphere(pos-vec4(0.0), 1.0, vec3(1,0,0));
	//res = union(res, sphere(pos-vec4(3,0,0,0), 1.0, vec3(0,1,0)));
	//res = union(res, sphere(pos-vec4(3,0,0,0).yzwx, 1.0, vec3(0,0,1)));
	//res = union(res, sphere(pos-vec4(3,0,0,0).zwxy, 1.0, vec3(0,1,1)));
	//res = union(res, sphere(pos-vec4(3,0,0,0).wxyz, 1.0, vec3(1,0,1)));

	//vec4 res = sphere(fract(pos)-0.5, 0.2, vec3(1,0,1));
	
	//vec4 res = cliffordTorus(pos, vec2(1.0, 2.0), 0.2, vec3(1,0,1));

	return res;
}

const float normalEps = 1e-3;
vec4 getNormal(vec4 pos) {
	float orig = sdf(pos).w;
	float x = sdf(pos + vec4(normalEps, 0, 0, 0)).w;
	float y = sdf(pos + vec4(0, normalEps, 0, 0)).w;
	float z = sdf(pos + vec4(0, 0, normalEps, 0)).w;
	float w = sdf(pos + vec4(0, 0, 0, normalEps)).w;
	return normalize((vec4(x,y,z,w)-orig)/normalEps);
}

const vec4 sunDir = normalize(vec4(1));

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 localPixDir = quatBetween(vec3(0,0,-1), normalize(vec3(scaledUV, -1)));
	vec4 pixDir = quatMult(quatMult(camLook, localPixDir), quatMult(localPixDir, camLookRhs));
	vec4 currPos = camPos;
	float dist = 0.0;
	vec4 hit = vec4(noHitColor, -100.0);
	for(int i = 0; i < iters; i++) {
		if(dist > farPlane) {
			hit = vec4(farColor, -100.0);
			break;
		}
		vec4 res = sdf(currPos);
		if(res.w < tolerance) {
			hit = res;
			break;
		}
		currPos += pixDir * res.w;
		dist += res.w;
	}
	if(hit.w != -100.0) {
		vec4 normal = getNormal(currPos);
		float diffuse = max(0.0, dot(normal, sunDir));
		vec4 reflectDir = pixDir - 2.0*dot(normal, pixDir)*normal;
		float specular = pow(max(dot(reflectDir, sunDir), 0.0), 20.0);
		hit.xyz = clamp(hit.xyz*diffuse + vec3(specular) + vec3(0.1), 0.0, 1.0);
	} else {
		hit.xyz = clamp(pow(max(0.0, dot(pixDir, sunDir)), 100.0)*vec3(1.0) + vec3(0.0,0.8,0.8), 0.0, 1.0);
	}
	COLOR = vec4(hit.xyz, 1.0);

	vec4 under = texture(underUI, SCREEN_UV);
	vec3 underDiff = under.xyz - vec3(1,0,1);
	if(dot(underDiff, underDiff) < 1e-3) {
		COLOR.xyz = 1.0-COLOR.xyz;
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
