# Run from the project root:  python tools/ui_art/help_panel.py
# Writes its PNGs next to this script; copy them over the sprite frame and layer PNGs.
"""Rebuild spr_HelpPanel at 2x (2042 x 2048), in the original's style."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np, os, glob

S = os.path.dirname(os.path.abspath(__file__))
MONT = os.path.join(S, 'fonts', 'Montserrat.ttf')
ORB = os.path.join(S, 'fonts', 'Orbitron.ttf')

# ---- background: the original panel with its lettering removed ----
orig = np.asarray(Image.open(os.path.join(S, 'help_panel_base.png')).convert('RGBA')).astype(float)
H0, W0 = orig.shape[:2]
bg = orig.copy()
B = 16                                  # soft dark border, kept as it was
col = orig[:, 1002, :].copy()           # a text-free column: the panel's vertical gradient
for y in range(B, H0 - B):
    bg[y, B:W0 - B, :] = col[y]
bg[:, :, 3] = orig[:, :, 3]
img = Image.fromarray(np.clip(bg, 0, 255).astype('uint8'), 'RGBA').resize((W0 * 2, H0 * 2), Image.BICUBIC)
W, H = img.size
d = ImageDraw.Draw(img)


def font(path, size, var):
    f = ImageFont.truetype(path, size)
    f.set_variation_by_name(var)
    return f


F_BODY = font(MONT, 29, 'Medium')
F_BOLD = font(MONT, 29, 'Bold')
F_KEY = font(ORB, 24, 'Bold')
F_HEAD = font(ORB, 32, 'Bold')
F_SMALL = font(MONT, 24, 'Medium')
F_VER = font(MONT, 26, 'SemiBold')

WHITE = (236, 236, 242, 255)
SOFT = (196, 196, 208, 255)
GREEN = (104, 212, 144, 255)
PURPLE = (176, 140, 255, 255)
RULE = (120, 120, 136, 255)
LH = 40                                  # body line height


def wrap(text, f, width):
    out, cur = [], ''
    for w in text.split(' '):
        t = (cur + ' ' + w) if cur else w
        if f.getlength(t) > width and cur:
            out.append(cur)
            cur = w
        else:
            cur = t
    if cur:
        out.append(cur)
    return out


def heading(x, y, text, width):
    d.text((x, y), text, font=F_HEAD, fill=GREEN)
    yy = y + 44
    d.line((x, yy, x + width, yy), fill=RULE, width=2)
    return yy + 16


def para(x, y, text, width, f=None, fill=WHITE, lh=LH):
    f = f or F_BODY
    for ln in wrap(text, f, width):
        d.text((x, y), ln, font=f, fill=fill)
        y += lh
    return y


def bullet(x, y, text, width):
    d.ellipse((x + 4, y + 14, x + 13, y + 23), fill=PURPLE)
    return para(x + 30, y, text, width - 30) + 7


def keyrow(x, y, key, text, width, keyw=190):
    # key cap
    kw = F_KEY.getlength(key) + 26
    d.rounded_rectangle((x, y + 2, x + kw, y + 35), radius=7, fill=(34, 34, 42, 255), outline=(150, 150, 168, 255), width=2)
    d.text((x + 13, y + 6), key, font=F_KEY, fill=WHITE)
    return max(para(x + keyw, y, text, width - keyw), y + LH) + 8


# ---- title: the splash logo ----
logo = Image.open(glob.glob('sprites/spr_logoTitle/*.png')[0]).convert('RGBA')
logo = logo.resize((int(logo.width * 0.80), int(logo.height * 0.80)), Image.LANCZOS)
img.alpha_composite(logo, (48, 40))
d = ImageDraw.Draw(img)
d.text((60, 196), 'Version 1.96   -   by Robert Ramsay', font=F_VER, fill=SOFT)
d.text((W - 60, 196), 'Click HELP INFO to close', font=F_VER, fill=SOFT, anchor='ra')

M = 60
GAP = 56
CW = (W - (2 * M) - GAP) // 2
X1, X2 = M, M + CW + GAP
TOP = 262

# ================= left column =================
y = TOP
y = heading(X1, y, 'GETTING STARTED', CW)
y = bullet(X1, y, 'Shape the hair with the sliders. The previewer on the left updates as you edit.', CW)
y = bullet(X1, y, 'Switch on the maps you want in the MAPS list, then press G to generate them at 4096 x 4096.', CW)
y = bullet(X1, y, 'Click a map name to view it. Press S to export every generated map with the project file.', CW)
y = bullet(X1, y, 'Hover over any button or slider: what it does is shown along the bottom bar.', CW)

y += 18
y = heading(X1, y, 'SETS', CW)
y = bullet(X1, y, 'The hair is built from 11 sets. Click a set in the preview, or its number at the bottom right, to select it.', CW)
y = bullet(X1, y, 'While a set is selected, sliders and colours change that set only. An overridden value turns yellow and a dot marks its row.', CW)
y = bullet(X1, y, 'Drag a selected set in the preview to move it. The arrow keys nudge it: hold Ctrl for fine steps, Shift for large ones.', CW)
y = bullet(X1, y, 'Click a selected set\'s number again to show it on its own. Right-click anywhere to deselect and show every set.', CW)
y = bullet(X1, y, 'COPY and PASTE carry one set\'s settings over to another.', CW)

y += 18
y = heading(X1, y, 'PREVIEW', CW)
y = bullet(X1, y, 'FAST, MED, SLOW and DYNA preview 20, 50, 100 or 30 strands per set. The final render draws up to 100 per set.', CW)
y = bullet(X1, y, 'LIVE UPDATE redraws as you drag, then grows the strands in. BUSY UPDATE waits until you let go.', CW)
y = bullet(X1, y, 'SMOOTH PREVIEW cleans up the stepped preview strands with a realtime shader. RAW PREVIEW shows them as drawn.', CW)

y += 18
y = heading(X1, y, 'CLUMPING', CW)
y = para(X1, y, 'Gathers the strands of each set into tresses.', CW, fill=SOFT) + 8
for k, t in (('AMOUNT', 'How tightly a tress pulls together. 0 is off.'),
             ('COUNT', 'How many tresses each set splits into.'),
             ('START', 'How far down the strand clumping begins.'),
             ('SCATTER', 'Loosens strands and frees a few strays.')):
    d.text((X1 + 30, y), k, font=F_KEY, fill=PURPLE)
    y = para(X1 + 190, y - 3, t, CW - 190) + 6
left_end = y

# ================= right column =================
y = TOP
y = heading(X2, y, 'KEYS', CW)
for k, t in (('G', 'Generate every enabled map'),
             ('S', 'Export all generated maps and the project'),
             ('L', 'Load a project file'),
             ('P', 'Back to the previewer'),
             ('R N M C I', 'View the RGB Mask, Normal, Mask, Color and ID maps'),
             ('D F A Z', 'View the Depth, Flow, AO and Frizz maps'),
             ('B', 'Hold to blur the map being viewed'),
             ('J', 'Hold to preview AO over the Color map'),
             ('U', 'Hold to show the loaded UV image'),
             ('ENTER', 'Apply a typed value'),
             ('ESC', 'Exit, or leave the mixer editor')):
    y = keyrow(X2, y, k, t, CW, keyw=250)

y += 14
y = heading(X2, y, 'FUNCTION KEYS', CW)
for k, t in (('F1', 'Type a seed. With a set selected, that set only'),
             ('F4', 'Reset the selected set\'s overrides'),
             ('F5', 'Reset every set\'s overrides'),
             ('F6', 'Soft reset: restarts Hair Strand Designer'),
             ('F8', 'Edit the mixer curves'),
             ('F9', 'Load an image to use as the colour palette')):
    y = keyrow(X2, y, k, t, CW, keyw=118)

y += 14
y = heading(X2, y, 'MOUSE', CW)
y = bullet(X2, y, 'Click any value box to type a number.', CW)
y = bullet(X2, y, 'Alt + right-click picks a colour from anywhere on screen for the selected tone.', CW)
y = bullet(X2, y, 'Right-click the UV image button to show the loaded image. Right-click the palette button to remove a loaded palette.', CW)

y += 18
y = heading(X2, y, 'FILES', CW)
y = bullet(X2, y, 'Your work is autosaved as you go. The start screen offers to load the last session.', CW)
y = bullet(X2, y, 'Save projects and textures to a folder outside the application folder.', CW)
right_end = y

print('size', img.size, 'left column ends', left_end, 'right column ends', right_end, 'limit', H - 50)
img.save(os.path.join(S, 'spr_HelpPanel_new.png'))
img.convert('RGB').resize((W // 2, H // 2), Image.LANCZOS).save(os.path.join(S, 'help_new_half.png'))
img.convert('RGB').crop((0, 0, 1200, 900)).save(os.path.join(S, 'help_new_crop.png'))
