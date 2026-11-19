//
// shd_gaussian_vertical - blur ALONG the strands (up/down), first half of the
// BLUR feature. See shd_gaussian_horizontal for who calls it and how.
//
// Despite the name this is a BOX blur, not a gaussian: every tap has the same
// weight. It takes 501 taps in a column (bs = -250..+250) plus one extra
// sample of the centre pixel, 502 samples in all, each weighted
// spreadVal = 1/502, so the weights add up to exactly 1 (no brightness change).
//
// blurSize = HALF a texel (0.5/resolution.y) x blur_amount, so the column
// reaches +-125 x blur_amount pixels.
//
// COST: 502 texture reads per pixel over a 4096x4096 target. This is the
// expensive half of the blur. 'dist' is the number to lower if it is too slow
// (spreadVal follows it automatically).
//
// Uniforms: resolution and blur_amount are used; time and mouse_pos are not.
//
varying vec2 v_texcoord;

uniform float time;
uniform vec2 mouse_pos;
uniform vec2 resolution;
uniform float blur_amount;

void main()
{ 
float blurSize = 0.5/resolution.y * blur_amount;
float dist = 250.0;
float spreadVal = (1.0 / (dist+1.0))/2.0;
vec4 sum = vec4(0.0);
sum += texture2D(gm_BaseTexture, vec2(v_texcoord.x, v_texcoord.y)) * spreadVal;
for (float bs = (dist*-1.0) ; bs<=dist ; bs++)
	{
   sum += texture2D(gm_BaseTexture, vec2(v_texcoord.x, v_texcoord.y + (blurSize * bs))) * spreadVal;
	}
	
   gl_FragColor = sum;
}
