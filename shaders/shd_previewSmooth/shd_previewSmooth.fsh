//
// V1.96 - realtime smoothing for the strand preview.
//
// Preview strands are drawn as a stack of short VERTICAL dashes, one per
// sampled point, so a strand that leans sideways shows as a staircase - and a
// coarser one while a slider is being dragged, when the dashes are longer.
// This filter blends along the strand (vertically) over about one dash length,
// which turns each stair into a slope, plus a light sideways blend that
// softens the hard pixel edges. Nothing is redrawn: it runs on the GPU as the
// preview surfaces are put on screen.
//
// The surfaces hold strands on a transparent background, so the blend is
// alpha-weighted - otherwise the transparent black around each strand would
// be averaged in and every strand would gain a dark fringe.
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2  u_texel;    // size of one surface pixel in texture space
uniform float u_radius;   // blend distance along the strand, in surface pixels

void main()
{
    // 9 taps along the strand, gaussian weights, spread over +-u_radius
    float stepY = u_texel.y * u_radius * 0.25;
    vec4  acc   = vec4(0.0);
    vec4  c;

    c = texture2D(gm_BaseTexture, v_vTexcoord);                                   acc += vec4(c.rgb * c.a, c.a) * 0.2042;
    c = texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.0,  stepY));               acc += vec4(c.rgb * c.a, c.a) * 0.1801;
    c = texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.0, -stepY));               acc += vec4(c.rgb * c.a, c.a) * 0.1801;
    c = texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.0,  stepY * 2.0));         acc += vec4(c.rgb * c.a, c.a) * 0.1238;
    c = texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.0, -stepY * 2.0));         acc += vec4(c.rgb * c.a, c.a) * 0.1238;
    c = texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.0,  stepY * 3.0));         acc += vec4(c.rgb * c.a, c.a) * 0.0663;
    c = texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.0, -stepY * 3.0));         acc += vec4(c.rgb * c.a, c.a) * 0.0663;
    c = texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.0,  stepY * 4.0));         acc += vec4(c.rgb * c.a, c.a) * 0.0277;
    c = texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.0, -stepY * 4.0));         acc += vec4(c.rgb * c.a, c.a) * 0.0277;

    // light sideways softening: two half-pixel taps, mixed in at 20%
    vec4 side = vec4(0.0);
    c = texture2D(gm_BaseTexture, v_vTexcoord + vec2( u_texel.x * 0.6, 0.0));     side += vec4(c.rgb * c.a, c.a) * 0.5;
    c = texture2D(gm_BaseTexture, v_vTexcoord + vec2(-u_texel.x * 0.6, 0.0));     side += vec4(c.rgb * c.a, c.a) * 0.5;
    acc = mix(acc, side, 0.2);

    vec3 rgb = (acc.a > 0.0001) ? acc.rgb / acc.a : vec3(0.0);

    // Blending a one-pixel strand with the empty pixels around it lowers its
    // opacity, which made the whole preview look fainter than the unfiltered
    // one. Lifting the alpha back up keeps the strands as dense as they were
    // while the soft edges stay soft.
    float a = clamp(acc.a * 1.7, 0.0, 1.0);
    gl_FragColor = v_vColour * vec4(rgb, a);
}
