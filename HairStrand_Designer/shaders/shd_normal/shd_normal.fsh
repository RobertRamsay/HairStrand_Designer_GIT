uniform vec3 iResolution; 
uniform float bumpAmount;
uniform vec2 uvs;
varying vec2 v_texcoord; 


void main( void )
{
	
	//vec2 texelStep = vec2(0.0005208,0.0009259);// for HD res
	vec2 texelStep = vec2(0.0001,0.0001);// for 4k square

    float tl, ll, bl, tt, bb, tr, rr, br;
	tl = texture2D(gm_BaseTexture, v_texcoord + vec2(-texelStep.x, -texelStep.y)).r;
	ll = texture2D(gm_BaseTexture, v_texcoord + vec2(-texelStep.x, 0)).r;
	bl = texture2D(gm_BaseTexture, v_texcoord + vec2(-texelStep.x, texelStep.y)).r;
	tt = texture2D(gm_BaseTexture, v_texcoord + vec2(0, -texelStep.y)).r;
	bb = texture2D(gm_BaseTexture, v_texcoord + vec2(0, texelStep.y)).r;
	tr = texture2D(gm_BaseTexture, v_texcoord + vec2(texelStep.x, -texelStep.y)).r;
	rr = texture2D(gm_BaseTexture, v_texcoord + vec2(texelStep.x, 0)).r;
	br = texture2D(gm_BaseTexture, v_texcoord + vec2(texelStep.x, texelStep.y)).r;
	
	float dX = tr + 2.0 * rr + br - tl - 2.0 * ll - bl;
	float dY = bl + 2.0 * bb + br - tl - 2.0 * tt - tr;
	
	float bumpAmount = 0.5;
	vec3 normal = vec3(-dX * 255.0, dY * 255.0, 255.0 * bumpAmount);
	normal = normalize(normal);
   gl_FragColor = vec4(normal.xy * 0.5 + 0.5, normal.z, texture2D(gm_BaseTexture, v_texcoord).a);
}