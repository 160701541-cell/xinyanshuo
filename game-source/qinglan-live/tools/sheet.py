#!/usr/bin/env python3
"""把一组同尺寸 PNG 拼成带中文标签的接触表。
用法: sheet.py OUT.png COLS TILE_W TILE_H FONT_SIZE "标签1,标签2,..." IMG1 IMG2 ...
"""
import sys
from PIL import Image, ImageDraw, ImageFont

FONT_B = "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc"

def main():
    out, cols, tw, th, fs = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
    labels = sys.argv[6].split(",")
    imgs = sys.argv[7:]
    rows = (len(imgs) + cols - 1) // cols
    pad, cap = 8, fs + 14
    sheet = Image.new("RGB", (cols * tw + pad * 2, rows * (th + cap) + pad * 2), (12, 14, 18))
    d = ImageDraw.Draw(sheet)
    f = ImageFont.truetype(FONT_B, fs)
    for i, p in enumerate(imgs):
        im = Image.open(p).convert("RGB").resize((tw, th), Image.LANCZOS)
        r, c = divmod(i, cols)
        x = pad + c * tw
        y = pad + r * (th + cap)
        sheet.paste(im, (x, y))
        lab = labels[i] if i < len(labels) else ""
        tw_text = d.textlength(lab, font=f)
        d.text((x + (tw - tw_text) / 2, y + th + 3), lab, font=f, fill=(228, 222, 205))
    sheet.save(out)
    print("sheet", out, sheet.size)

if __name__ == "__main__":
    main()
