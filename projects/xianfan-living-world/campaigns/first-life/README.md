# 《仙凡·苍岚》第一世公开存档

本文件夹只属于ChatGPT中的独立文字战役；不覆盖《仙凡》安卓版、苍岚Godot工程或WorldBox模组的数据。

## 权威来源与同步状态

- `campaign_index.json`：当前可公开的局面、人名、财产和历史事件哈希。
- 原始事件末尾编号 `EV000002`，目前玩家有效行动回合数 **0**。
- 完整原始状态以四份JSON拆分上传，合并后的SHA256与原存档一致；events.jsonl含原始两条事件，角色记忆保存在story_memory_public.json。
- 单独的campaign_index.json不能替代权威状态，需运行node ../../tools/restore_campaign.mjs verify . 将四份状态无损合并为game_state.json并校验events.jsonl。
- 后续每轮行动应落盘至经校验的正式事件链并同步公开仓库；不能提交时必须提示用户“尚未同步”。

## 主持协议

见 `../../docs/GM_GAME_PROTOCOL.md`。玩家不是被偏爱或被特别针对的主角，而是世界中的普通人物，和其他NPC承受相同规则。

## GM的逐轮自检与每10轮复盘

- 操作流程见 `../../docs/GM_CONTINUOUS_IMPROVEMENT_V1.md`。
- 本地运行 `node ../../tools/restore_campaign.mjs checkpoint .` 时同时生成 `checkpoints/turn_NNNN.json` 和 `gm_reviews/review_NNNN.json`（仅第10、20、30……轮）。
- GM评审应保留未核查项的 `NOT_CHECKED`，而不是虚报没有漏洞；生成文件仍需要实际提交GitHub才算仓库已保存。

## 每10轮压缩

第10、20、30……个完成结算的行动回合生成一个带事件起止编号及哈希的摘要，归纳NPC、经济变化、剧情事实、未决线索、主角位置；不抹去原始事件。查询资料、讨论规则、未实际执行的命令均不算回合。游戏没有聊天之外的自动计算能力。

## 公开信息边界

此目录所有内容任何人都能阅读。不得放未揭晓根性明文、未发现剧情秘密、真实个人身份或私钥。游戏公开记录可展示的是玩家已知和可验证的内容。
