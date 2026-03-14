# 🦞 Lobster Platformer 开发日志

## v4.0 - Volume Control System (2026-03-14)

### 新增功能
- ✅ **音量控制系统** - audio_manager.gd 添加完整的音量控制
  - Master 主音量控制
  - SFX 音效音量控制  
  - 设置自动保存到本地 (user://volume.dat)
  - 使用分贝 (dB) 转换实现平滑音量调节
  - 暂停菜单中添加音量滑块（需要手动更新 main.gd，详见 VOLUME_PATCH.md）

### 手动更新
- main.gd 需要应用 VOLUME_PATCH.md 中的补丁来显示音量滑块

### 构建信息
- Web Export: ✅ 已构建
- itch.io: ⚠️ 需要手动推送 (butler 认证问题)
- GitHub: ✅ 已推送

---

## v3.9 - Virtual Controls Fix (2026-03-14)

### Bug 修复
- ✅ **虚拟按钮左右键问题修复**
  - 添加按钮状态跟踪，防止重复触发
  - 添加触摸事件 (InputEventScreenTouch) 支持
  - 添加鼠标点击事件支持
  - 使用 gui_input 捕获更广泛的输入事件
  - 确保 Web 平台虚拟按钮正常工作

### 构建信息
- Web Export: ✅ 已构建
- itch.io: ✅ 已发布 (https://lungtakumi.itch.io/clawplatformer)
- GitHub: ✅ 已推送

---

## v3.8 - Level Select (2026-03-14)

### 新增功能
- ✅ **选关页面 (Level Select Screen)** - 玩家可以在开始游戏后选择关卡
  - 网格布局展示所有29个关卡
  - 显示关卡编号、名称和解锁状态
  - 已解锁关卡显示 ✅，未解锁显示 🔒
  - 点击已解锁关卡即可开始游戏
  - 支持返回主菜单

### 优化
- 开始界面新增"Level Select"按钮
- 选关页面支持滚动查看所有关卡

---

## v3.7 - Void Dimension (2026-03-14)

### 新增功能
- ✅ **Void Dimension 关卡** - 第29关，黑暗虚空主题
  - 深黑/紫色虚空主题背景
  - 15个平台，多条上升路线
  - 包含3颗星星和14枚金币
  - 包含二段跳能力道具 (Double Jump)
  - 混合敌人：水母、史莱姆、飞行敌人、电鳗
- ✅ **虚空粒子效果** - Void Dimension 专属背景
  - 黑暗虚空漩涡
  - 漂浮的虚空粒子
  - 暗能量飘带动画
- ✅ 版本号更新为 v3.7

### 关卡列表 (v3.7)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️
15. Volcano 🔥
16. Haunted Forest 👻
17. Desert 🏜️
18. Underwater Temple 🌊
19. Space Station 🚀
20. Neon City 🌃
21. Matrix Core 🟢
22. Cloud Kingdom ☁️
23. Ancient Temple 🏛️
24. Enchanted Forest 🌲
25. Cyberpunk City 🌃
26. Digital Realm 💻
27. Crystal Palace ❄️
28. Nebula Nexus 🌌
29. Void Dimension 🌑 新增

### 敌人类型 (v3.7)
- 🟣 Ground Enemy - 地面敌人
- 🦇 Flying Enemy - 飞行敌人
- 💧 Jellyfish - 水母敌人
- 🟢 Slime - 史莱姆
- ⚡ Electric Eel - 电鳗
- 🐉 Boss - Boss敌人

### 构建信息
- Web Export: ✅ 已构建
- itch.io: ✅ 已发布 (https://lungtakumi.itch.io/clawplatformer)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v3.6 - Nebula Nexus (2026-03-14)

### 新增功能
- ✅ **Nebula Nexus 关卡** - 第28关，星云宇宙主题
  - 深紫/粉红星云主题背景
  - 15个平台，多条上升路线
  - 包含3颗星星和15枚金币
  - 包含冲刺能力道具 (Dash)
  - 混合敌人：水母、史莱姆、飞行敌人、电鳗
- ✅ **星云粒子效果** - Nebula Nexus 专属背景
  - 彩色星云云团
  - 漂浮的宇宙尘埃粒子
  - 缓慢旋转动画
- ✅ 版本号更新为 v3.6

### 关卡列表 (v3.6)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️
15. Volcano 🔥
16. Haunted Forest 👻
17. Desert 🏜️
18. Underwater Temple 🌊
19. Space Station 🚀
20. Neon City 🌃
21. Matrix Core 🟢
22. Cloud Kingdom ☁️
23. Ancient Temple 🏛️
24. Enchanted Forest 🌲
25. Cyberpunk City 🌃
26. Digital Realm 💻
27. Crystal Palace ❄️
28. Nebula Nexus 🌌 新增

### 敌人类型 (v3.6)
- 🟣 Ground Enemy - 地面敌人
- 🦇 Flying Enemy - 飞行敌人
- 💧 Jellyfish - 水母敌人
- 🟢 Slime - 史莱姆
- ⚡ Electric Eel - 电鳗
- 🐉 Boss - Boss敌人

### 构建信息
- Web Export: ✅ 已构建
- itch.io: ✅ 已发布 (https://lungtakumi.itch.io/clawplatformer)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v3.5 - Crystal Palace (2026-03-14)

### 新增功能
- ✅ **Crystal Palace 关卡** - 第27关，水晶宫殿主题
  - 浅蓝色冰晶主题背景
  - 15个平台，多条上升路线
  - 包含3颗星星和14枚金币
  - 包含二段跳能力道具 (Double Jump)
  - 混合敌人：水母、史莱姆、飞行敌人、电鳗
- ✅ **冰晶平台** - 新平台类型
  - 青色/蓝色/紫色/白色水晶渐变效果
  - 冰晶边缘光效
- ✅ **冰晶粒子效果** - Crystal Palace 专属背景
  - 飘落的冰晶粒子
  - 缓慢漂浮动画
- ✅ 版本号更新为 v3.5

### 关卡列表 (v3.5)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️
15. Volcano 🔥
16. Haunted Forest 👻
17. Desert 🏜️
18. Underwater Temple 🌊
19. Space Station 🚀
20. Neon City 🌃
21. Matrix Core 🟢
22. Cloud Kingdom ☁️
23. Ancient Temple 🏛️
24. Enchanted Forest 🌲
25. Cyberpunk City 🌃
26. Digital Realm 💻
27. Crystal Palace ❄️ 水晶宫 新增

### 敌人类型 (v3.5)
- 🟣 Ground Enemy - 地面敌人
- 🦇 Flying Enemy - 飞行敌人
- 💧 Jellyfish - 水母敌人
- 🟢 Slime - 史莱姆
- ⚡ Electric Eel - 电鳗
- 🐉 Boss - Boss敌人

### 构建信息
- Web Export: ✅ 已构建
- itch.io: ✅ 已发布 (https://lungtakumi.itch.io/clawplatformer)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v3.4 - Digital Realm (2026-03-14)

### 新增功能
- ✅ **Digital Realm 关卡** - 第26关，矩阵/二进制主题
  - 深黑绿色矩阵风格背景
  - 15个平台，多条上升路线
  - 包含3颗星星和15枚金币
  - 包含冲刺能力道具 (Dash)
  - 混合敌人：电鳗、史莱姆、飞行敌人、水母
- ✅ 版本号更新为 v3.4

### 关卡列表 (v3.4)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️
15. Volcano 🔥
16. Haunted Forest 👻
17. Desert 🏜️
18. Underwater Temple 🌊
19. Space Station 🚀
20. Neon City 🌃
21. Matrix Core 🟢
22. Cloud Kingdom ☁️
23. Ancient Temple 🏛️
24. Enchanted Forest 🌲
25. Cyberpunk City 🌃
26. Digital Realm 💻 新增

### 敌人类型 (v3.4)
- 🟣 Ground Enemy - 地面敌人
- 🦇 Flying Enemy - 飞行敌人
- 💧 Jellyfish - 水母敌人
- 🟢 Slime - 史莱姆
- ⚡ Electric Eel - 电鳗
- 🐉 Boss - Boss敌人

### 构建信息
- Web Export: ✅ 已构建
- itch.io: ✅ 已发布 (https://lungtakumi.itch.io/clawplatformer)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v3.3 - Cyberpunk City (2026-03-14)

### 新增功能
- ✅ **Cyberpunk City 关卡** - 第25关，赛博朋克城市主题
  - 深蓝紫色霓虹主题背景
  - 15个平台，多条上升路线
  - 包含3颗星星和15枚金币
  - 包含二段跳能力道具 (Double Jump)
  - 混合敌人：电鳗(新!)、飞行敌人、水母
- ✅ **Electric Eel (电鳗) 敌人** - 新敌人类型
  - 快速水平移动
  - 转向时释放电流特效
  - 死亡时更大的电火花爆炸
  - 击败获得35分(更高奖励!)
- ✅ 版本号更新为 v3.3

### 关卡列表 (v3.3)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️
15. Volcano 🔥
16. Haunted Forest 👻
17. Desert 🏜️
18. Underwater Temple 🌊
19. Space Station 🚀
20. Neon City 🌃
21. Matrix Core 🟢
22. Cloud Kingdom ☁️
23. Ancient Temple 🏛️
24. Enchanted Forest 🌲
25. Cyberpunk City 🌃 新增

### 敌人类型 (v3.3)
- 🟣 Ground Enemy - 地面敌人
- 🦇 Flying Enemy - 飞行敌人
- 💧 Jellyfish - 水母敌人
- 🟢 Slime - 史莱姆
- ⚡ **Electric Eel - 电鳗** 新增!
- 🐉 Boss - Boss敌人

### 构建信息
- Web Export: ✅ 已构建
- itch.io: ✅ 已发布 (https://lungtakumi.itch.io/clawplatformer)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v3.2 - Enchanted Forest (2026-03-14)

### 新增功能
- ✅ **Enchanted Forest 关卡** - 第24关，魔法森林主题关卡
  - 深绿色神秘森林主题背景
  - 16个平台，多条路线
  - 包含3颗星星和16枚金币
  - 包含冲刺能力道具 (Dash)
  - 混合敌人：史莱姆、飞行敌人、水母
- ✅ 版本号更新为 v3.2

### 关卡列表 (v3.2)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️
15. Volcano 🔥
16. Haunted Forest 👻
17. Desert 🏜️
18. Underwater Temple 🌊
19. Space Station 🚀
20. Neon City 🌃
21. Matrix Core 🟢
22. Cloud Kingdom ☁️
23. Ancient Temple 🏛️
24. Enchanted Forest 🌲 新增

### 构建信息
- Web Export: ✅ 已构建
- itch.io: ✅ 已发布 (https://lungtakumi.itch.io/clawplatformer)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v3.1 - Ancient Temple (2026-03-14)

### 新增功能
- ✅ **Ancient Temple 关卡** - 第23关，古老神庙/遗迹主题关卡
  - 深紫色神秘古遗迹主题背景
  - 12个平台，多条路线
  - 包含3颗星星和12枚金币
  - 包含二段跳能力道具
  - 混合敌人：史莱姆、飞行敌人、水母
- ✅ 版本号更新为 v3.1

### 关卡列表 (v3.1)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️
15. Volcano 🔥
16. Haunted Forest 👻
17. Desert 🏜️
18. Underwater Temple 🌊
19. Space Station 🚀
20. Neon City 🌃
21. Matrix Core 🟢
22. Cloud Kingdom ☁️
23. Ancient Temple 🏛️ 新增

### 构建信息
- Web Export: ✅ 成功 (2026-03-14)
- itch.io: ✅ 发布成功 (html channel)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v3.0 - Cloud Kingdom (2026-03-14)

### 新增功能
- ✅ **Cloud Kingdom 关卡** - 第22关，梦幻云朵主题关卡
  - 浅蓝色/白色梦幻云朵主题背景
  - 13个平台，多条路线
  - 包含3颗星星和13枚金币
  - 包含二段跳能力道具
  - 混合敌人：史莱姆、飞行敌人、水母
- ✅ 版本号更新为 v3.0

### 关卡列表 (v3.0)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️
15. Volcano 🔥
16. Haunted Forest 👻
17. Desert 🏜️
18. Underwater Temple 🌊
19. Space Station 🚀
20. Neon City 🌃
21. Matrix Core 🟢
22. Cloud Kingdom ☁️ 新增

### 构建信息
- Web Export: ✅ 成功 (2026-03-14)
- itch.io: ✅ 发布成功 (html channel)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v2.9 - Matrix Core (2026-03-14)

### 新增功能
- ✅ **Matrix Core 关卡** - 第21关，黑客帝国/科技主题关卡
  - 黑色/绿色黑客帝国主题背景
  - 12个平台，多条路线
  - 包含3颗星星和12枚金币
  - 包含二段跳能力道具
  - 混合敌人：史莱姆、飞行敌人、水母
- ✅ 版本号更新为 v2.9

### 关卡列表 (v2.9)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️
15. Volcano 🔥
16. Haunted Forest 👻
17. Desert 🏜️
18. Underwater Temple 🌊
19. Space Station 🚀
20. Neon City 🌃
21. Matrix Core 🟢 新增

### 构建信息
- Web Export: ✅ 成功 (2026-03-14)
- itch.io: ✅ 发布成功 (html channel)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v2.8 - Neon City (2026-03-14)

### 新增功能
- ✅ **霓虹城市关卡 (Neon City)** - 第20关，赛博朋克霓虹主题关卡
  - 深紫色/深蓝色赛博朋克主题背景
  - 13个平台，多条路线
  - 包含3颗星星和13枚金币
  - **地面重击能力 (Ground Slam)** - 在关卡中获得此能力
  - 包含史莱姆敌人和飞行敌人混合
- ✅ 版本号更新为 v2.8

### 关卡列表 (v2.8)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️
15. Volcano 🔥
16. Haunted Forest 👻
17. Desert 🏜️
18. Underwater Temple 🌊
19. Space Station 🚀
20. Neon City 🌃 新增

### 构建信息
- Web Export: ✅ 成功 (2026-03-14)
- itch.io: ✅ 发布成功 (html channel)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v2.7 - Space Station (2026-03-14)

### 新增功能
- ✅ **太空站关卡 (Space Station)** - 第19关，科幻太空主题关卡
  - 深紫色太空主题背景
  - 12个平台，多条路线
  - 包含3颗星星和12枚金币
  - **Dash 能力道具** - 在关卡中获得冲刺能力
  - 包含飞行敌人
- ✅ **史莱姆敌人 (Slime)** - 新敌人类型
  - 绿色的弹跳敌人
  - 会在平台上随机跳跃
  - 有挤压拉伸动画效果
- ✅ 版本号更新为 v2.7

### 关卡列表 (v2.7)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️
15. Volcano 🔥
16. Haunted Forest 👻
17. Desert 🏜️
18. Underwater Temple 🌊
19. Space Station 🚀 新增

### 构建信息
- Web Export: ✅ 成功 (2026-03-14)
- itch.io: ✅ 发布成功 (html channel)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v2.6 - Underwater Temple (2026-03-14)

### 新增功能
- ✅ **水下神庙关卡** - 第18关，水下/海洋主题关卡
  - 深蓝色水下主题背景
  - 11个平台，多条路线
  - 包含3颗星星和11枚金币
  - **水母敌人** - 新敌人类型，在空中漂浮移动
  - 包含二段跳能力道具
- ✅ **水母敌人 (Jellyfish)** - 新敌人类型
  - 优雅的漂浮和弹跳动作
  - 半透明粉红色外观
  - 在关卡中作为空中敌人
- ✅ 版本号更新为 v2.6

### 关卡列表 (v2.6)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️
15. Volcano 🔥
16. Haunted Forest 👻
17. Desert 🏜️
18. Underwater Temple 🌊 新增

### 构建信息
- Web Export: ✅ 成功 (2026-03-14)
- itch.io: ✅ 发布成功 (html channel)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v2.5 - Abilities & Powerups (2026-03-13)

### Metroidvania 元素 (C)
- ✅ **存档系统** - 保存进度、金币、星星、解锁关卡
- ✅ **能力系统框架** - 添加能力解锁框架（double_jump, dash, wall_climb, ground_slam）
- ✅ **能力通知** - 解锁能力时显示通知
- ✅ **进度显示** - 首页显示总金币、星星、解锁关卡数
- ✅ **自动解锁关卡** - 通关后自动解锁下一关

### 新增能力 & Powerups
- ✅ **冲刺能力 (Dash)** - 按 Shift 键冲刺，有冷却时间
- ✅ **墙壁攀爬 (Wall Climb)** - 贴着墙可以缓慢下落，再次跳跃可以蹬墙跳
- ✅ **Powerup 道具** - 在关卡中生成能力道具
- ✅ **Bonus Stage** - 添加 Dash 和 Double Jump 道具
- ✅ **Haunted Forest** - 添加 Wall Climb 道具

### 美观优化 (B)
- ✅ **UI 样式改进** - 使用 HBoxContainer + 图标，改进分数/生命/关卡显示
- ✅ **粒子效果增强** - 收集物品时显示圆形粒子 + 闪烁星星效果
- ✅ **背景星空改进** - 添加多层星空（远/中/近），不同速度和透明度
- ✅ **关卡名称动画** - 添加弹跳入场动画 + 背景板
- ✅ **Boss 警告动画** - 屏幕红光闪烁 + 文字缩放效果

### 版本号
- 版本号更新为 v2.4

---

## v2.2 - Desert (2026-03-13)

### 新增功能
- ✅ **Desert 关卡** - 新增第18关，沙漠主题关卡
  - 金黄色沙漠主题背景
  - 11个平台，多条路线
  - 包含3颗星星和11枚金币
  - 4个敌人分布在不同平台
- ✅ 版本号更新为 v2.2

### 关卡列表 (v2.2)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️
15. Volcano 🔥
16. Haunted Forest 👻
17. Desert 🏜️ 新增

### Power-up 类型
- 无敌 (⭐) - 5秒无敌时间
- 速度提升 (⚡) - 移动速度 x1.5
- 二段跳 (🔺) - 获得永久二段跳能力
- 额外生命 (❤️) - 增加1条生命

### 构建信息
- Web Export: ✅ 成功 (2026-03-13)
- itch.io: ✅ 发布成功 (html channel)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v2.1 - Haunted Forest (2026-03-13)

### 新增功能
- ✅ **Haunted Forest 关卡** - 新增第17关，万圣节/森林主题关卡
  - 深紫色万圣节主题背景
  - 11个平台，多条路线
  - 包含3颗星星和11枚金币
  - 4个敌人分布在不同平台
- ✅ 版本号更新为 v2.1

### 关卡列表 (v2.1)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️
15. Volcano 🔥
16. Haunted Forest 👻 新增

### Power-up 类型
- 无敌 (⭐) - 5秒无敌时间
- 速度提升 (⚡) - 移动速度 x1.5
- 二段跳 (🔺) - 获得永久二段跳能力
- 额外生命 (❤️) - 增加1条生命

### 构建信息
- Web Export: ✅ 成功 (2026-03-13)
- itch.io: ✅ 发布成功 (html channel)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v2.0 - Volcano & More (2026-03-13)

### Bug 修复
- ✅ 修复移动平台物理计算 - 改进平台移动的平滑度和玩家跟随
- ✅ 修复玩家在移动平台上滑落的问题

### 新增功能
- ✅ **Volcano 关卡** - 新增第16关，熔岩/火焰主题关卡
  - 红色/橙色熔岩主题背景
  - 11个平台，多条路线
  - 包含3颗星星和11枚金币
  - 4个敌人分布在不同平台
- ✅ 版本号更新为 v2.0
- ✅ 改进开始画面显示

### 关卡列表 (v2.0)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️
15. Volcano 🔥 新增

### Power-up 类型
- 无敌 (⭐) - 5秒无敌时间
- 速度提升 (⚡) - 移动速度 x1.5
- 二段跳 (🔺) - 获得永久二段跳能力
- 额外生命 (❤️) - 增加1条生命

### 构建信息
- Web Export: ✅ 成功 (2026-03-13)
- itch.io: ✅ 发布成功 (html channel)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v1.9 - Ice Palace & Improvements (2026-03-13)

### Bug 修复
- ✅ 修复 Boss HP条位置跟随问题 - 现在正确跟随玩家视角
- ✅ 修复移动平台物理计算 - 改进平台移动的平滑度
- ✅ 修复玩家死亡重生位置 - 现在会重生在检查点位置

### 新增功能
- ✅ **Ice Palace 关卡** - 新增第15关，冰雪主题关卡
  - 蓝色/白色冰雪主题背景
  - 11个平台，多条路线
  - 包含3颗星星和11枚金币
- ✅ 版本号更新为 v1.9

### 关卡列表 (v1.9)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨
14. Ice Palace ❄️ 新增

### Power-up 类型
- 无敌 (⭐) - 5秒无敌时间
- 速度提升 (⚡) - 移动速度 x1.5
- 二段跳 (🔺) - 获得永久二段跳能力
- 额外生命 (❤️) - 增加1条生命

### 构建信息
- Web Export: ✅ 成功 (2026-03-13)
- itch.io: ✅ 发布成功 (html channel)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v1.8 - Bug Fixes (2026-03-13)

### Bug 修复
- ✅ 修复 Boss HP条位置跟随问题 - 现在正确跟随玩家视角

### 构建信息
- Web Export: ✅ 成功 (2026-03-13)
- itch.io: ✅ 发布成功 (html channel)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v1.7 - Pause Menu & Secret Level (2026-03-13)

### Bug 修复
- ✅ 修复 First Coin 成就无法解锁的问题

### 新增功能
- ✅ **暂停菜单** - 按 ESC 或 P 键暂停游戏
  - 继续游戏 (Resume)
  - 重新开始关卡 (Restart Level)
  - 返回主菜单 (Quit to Menu)
- ✅ **秘密关卡 Secret Garden** - 第14个关卡
  - 绿色主题的隐藏关卡
  - 包含3颗星星和15枚金币
  - 敌人分布在不同平台
- ✅ 更新版本号为 v1.7
- ✅ 更新功能列表

### 关卡列表 (v1.7)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)
13. Secret Garden ✨ 新增

### Power-up 类型
- 无敌 (⭐) - 5秒无敌时间
- 速度提升 (⚡) - 移动速度 x1.5
- 二段跳 (🔺) - 获得永久二段跳能力
- 额外生命 (❤️) - 增加1条生命

### 构建信息
- Web Export: ✅ 成功 (2026-03-13)
- itch.io: ✅ 发布成功 (html channel)

### 游戏链接
- https://lungtakumi.itch.io/clawplatformer

---

## v1.6 - Level Improvements (2026-03-13)

### Bug 修复
- ✅ 修复关卡重复问题 - "The Tower" 不再重复出现
- ✅ 新增关卡 "Crystal Caverns" 替代重复关卡
- ✅ Bonus Stage 新增星星收集

### 新增功能
- ✅ **Crystal Caverns 关卡** - 新增第9关，包含水晶洞主题
- ✅ **关卡更新** - 现在有13个精心设计的关卡

### 关卡列表 (更新)
1. Green Hills
2. Sky Bridges
3. Moving Platforms
4. Mountain Climb
5. Floating Islands
6. The Tower
7. Cave
8. Rainbow Bridge
9. Crystal Caverns ✨ 新增
10. Bonus Stage
11. Sky Fortress
12. Dragon's Lair (Boss)

### Power-up 类型

### 新增功能
- ✅ **粒子效果系统** - 添加跳跃、落地、收集道具时的粒子效果
- ✅ **屏幕震动增强** - Boss 击败、连击等事件触发更强的屏幕震动
- ✅ **改进 Boss 战** - Boss 攻击模式更加多样化
- ✅ **关卡难度平衡** - 调整部分关卡难度，使游戏更加流畅

### Bug 修复
- ✅ 修复玩家死亡后重生位置的 Bug
- ✅ 修复移动平台物理计算
- ✅ 修复敌人碰撞检测问题
- ✅ 优化游戏性能，减少卡顿

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
