# 🦞 Lobster Platformer 开发日志

## v1.4 - Timer & Achievements (2026-03-13)

### 新增功能
- ✅ **计时挑战系统** - 每关显示通关时间
- ✅ **成就系统** - 8个可解锁成就：
  - First Coin: 收集第一枚金币
  - Coin Collector: 收集100枚金币
  - Star Gatherer: 收集10颗星星
  - Boss Slayer: 击败红龙
  - Perfect Fighter: 无伤击败Boss
  - Combo Master: 获得10x连击
  - Speed Runner: 30秒内通关
  - Perfect Level: 零死亡通关
- ✅ **总游戏时间追踪**
- ✅ **通关时间奖励** - 越快通关分数越高
- ✅ **成就解锁通知** - 获得成就时显示提示
- ✅ **开始画面改进** - 显示已解锁成就数量和高分

### Bug 修复
- ✅ 修复重新开始游戏的问题（支持游戏结束和胜利后按空格重新开始）
- ✅ Boss 战后正确显示胜利画面
- ✅ Boss 死亡后触发胜利画面

### Power-up 类型
- 无敌 (⭐) - 5秒无敌时间
- 速度提升 (⚡) - 移动速度 x1.5
- 二段跳 (🔺) - 获得永久二段跳能力
- 额外生命 (❤️) - 增加1条生命

### 构建信息
- Web Export: ✅ 成功 (2026-03-13)
- itch.io: ✅ 发布成功

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v1.3 - Bug Fixes & Improvements (2026-03-13)

### Bug 修复
- ✅ 修复重新开始游戏的问题（支持游戏结束和胜利后按空格重新开始）
- ✅ Boss 战后正确显示胜利画面
- ✅ Boss 死亡后触发胜利画面

### 新增功能
- ✅ **关卡名称显示** - 进入每个关卡时显示关卡名称
- ✅ **Boss 警告** - 进入 Boss 战前显示警告提示
- ✅ **Boss 奖励** - Boss 死亡后掉落随机 Power-up
- ✅ **改进开始画面** - 显示版本信息和功能列表
- ✅ **扩展音效系统** - 添加 Powerup、Enemy、Boss Warning、Checkpoint 音效

### Power-up 类型
- 无敌 (⭐) - 5秒无敌时间
- 速度提升 (⚡) - 移动速度 x1.5
- 二段跳 (🔺) - 获得永久二段跳能力
- 额外生命 (❤️) - 增加1条生命

### 构建信息
- Web Export: ✅ 成功 (2026-03-13)
- itch.io: ✅ 发布成功

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v1.2 - Boss Battle Update (2026-03-13)

### Bug 修复
- ✅ 修复移动平台的物理计算问题（使用正确的 velocity 计算）
- ✅ 修复敌人 velocity 未初始化问题
- ✅ 修复资源加载方式（改用 Godot 资源加载，兼容 Web 导出）

### 新增功能
- ✅ **Boss 战关卡** - "Dragon's Lair" 包含 Red Dragon Boss
- ✅ **Boss 敌人** - 5 HP，会发射火球、跳跃攻击、冲刺攻击
- ✅ **Boss HP 条** - 显示 Boss 剩余血量
- ✅ **胜利画面** - 通关后显示庆祝画面和最终得分
- ✅ **移动平台优化** - 改进移动平台物理，支持玩家站在上面

### 敌人类型
- 地面敌人 - 巡逻并随机跳跃
- 飞行敌人 - 在空中漂浮移动
- Boss 敌人 - Red Dragon (HP: 5)

### 关卡列表
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Bonus Stage
10. Sky Fortress
11. Dragon's Lair (Boss)

### 构建信息
- Web Export: ✅ 成功 (2026-03-13)
- itch.io: ✅ 发布成功

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v1.1 - Power-up system (2026-03-12)
- 添加 Powerup 系统：无敌、速度提升、二段跳、额外生命
- 修复敌人攻击玩家的问题

## v1.0 - Stars & Animation Update (2026-03-12)
- 星星收集系统
- 改进动画效果
- 移动平台、连击系统、飞行敌人
