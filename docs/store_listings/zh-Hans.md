# Velour — où coller ces textes (guide en français)

Les titres ## sont en chinois (comme sur ta fiche store) ; les lignes *italiques* expliquent où coller dans les consoles, toujours en français.

Les textes à publier sont en texte plat (sans `**` Markdown) pour un copier-coller direct vers Apple et Google.

Locale pour ce fichier : App Store Connect → Chinois (simplifié) (*Chinese (Simplified)*) · Play Console → chinois (Chine simplifiée) ou chinois (simplifié) selon le libellé exact.

### App Store Connect

1. [App Store Connect](https://appstoreconnect.apple.com) → Mes apps → Velour → App Store → version iOS → localisation Chinois (simplifié).
2. Même emplacement que pour le français : si l’interface Apple est en anglais, repère Name, Subtitle, Keywords, Promotional Text, Description, What’s New in This Version — ce sont les champs où vont les blocs 名称, 副标题, etc. ci‑dessous.
3. Promotional Text : parfois modifiable sans nouvelle build.
4. Nouveautés de cette version (*What’s New in This Version*) : obligatoire par langue — voir section dédiée plus bas (adapter à chaque release ; réf. dépôt : 1.1.0+17).

### Google Play Console

1. [Play Console](https://play.google.com/console) → Velour → Présence sur le Play Store → Fiches principales du store → langue chinois (simplifié) → Titre, Courte description, Description complète.
2. Lors d’un déploiement de version (AAB) : étape Release notes / 版本说明 par langue — voir section en fin de fichier.

---

# App Store Connect（简体中文 — zh-Hans）

## 名称（30 字以内）

*Champ Apple Name / 名称 — nom public sur l’App Store (30 caractères max ; compte différemment pour le chinois, respecter la limite affichée dans la console).*

Velour: Luxury Sort & Stack

## 副标题（30 字以内）

*Champ Subtitle / 副标题.*

霓虹解谜·全球争榜

## 关键词（100 字以内，英文逗号分隔、逗号后无空格）

*Champ Keywords / 关键词 — une seule ligne, virgules anglaises sans espace après.*

puzzle,strategy,neon,arcade,gems,LUX,leaderboard,perfect,skill,logic,challenge,triple

## 推广文本（170 字以内，选填）

*Champ Promotional Text / 推广文本.*

一局一摊牌：秒读盘面，连消形状与颜色，倒计时里追 Perfect、叠 Heat。暗色霓虹 + 全球实时榜——压力越大，排名越香。

## 描述（4000 字以内）

*Champ Description / 描述.*

你看见盘面，时间不会讨价还价。 Velour 是一款偏硬核的霓虹解谜：每一局 run 都是逻辑与胆量的考试——形状消除、颜色消除，以及一发入魂的 Perfect（三颗完全相同）——分数飙升、Heat 叠起，换来更高 LUX 与关键时刻的补时。适合喜欢高压下仍要算清楚的人。

让人停不下来的理由
• 先谈挑战：节奏清晰但要动脑——别为了“轻松三连”放弃一步之遥的 Perfect。  
• 好看更要能打：暗色磨砂 + 霓虹宝石，信息一眼可读，并尊重系统的减弱动态效果。  
• 用排名说话：冲击全球排行榜的最佳成绩；在提示时设置你的 Oracle 名号。

按胆量选模式
• 经典：低筹码练习，把套路练熟。  
• 高额 / 皇家：赌注、目标与回报一起抬升——要么打得漂亮，要么干脆收手。

成长
商店里用 LUX 换皮肤与局内强化（保险、时间急救、慈悲重整等，规则以应用内为准）。主界面可领每日 LUX（以服务器规则为准）。

信任
商店版本可能包含分析与崩溃报告，详见页面链接的隐私政策。

现在就下：要硬核逻辑、可读霓虹、和「再来一局」的手感——装完用分数说话。

## 本版本更新 — App Store（各语言必填）

*与「名称」「描述」同一版本本地化页面：此版本的新增内容（界面英文常为 What's New in This Version）。每种语言都要填写。可按每次发版修改（仓库参考：1.1.0+17）。*

• 应用内语言：简体中文、印地语（可在系统或应用语言中选择）。
• 优化应用图标与 Android / iOS 启动屏，主屏幕更清晰。
• 匹配 / Perfect 音效更柔和；问题修复、稳定性与小优化。

---

# Google Play Console（简体中文）

*Play → Fiches principales du store → langue chinois (simplifié) (voir *Locale pour ce fichier* en haut).*

## 标题（30 字以内）

*Champ Title / 标题.*

Velour: Luxury Sort & Stack

## 简短说明（80 字以内）

*Champ Short description / 简短说明.*

高压霓虹解谜：Perfect、LUX筹码、全球榜——难到想再来一局。

## 完整说明（4000 字以内）

*Champ Full description / 完整说明.*

盘面是考题，时间是裁判。 Velour 把 跑分式 run 做成策略 + 解谜：三连、Perfect、LUX、Heat——给喜欢高压下做决策的人。

玩法
形状/颜色稳住节奏；三颗相同 = Perfect + Heat。暗色霓虹不是为了炫，是为了读得更快。

竞争
全球排行榜 + Oracle 名称（按游戏提示设置）。

模式
经典上手；高额 / 皇家加码。

LUX
商店皮肤与强化；每日奖励（符合条件）。

隐私
分析与崩溃报告可能开启——见隐私政策链接。

想要冲榜、霓虹质感、越难越想玩？安装，然后用排行榜回我。

## 版本说明 — Google Play（发布版本时填写）

*不在主商店详情页单独长期展示：创建版本、上传 AAB 后的「版本说明 / Release notes」步骤，选择与本文档相同语言。注意控制台字数限制。*

• 简体中文与印地语应用内语言；图标与启动画面优化；匹配/Perfect 音效更柔和；修复与稳定性。
