shader_type canvas_item;

uniform sampler2D previousFrame : source_color;
uniform vec4 cameraQuat;

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

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 prev = round(texture(previousFrame, UV));
	//COLOR = vec4(dirToUV(uvToDir(UV)), 0.0, 1.0);
	//COLOR = vec4(fract(VERTEX/2.0)*2.0, 0.0, 1.0);
	COLOR = vec4(normalize(uvToDir(UV))/2.0+0.5, 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
