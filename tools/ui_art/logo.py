# Run from the project root:  python tools/ui_art/logo.py
# Writes its PNGs next to this script; copy them over the sprite frame and layer PNGs.
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np, os, math, random
S=os.path.dirname(os.path.abspath(__file__)); FN=os.path.join(S,'fonts','Orbitron.ttf')
OUT_W,OUT_H=1240,176          # sprite size (2x of the 620x88 it is drawn at)
SS=3                          # supersample
W,H=OUT_W*SS,OUT_H*SS
def font(size,var):
    f=ImageFont.truetype(FN,size); f.set_variation_by_name(var); return f
def text_tracked(d,x,y,s,f,track,fill=255):
    for ch in s:
        d.text((x,y),ch,font=f,fill=fill,anchor='ls'); x+=f.getlength(ch)+track
    return x
def width_tracked(s,f,track): return sum(f.getlength(c) for c in s)+track*(len(s)-1)

# ---- lettering ----
A,B='HAIR STRAND','DESIGNER'
size=100*SS
while True:
    fa=font(size,'Black'); fb=font(size,'Medium')
    ta=size*0.02; tb=size*0.10; gap=size*0.42
    tw=width_tracked(A,fa,ta)+gap+width_tracked(B,fb,tb)
    if tw<=W*0.965: break
    size-=2
base=int(H*0.56)
x0=(W-tw)/2
mask=Image.new('L',(W,H),0); d=ImageDraw.Draw(mask)
xe=text_tracked(d,x0,base,A,fa,ta)
maskB=Image.new('L',(W,H),0); dB=ImageDraw.Draw(maskB)
text_tracked(dB,xe-ta+gap,base,B,fb,tb)
cap=fa.getbbox('H',anchor='ls'); cap_top=base+cap[1]

# vertical gradient fill for the letters: white -> cool light grey
yy=np.linspace(0,1,H)[:,None]
t=np.clip((yy*H-cap_top)/(base-cap_top),0,1)
def grad(c0,c1): return np.dstack([np.broadcast_to(c0[i]+(c1[i]-c0[i])*t,(H,W)) for i in range(3)])
colA=grad((255,255,255),(196,200,210))
colB=grad((150,232,180),(84,196,128))      # the splash accent green, lit from above

# ---- strands under the lettering ----
strand=np.zeros((H,W,4),float)
random.seed(7)
PUR=np.array((150,100,250.)); GRN=np.array((90,200,130.)); WHT=np.array((235,235,245.))
layer=Image.new('RGBA',(W,H),(0,0,0,0)); ld=ImageDraw.Draw(layer)
n=11
xa,xb=x0-W*0.005,x0+tw+W*0.005
ymid=base+(H-base)*0.50
for i in range(n):
    u=i/(n-1)
    ph=random.uniform(0,6.28); amp=(H-base)*random.uniform(0.10,0.22)
    f1=random.uniform(1.2,1.9); f2=random.uniform(2.6,3.8)
    off=(u-0.5)*(H-base)*0.42
    wmax=SS*random.uniform(1.6,3.2)
    col=(PUR*(1-u)+GRN*u)*0.82+WHT*0.18
    pts=[]
    steps=420
    for k in range(steps+1):
        s=k/steps; x=xa+(xb-xa)*s
        pinch=0.35+0.65*math.sin(math.pi*s)**0.8          # gathers at both ends like a tress
        y=ymid+off*pinch+amp*pinch*(0.7*math.sin(f1*math.pi*2*s+ph)+0.3*math.sin(f2*math.pi*2*s+ph*1.7))
        pts.append((x,y,s))
    for k in range(steps):
        (x1,y1,s),(x2,y2,_)=pts[k],pts[k+1]
        fade=min(1,s/0.10,(1-s)/0.16); fade=max(0,fade)**1.3
        wd=max(1,wmax*(0.35+0.65*math.sin(math.pi*min(1,s*1.15))))
        ld.line((x1,y1,x2,y2),fill=tuple(int(c) for c in col)+(int(255*fade*0.92),),width=int(round(wd)))
layer=layer.filter(ImageFilter.GaussianBlur(SS*0.35))

# ---- compose (straight alpha, transparent background) ----
def over(dst,src_rgb,src_a):
    a=src_a[:,:,None]; da=dst[:,:,3:4]
    oa=a+da*(1-a)
    rgb=np.where(oa>0,(src_rgb*a+dst[:,:,:3]*da*(1-a))/np.maximum(oa,1e-6),0)
    return np.dstack([rgb,oa])
out=np.zeros((H,W,4),float)
L=np.asarray(layer).astype(float); out=over(out,L[:,:,:3],L[:,:,3]/255)
# soft dark halo so the letters sit above the strands and read on any backdrop
both=Image.fromarray(np.maximum(np.asarray(mask),np.asarray(maskB)))
halo=np.asarray(both.filter(ImageFilter.GaussianBlur(SS*5))).astype(float)/255
out=over(out,np.zeros((H,W,3)),np.clip(halo*1.25,0,1)*0.62)
out=over(out,colA,np.asarray(mask).astype(float)/255)
out=over(out,colB,np.asarray(maskB).astype(float)/255)
img=Image.fromarray(np.clip(np.dstack([out[:,:,:3],out[:,:,3]*255]),0,255).astype('uint8'),'RGBA').resize((OUT_W,OUT_H),Image.LANCZOS)
img.save(os.path.join(S,'spr_logoTitle.png'))
# preview on the card colour, at display size and at full size
bg=Image.new('RGBA',(OUT_W+60,OUT_H+40),(26,26,30,255)); bg.alpha_composite(img,(30,20))
half=bg.resize((bg.width//2,bg.height//2),Image.LANCZOS)
pv=Image.new('RGB',(bg.width,bg.height+half.height+10),(10,10,12)); pv.paste(bg.convert('RGB'),(0,0)); pv.paste(half.convert('RGB'),((bg.width-half.width)//2,bg.height+10)); pv.save(os.path.join(S,'logo_preview.png'))
print(img.size, 'text width frac', tw/W)
