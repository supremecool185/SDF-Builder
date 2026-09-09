shader_type spatial;

const vec2 RESOLUTION = vec2(1440.0, 1080.0);

uniform vec3 cameraPos = vec3(0, 0, -10);
uniform mat3 cameraRot = mat3(1);
uniform vec3 lightPos = vec3(50, -10, -100);
const float diffuseStrength = 1.2;
const float specularStrength = 0.7;

uniform float colorMix = 1.0;

const int shapeLimit = 32;
uniform int shapeTypes[shapeLimit];
uniform vec3 shapeTransforms[shapeLimit];
uniform mat3 shapeRotations[shapeLimit];
uniform vec3 shapeScales[shapeLimit];
uniform vec3 shapeColors[shapeLimit] : source_color;
uniform int shapeMerge[shapeLimit];
uniform float shapeSmooth[shapeLimit];

vec3 translate(vec3 pos, vec3 offset){
	return pos - offset;
}

vec2 SmoothMin(float a, float b , float k)
{
    float h = 1.0 - min( abs(a-b)/(4.0*k), 1.0 );
    float w = h*h;
    float m = w*0.5;
    float s = w*k;
    return (a<b) ? vec2(a-s,m) : vec2(b-s,1.0-m);
}

vec2 SmoothIntersect(float a, float b , float k){
	float h = clamp( 0.5 - 0.5*(b-a)/k, 0.0, 1.0 );
    return vec2(mix( b, a, h ) + k*h*(1.0-h), 0.5);
}

vec2 SmoothSubtract( float a, float b, float k )
{
    float h = clamp( 0.5 - 0.5*(b+a)/k, 0.0, 1.0 );
    return vec2(mix( b, -a, h ) + k*h*(1.0-h), 0.0);
}

float Sphere( vec3 p, float r )
{
  return length(p)-r;
}

float Cube( vec3 pos, vec3 s){
	vec3 q = abs(pos) - s;
	return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float Tetrahedron( vec3 p, float r )
{
	p = translate(p, vec3(0.0, 0.2, 0.0));
	p *= mat3(	//horrifying rotation needed to get the pyramid to sit face down
		vec3(-0.0000727, 0.5772852, 0.8165426), 
		vec3(-0.7070010, 0.5774395, -0.4083053), 
		vec3(-0.7072125, -0.5773261, 0.4080993));
	
    float a = +p.x +p.y;
    float c = +p.x -p.y;
	return (max(max(a,-a)-p.z,max(c,-c)+p.z)-r)/sqrt(3.);
}

float Torus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float Octahedron( vec3 p, float s )
{
  p = abs(p);
  float m = p.x+p.y+p.z-s;
  vec3 q;
       if( 3.0*p.x < m ) q = p.xyz;
  else if( 3.0*p.y < m ) q = p.yzx;
  else if( 3.0*p.z < m ) q = p.zxy;
  else return m*0.57735027;

  float k = clamp(0.5*(q.z-q.y+s),0.0,s);
  return length(vec3(q.x,q.y-s+k,q.z-k));
}

#define sqabs(p) sqrt((p)*(p)+2e-3)
#define sqmin(a,b) (a+b-sqabs(a-b))*.5
#define sqmax(a,b) (a+b+sqabs(a-b))*.5
float Dodecahedron(vec3 p, float r) {
	float G=sqrt(5.)*.5+.5;
	vec3 n=normalize(vec3(G,1,0));
	float d=0.;
    p=sqabs(p);
    d=sqmax(d,dot(p,n));
    d=sqmax(d,dot(p,n.yzx));
    d=sqmax(d,dot(p,n.zxy));
	return d-r;
}

float Icosahedron(vec3 p, float radius) {
    float q = 2.61803398875; // Golden Ratio + 1 = (sqrt(5)+3)/2;
    vec3 n1 = normalize(vec3(q, 1,0));
    vec3 n2 = vec3(0.57735026919);  // = sqrt(3)/3);

    p = abs(p / radius);
    float a = dot(p, n1.xyz);
    float b = dot(p, n1.zxy);
    float c = dot(p, n1.yzx);
    float d = dot(p, n2) - n1.x;
    return max(max(max(a,b),c)-n1.x,d) * radius;
}

vec4 scene(vec3 pos){
	float dist = 1e10;
	vec4 result;
	result.rgb = vec3(0.0, 0.0, 0.0);

	for(int i=0; i<shapeLimit; i++){
		float tempDist = 1e10;
		vec3 p = translate(pos, shapeTransforms[i]) * inverse(shapeRotations[i]);
		switch(shapeTypes[i]){
			case 1:
				tempDist = Cube(p, shapeScales[i]);
				break;
			case 2:
				tempDist = Sphere(p, shapeScales[i].x);
				break;
			case 3:
				tempDist = Tetrahedron(p, shapeScales[i].x);
				break;
			case 4:
				tempDist = Torus(p, shapeScales[i].xy);
				break;
			case 5:
				tempDist = Octahedron(p, shapeScales[i].x);
				break;
			case 6:
				tempDist = Dodecahedron(p, shapeScales[i].x);
				break;
			case 7:
				tempDist = Icosahedron(p, shapeScales[i].x);
				break;
			case 0:
				result.a = dist;
				return result;
		}
		
		vec2 Mix;
		if(i==0){
			result.rgb = shapeColors[i];
			dist = min(dist, tempDist);
			continue;
		}
		switch(shapeMerge[i]){
			case 0:
				Mix = SmoothMin(dist, tempDist, shapeSmooth[i]);
				Mix.r = (shapeSmooth[i]<0.1) ? min(dist, tempDist) : Mix.r;
				break;
			case 1:
				Mix = SmoothIntersect(dist, tempDist, shapeSmooth[i]);
				Mix.r = (shapeSmooth[i]<0.1) ? max(dist, tempDist) : Mix.r;
				break;
			case 2:
				Mix = SmoothSubtract(tempDist, dist, shapeSmooth[i]);
				Mix.r = (shapeSmooth[i]<0.1) ? max(dist, -tempDist) : Mix.r;
				break;
		}
		result.rgb = mix(result.rgb, shapeColors[i] , Mix.y);
		dist = Mix.x;
	}
	result.a = dist;
	return result;
}

vec3 calcNormals(vec3 pos){
	const vec3 dx = vec3(0.001, 0, 0);
	vec3 normal;

	normal.x = (scene(pos + dx.xyy)).a - (scene(pos).a);
	normal.y = (scene(pos + dx.yxy)).a - (scene(pos).a);
	normal.z = (scene(pos + dx.yyx)).a - (scene(pos).a);

	return normalize(normal);
}

vec4 rayMarch(vec3 origin, vec3 direction){
	direction = normalize(direction);
	float totalDist = 0.0;
	float nearestDist = 1e10;

	const int maxSteps = 128;
	const float minDist = 0.001;
	const float maxDist = 10000.0;

	for(int i=0; i<maxSteps; i++){
		vec3 position = origin + totalDist*direction;
		vec4 scene = scene(position);
		float dist = scene.a;
		vec3 color = scene.rgb;
		if(dist < nearestDist){ nearestDist = dist; }

		if(dist <= minDist){
			vec3 normal = calcNormals(position);
			vec3 lightDir = normalize(lightPos - position);
			float lighting = diffuseStrength * max(0.0, dot(normal, lightDir));
			lighting += specularStrength * pow(max(0.0, dot(direction, reflect(lightDir, normal))), 16);
			color *= lighting;
			return vec4(color, 1.0);
		}
		if(dist > maxDist){ break; }

		totalDist += dist;
	}

	return vec4(0.0, 0.0, 0.0, 0.0);
}

void fragment() {
	vec2 uv = vec2(UV.x, UV.y);
	uv -= vec2(0.5, 0.5);
	uv *= RESOLUTION;

	vec4 result = rayMarch(cameraPos, vec3(uv, RESOLUTION.y) * cameraRot);
	ALBEDO = clamp(result.rgb, 0.0, 1.0);
	ALPHA = clamp(result.a, 0.0, 1.0);
}