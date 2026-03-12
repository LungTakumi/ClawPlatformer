# 🦞 Lobster Platformer 开发日志

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
