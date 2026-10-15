# 苍岚高清素材工业流水线 / Asset Factory

**2026-10-15 用户确认方案**：允许以风格一致的国风拼版为批量输入进行分格裁切；流程目标是大规模、可复现、可审核、可追溯的独立场景候选素材 + 对应图标。裁切候选不等于透明高清成品，不允许把拼图直接裁切结果宣称为通过质量门禁的游戏素材。

## 已上传的真正可执行源码

- `atlas_factory.py`：v5拼版20格裁切、512px图标候选、输入SHA256与候选清单，所有结果默认 `UNAPPROVED`，不会导入正式游戏。
- `atlas_layout.json`：对应示例海报的20格坐标，可按具体拼版模板调整。
- `make_jobs.py`：生成20种道具的多状态生图任务与初版制造关系草案。
- `industrial_pipeline.py`：连接已经运行的ComfyUI本地API；可选外部超分命令；无AI超分时标注LANCZOS_NOT_AI。生成结果仍需审核。
- 同目录早先提交的 `comfy_batch.py` / `approve_and_export.py` / `test_factory.py` 仅为占位索引，并非完整可执行源码；**不可视为已完成GitHub同步**。完整历史原型见聊天交付包 v1.2。后续要替换占位实现。

## 安装与运行

Python 3.10+，安装 Pillow：`python -m pip install Pillow`。

```sh
# 从拼版裁出20个未审核候选场景图、20个配套图标（必须提供原始拼版PNG）
python tools/asset_factory/atlas_factory.py --image YOUR_ATLAS.png --layout tools/asset_factory/atlas_layout.json --out ./candidate_output

# 对纯黑边缘可选尝试简单扣底（不能保证精确透明）
python tools/asset_factory/atlas_factory.py --image YOUR_ATLAS.png --layout tools/asset_factory/atlas_layout.json --out ./candidate_output --dark-cutout

# 生成20种物品、多状态AI生图任务，写到同目录
python tools/asset_factory/make_jobs.py
python tools/asset_factory/industrial_pipeline.py --dry-run
```

真实ComfyUI调用另需已启动的图像服务器及用户提供的API格式工作流：
```sh
python tools/asset_factory/industrial_pipeline.py --workflow YOUR_COMFY_API_WORKFLOW.json --url http://127.0.0.1:8188
```

脚本不自带AI模型、GPU、透明抠图精修器，不自动批准候选。必须人工复核拼版裁切是否有邻格、文字、黑底、透视不一、细节不足、边缘残留；符合要求后再单独完善审批/导出流程及Godot验证。

## 实际验证
会话环境执行 `atlas_factory.py` 输入已有拼版和本模板，返回 `Created 20 candidate sprites and icons; 0 approved`。**已通过命令行候选输出冒烟测试，未验证Godot，也未更新手机。**

## 推荐状态机
`GENERATED -> CROPPED_CANDIDATE -> BACKGROUND_CLEANUP -> TECH_QA -> VISUAL_REVIEW -> APPROVED_HASH_LOCKED -> GODOT_IMPORTED -> ENGINE_TESTED -> MOBILE_RELEASED`。

同名文件或缩略图不能证明已完成生产上线；每一阶段记录源输入、脚本版本、处理参数、输出哈希和复核人。
