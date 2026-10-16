#!/usr/bin/env python3
"""Apply an actual WorldX prompt-template override for one isolated building.
Preserves WorldX's native prompt-loader; does not produce/fabricate any image.
"""
import argparse
from pathlib import Path

MAIN_HOUSE = """请为《苍岚·人生世界》制作一张可裁剪的独立正房建筑游戏素材候选原图。

【同一画风，不准改变】统一采用上一批《苍岚》四合院获用户认可的国风精细手绘插画风格：青灰瓦片、深棕木梁、灰白墙体、温暖柔和自然光、低饱和配色；保留清雅古建筑意境，但消除建筑整体模糊与景深虚化。
【唯一主体】画面只能是一栋中国古代四合院正房，完整硬山式瓦顶、两侧山墙、门窗、梁柱、台基。禁止生成整个四合院、左右厢房、围墙、庭院、树木、地面道路、天空、人物、牌匾字样或杂物。
【构图】与此前国风四合院保持统一斜俯视35–45度，可见完整屋顶、正立面、可见侧墙、石台基。建筑居中，横向占图约75–85%，四周留白，不得裁掉瓦脊、檐角或台基。纯色均匀浅灰背景，无投射到背景上的大面积软阴影，不要棋盘格伪透明。
【清晰度硬要求】瓦片层次、屋脊、檐口、木梁、门框、窗棂、柱础必须边界锐利且手绘笔触协调。禁止局部涂抹模糊、错误重复瓦片、曲折断裂梁柱、错位透视、镜头虚化、锐化光晕、塑料质感。
【生成限制】高清2D绘画，不能变成3D建模截图；不能切换像素风或Q版；不得出现AI水印、文字或UI。这张图只是可裁剪素材候选，不要假装它已经是透明分层建筑或3D模型。

原始附加要求：{{userPrompt}}
额外约束：{{additionalConstraints}}
"""

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--worldx-root", required=True, type=Path)
    a=p.parse_args()
    root=a.worldx_root
    original=root/"generators/map/prompts/step1-map-generation.md"
    loader=root/"generators/map/src/utils/prompt-loader.mjs"
    if not original.is_file() or not loader.is_file():
        raise SystemExit("Not a WorldX checkout with the native map prompt loader")
    baseline=original.read_text(encoding="utf-8")
    if "90度" not in baseline and "90°" not in baseline:
        raise SystemExit("Unexpected WorldX upstream prompt, refuse risky override")
    backup=original.with_name("step1-map-generation.worldx-original.md")
    backup.write_text(baseline,encoding="utf-8")
    original.write_text(MAIN_HOUSE,encoding="utf-8")
    print("PASS_WORLDX_CANG LAN_SINGLE_MAIN_HOUSE_PROMPT".replace(" ", ""))

if __name__=="__main__":
    main()
