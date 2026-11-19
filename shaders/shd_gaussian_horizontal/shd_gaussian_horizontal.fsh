//
// shd_gaussian_horizontal - sideways blur, second half of the BLUR feature.
//
// USED BY  obj_surfaceDweller Draw_0 (B key / blur button, any map view except
//          the previewer) and obj_controller_gaussian_blur. In Draw_0 the map
//          on show is drawn through this shader into blurSurface, and the
//          result is copied back over the map canvas - so the blur is
//          permanent on that map until it is generated again.
//
// 9 taps along X, spaced blurSize apart, with fixed gaussian-style weights.
// blurSize = one texel (1/resolution.x) x blur_amount, so blur_amount is the
// tap spacing in pixels and the total reach is +-4 x that.
//
// The nine weights add up to 0.98, not 1.0, so each pass darkens the image by
// 2%. Draw_0 follows the blur with an additive "brightness compensation" pass.
//
// Uniforms: resolution (Draw_0 passes 4096,4096) and blur_amount are used.
// time and mouse_pos are declared but not used.
// Alpha is blurred along with RGB (all four channels are summed).
//
varying vec2 v_texcoord;

uniform float time;
uniform vec2 mouse_pos;
uniform vec2 resolution;
uniform float blur_amount;

void main()
{ 
float blurSize = 1.0/resolution.x * blur_amount;

   vec4 sum = vec4(0.0);

   sum += texture2D(gm_BaseTexture, vec2(v_texcoord.x - 4.0*blurSize, v_texcoord.y)) * 0.05;
   sum += texture2D(gm_BaseTexture, vec2(v_texcoord.x - 3.0*blurSize, v_texcoord.y)) * 0.09;
   sum += texture2D(gm_BaseTexture, vec2(v_texcoord.x - 2.0*blurSize, v_texcoord.y)) * 0.12;
   sum += texture2D(gm_BaseTexture, vec2(v_texcoord.x - blurSize, v_texcoord.y)) * 0.15;
   sum += texture2D(gm_BaseTexture, vec2(v_texcoord.x, v_texcoord.y)) * 0.16;
   sum += texture2D(gm_BaseTexture, vec2(v_texcoord.x + blurSize, v_texcoord.y)) * 0.15;
   sum += texture2D(gm_BaseTexture, vec2(v_texcoord.x + 2.0*blurSize, v_texcoord.y)) * 0.12;
   sum += texture2D(gm_BaseTexture, vec2(v_texcoord.x + 3.0*blurSize, v_texcoord.y)) * 0.09;
   sum += texture2D(gm_BaseTexture, vec2(v_texcoord.x + 4.0*blurSize, v_texcoord.y)) * 0.05;

   gl_FragColor = sum;
}
