//
// shd_normal - turns a HEIGHT map into a tangent-space NORMAL map.
//
// USED ONLY IN MULTI STRAND MODE (moreHairs==1). In that mode doMainStep draws
// the normal canvas (nm_canvas) as a greyscale height map (white bump sprites
// on black). This shader converts it whenever it is shown or written out:
//   Draw_0            when the Normal map view is on screen
//   KeyPress_83       when saving      (via the scratch surface tNormsurf)
//   exportIndividual  when exporting   (via tNormsurf)
// In Single Strand mode the canvas already holds normal colours and this
// shader is not used.
//
// HOW  A Sobel filter on the RED channel: the eight neighbours of the pixel
// give the slope across (dX) and down (dY). The normal is
// (-dX, dY, bumpAmount), normalised; x and y are packed from -1..1 into 0..1,
// z is written as it is. Alpha is copied from the source pixel.
//
// THINGS TO KNOW
//  - texelStep is a fixed 0.0001. One pixel of a 4096 texture is 1/4096 =
//    0.000244, so the neighbours are sampled less than half a pixel away.
//  - bumpAmount is declared as a uniform at the top AND again as a local
//    (= 0.5) inside main(). The local is the one the maths uses, so setting
//    the uniform from GML has no effect. A smaller value gives a stronger bump.
//  - iResolution and uvs are declared but not used.
//
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