# Run from the project root:  python tools/ui_art/btn.py
# Writes its PNGs next to this script; copy them over the sprite frame and layer PNGs.
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np, glob, os
S=os.path.dirname(os.path.abspath(__file__))
fs=sorted(glob.glob('sprites/spr_but_StrandType/*.png'))
orig=[np.asarray(Image.open(f).convert('RGBA')).astype(float) for f in fs]
base=orig[0].copy(); H,W=base.shape[:2]
face=base[:,8,:3].copy()
for y in range(9,25): base[y,8:66,:3]=face[y]      # wipe the old lettering back to the face gradient
SS=8
FN=os.path.join(S,'fonts','Syncopate-Bold.ttf')
def make(l1,l2):
    out=base.copy()
    m=Image.new('L',(W*SS,H*SS),0); d=ImageDraw.Draw(m)
    for txt,by in ((l1,15.9),(l2,23.0)):
        fs_=60
        while True:
            f=ImageFont.truetype(FN,fs_)
            if sum(f.getlength(c) for c in txt)+1*(len(txt)-1) <= 55*SS or fs_<40: break
            fs_-=1
        # tighten tracking slightly, centre on the face
        w=sum(f.getlength(c) for c in txt)+1*(len(txt)-1); x=(37.6*SS)-w/2
        for c in txt:
            d.text((x,by*SS),c,font=f,fill=255,anchor='ls',stroke_width=3,stroke_fill=255); x+=f.getlength(c)+1
    sh_k=0.12
    m=m.transform(m.size,Image.AFFINE,(1,sh_k,-sh_k*17.0*SS,0,1,0),resample=Image.BICUBIC)
    M=np.asarray(m.resize((W,H),Image.BOX)).astype(float)/255
    sh=Image.new('L',m.size,0); sh.paste(m,(0,int(1.0*SS))); sh=sh.filter(ImageFilter.GaussianBlur(SS*0.55))
    Sm=np.asarray(sh.resize((W,H),Image.BOX)).astype(float)/255
    # per-line top-to-bottom shading like the original lettering
    col=np.zeros((H,W))
    for (t,b) in ((10,15.9),(17.2,23.0)):
        for y in range(int(t)-1,int(b)+2):
            u=min(max((y-t)/(b-t),0),1); col[y,:]=232-(62*u)
    rgb=out[:,:,:3]
    rgb[:]=rgb*(1-0.62*Sm[:,:,None])*(1-M[:,:,None])+col[:,:,None]*M[:,:,None]
    return Image.fromarray(np.clip(np.round(out),0,255).astype('uint8'),'RGBA')
a=make('LIVE','UPDATE'); b=make('BUSY','UPDATE')
a.save(os.path.join(S,'btn_live.png')); b.save(os.path.join(S,'btn_busy.png'))
c1=make('SMOOTH','PREVIEW'); c2=make('RAW','PREVIEW'); c1.save(os.path.join(S,'btn_smooth.png')); c2.save(os.path.join(S,'btn_raw.png'))
c=Image.new('RGBA',(W*4,H),(42,42,42,255))
for i,im in enumerate([Image.fromarray(orig[0].astype('uint8'),'RGBA'),a,c1,c2]): c.alpha_composite(im,(i*W,0))
c.resize((W*4*6,H*6),Image.LANCZOS).save(os.path.join(S,'btn_cmp.png'))
