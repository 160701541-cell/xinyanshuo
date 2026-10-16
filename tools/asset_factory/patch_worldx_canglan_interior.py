#!/usr/bin/env python3
"""Override WorldX's native step1 prompt with Canglan's first room interior.
Only the prompt is replaced; WorldX's loader remains unchanged.
"""
from pathlib import Path
import argparse

INTERIOR = """制作《苍岚·人生世界》高清国风游戏的一间【正房室内场景】。
【场景唯一性】画面中必须是室内房间，不要室外四合院，不要建筑外壳或院子、瓦顶外立面、围墙、远山、街道、室外树木。
【沿用已认可的风格】国风精细手绘插画，青灰瓦建筑的室内延续灰白粉墙、深棕木梁与门窗、柔和金色自然光、低饱和温润色彩，画风统一；禁止像素风、Q版、赛博风、写实3D光滑塑料。
【摄像机】固定斜俯视约35–45度、屋顶暂时隐藏的室内剖面场景；能同时看到木地板、房间后墙、两侧墙体。透视和外景画风一致，全部室内区域可看清，禁止景深虚化、浓雾、过度锐化。
【真实生活环境】一间普通中国古代正房的室内，木地板和门槛清晰，靠墙一张简洁木床，一张木桌、两张凳子、一件木柜，窗上有柔和日照，靠近画面下边中央留出玩家从门口进入的空位。家具大小与房间比例真实；每件家具仅出现一次。
【作为可玩的布景】空间结构清楚，中心留可行走通道，门应能辨认；完整房间填满画面约85%，没有文字、标牌、人物、界面、水印、AI字样。输出1:1高清单张房间候选原画。后续门和家具需独立交互分层，此图本身不能冒充已分层的资产。

{{userPrompt}}
{{additionalConstraints}}
"""

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--worldx-root",required=True,type=Path)
    args=parser.parse_args()
    root=args.worldx_root
    loader=root/"generators/map/src/utils/prompt-loader.mjs"
    target=root/"generators/map/prompts/step1-map-generation.md"
    if not loader.is_file() or not target.is_file():
        raise SystemExit("Invalid WorldX checkout: no native prompt-loader or map template")
    previous=target.read_text(encoding="utf-8")
    if "90度" not in previous and "90°" not in previous:
        raise SystemExit("Unexpected upstream template: refusing unreviewed patch")
    target.with_name("step1-map-generation.worldx-original.md").write_text(previous,encoding="utf-8")
    target.write_text(INTERIOR,encoding="utf-8")
    print("PASS_WORLDX_CANG LAN_INTERIOR_PROMPT_LOADED".replace(" ",""))

if __name__=="__main__":
    main()
