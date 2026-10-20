#!/bin/bash
# 一条命令复现"头部特写四视图"（自我迭代协议 R3 固定机位）。
# 用法: run_head_shot.sh <宿主Godot工程目录> [godot二进制] [neck_params.json] [输出前缀]
# 本仓库只存放流水线源码；运行需要宿主 Godot 工程（本机为 /root/game）。
# 缺宿主或缺 Godot 二进制时按协议打印 BLOCKED，不得用文字描述冒充出图。
set -e
GAME="${1:?用法: run_head_shot.sh <宿主Godot工程目录> [godot二进制] [neck_params.json] [输出前缀]}"
GODOT="${2:-/root/godot/Godot_v4.4.1-stable_linux.arm64}"
PARAMS="${3:-$(dirname "$0")/../self_iteration/params/round01_after.json}"
PREFIX="${4:-round01_after}"
HERE="$(cd "$(dirname "$0")" && pwd)"
if [ ! -d "$GAME" ]; then echo "BLOCKED: 宿主工程不存在: $GAME"; exit 3; fi
if [ ! -x "$GODOT" ]; then echo "BLOCKED: Godot 二进制不存在: $GODOT"; exit 3; fi
cp "$HERE/src/cloth.gd" "$GAME/rig/cloth.gd"
cp "$HERE/src/cloth.tscn" "$GAME/rig/cloth.tscn"
for f in neck_params.json trim_params.json studio_params.json; do cp "$PARAMS" "$GAME/rig/$f"; done
echo "参数: $PARAMS"
python3 -c "import json,sys;print(json.dumps(json.load(open(sys.argv[1])),ensure_ascii=False))" "$PARAMS"
for y in 0 90 180 45; do
  DISPLAY="${DISPLAY:-:99}" timeout 300 "$GODOT" --path "$GAME" --rendering-driver opengl3 \
    --resolution 620x820 res://rig/cloth.tscn -- --yaw=$y --head 2>&1 | grep -E 'NECK_PARAMS lo|HEAD c=|SHOT' | tail -2
  cp "$GAME/out/cloth_head$y.png" "$HERE/../self_iteration/shots/${PREFIX}_$y.png"
done
ls -la "$HERE/../self_iteration/shots/${PREFIX}_"*.png
