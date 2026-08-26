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
