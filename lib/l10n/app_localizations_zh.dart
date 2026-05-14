// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Velour';

  @override
  String get brandTitleDisplay => 'VELOUR';

  @override
  String get startScreenInitializeSystem => '初始化系统';

  @override
  String startScreenHighScoreLine(int high) {
    return '高分$high';
  }

  @override
  String get menuEditionSubtitle => '深色哑光版';

  @override
  String menuStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '连胜：$count 天',
      one: '连胜：1 天',
    );
    return '$_temp0';
  }

  @override
  String get menuPlay => '玩';

  @override
  String menuDailyLuxBonus(int amount) {
    return '+$amount LUX — 每日奖金';
  }

  @override
  String get menuDailyLuxBonusSuccess => '领取每日奖金。';

  @override
  String get menuDailyLuxBonusQueued => '奖金已保存 - 当您在线时它会同步。';

  @override
  String get menuDailyLuxBonusSynced => '余额从服务器同步。';

  @override
  String get menuDailyLuxBonusAlready => '今天已经索赔了。';

  @override
  String get menuDailyLuxBonusRetry => '无法到达服务器。再试一次。';

  @override
  String get menuLeaderboard => '世界排行榜';

  @override
  String get menuShop => '商店';

  @override
  String get menuCareer => '职业生涯';

  @override
  String get menuSettings => '设置';

  @override
  String get menuGuidedTutorial => '教程';

  @override
  String luxHudPrefix(int highScore) {
    return '高分 $highScore • LUX 金币';
  }

  @override
  String get settingsSectionLanguage => '语言';

  @override
  String get settingsLanguageRowTitle => '显示语言';

  @override
  String get settingsLocaleSystem => '系统默认';

  @override
  String get settingsLocaleEnglish => '英语';

  @override
  String get settingsLocaleFrench => '法语';

  @override
  String get settingsLocaleGerman => '德语';

  @override
  String get settingsLocaleChinese => '简体中文';

  @override
  String get settingsLocaleHindi => '印地语';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionAudio => '音频';

  @override
  String get settingsMusicTitle => '音乐';

  @override
  String get settingsMusicOn => '开';

  @override
  String get settingsMusicOff => '关闭';

  @override
  String get settingsSfxTitle => '音效';

  @override
  String get settingsSfxOn => '开';

  @override
  String get settingsSfxOff => '关闭';

  @override
  String get settingsSectionHaptics => '触觉技术';

  @override
  String get settingsHapticsTitle => '触觉反馈';

  @override
  String get settingsHapticsOn => '开启（高级）';

  @override
  String get settingsHapticsOff => '关闭';

  @override
  String get settingsSectionInfos => '信息';

  @override
  String get settingsVersionLabel => '版本';

  @override
  String get settingsCopyPlayerIdTitle => '复制玩家ID';

  @override
  String get settingsCopyPlayerIdSubtitle => '对于支持和错误报告很有用';

  @override
  String get settingsCopyPlayerIdFailed => '玩家 ID 尚不可用。';

  @override
  String settingsCopyPlayerIdSnack(String uid) {
    return '已复制：$uid';
  }

  @override
  String get settingsPingServerTitle => '服务器状态';

  @override
  String get settingsPingServerSubtitle => 'Ping 后端 (velourHealth)';

  @override
  String get settingsPingServerOk => '服务器正常。';

  @override
  String get settingsPingServerFail => '服务器无法访问（检查网络/应用程序检查）。';

  @override
  String get settingsCopyDiagnosticsTitle => '复制诊断';

  @override
  String get settingsCopyDiagnosticsSubtitle => '复制版本、区域设置、玩家 ID 和服务器状态';

  @override
  String get settingsCopyDiagnosticsSnack => '诊断已复制。';

  @override
  String get settingsPrivacyPolicyTitle => '隐私政策';

  @override
  String get settingsPrivacyPolicySubtitle => '在浏览器中打开';

  @override
  String get settingsPrivacyPolicyLaunchFail => '无法打开链接。';

  @override
  String get luxCloudRejectedUpdateRequired =>
      'LUX 同步被拒绝。请更新应用程序。如果问题仍然存在，请在“设置”→“信息”中复制您的玩家 ID。';

  @override
  String get luxCloudRejectedTryLater => 'LUX 同步被拒绝。请稍后重试。';

  @override
  String get luxCloudRejectedGeneric => 'LUX 同步失败。检查网络并重试。';

  @override
  String get settingsCreditsTitle => '制作人员';

  @override
  String get settingsCreditsSubtitle => '查看贡献者';

  @override
  String get settingsSectionDebug => '调试';

  @override
  String get settingsResetTitle => '全部重置';

  @override
  String get settingsResetSubtitle => '清除游戏数据（首选项）并重新启动游戏';

  @override
  String get settingsResetSnack => '游戏重置。重新启动应用程序即可查看教程。';

  @override
  String get settingsDebugResetWelcomeTitle => '重置欢迎礼物';

  @override
  String get settingsDebugResetWelcomeSubtitle =>
      'firstLaunch + LUX 0（在下一个菜单点击时测试 250 LUX）';

  @override
  String get settingsDebugResetWelcomeSnack => '欢迎礼物重置。返回主菜单并点击按钮。';

  @override
  String get settingsFooterTagline => '深色哑光 • 丝绒装饰';

  @override
  String get settingsCreditsDialogTitle => '学分';

  @override
  String get settingsCreditsBody =>
      '丝绒 — 深色哑光版\n\n设计与指导：Velor Studio\n工程：颤振\n音频：Velor SFX 包';

  @override
  String get settingsClose => '关闭';

  @override
  String get shopBackTooltip => '返回';

  @override
  String get shopVaultTitle => '避难所';

  @override
  String get shopProductSparkReserve => '火花储备';

  @override
  String get shopProductOracleTreasure => '甲骨文的宝藏';

  @override
  String get shopProductRoyalLegacy => '皇家遗产';

  @override
  String get shopBadgeBestDeal => '最划算';

  @override
  String shopLuxAmount(int lux) {
    return '$lux勒克斯';
  }

  @override
  String get shopForgeTitle => '甲骨文熔炉';

  @override
  String get shopSkinEquipped => '装备齐全';

  @override
  String get shopSkinOwned => '拥有';

  @override
  String shopPriceLux(int price) {
    return '$price勒克斯';
  }

  @override
  String get shopVaultLoading => '联系金库……';

  @override
  String get shopVaultPricePending => '—';

  @override
  String get shopPurchaseSuccess => '成功';

  @override
  String shopPurchaseLuxAdded(int lux) {
    return '+$lux勒克斯';
  }

  @override
  String get shopBackToGame => '返回游戏';

  @override
  String get shopSnackInsufficientLux => '勒克斯不够。';

  @override
  String get shopSnackSkinEquipped => '皮肤配备。';

  @override
  String get shopSnackSkinUnlocked => '皮肤已解锁并装备。';

  @override
  String get shopForgeBoostsSection => '会话提升';

  @override
  String get shopForgeSectionRunSalvage => '运行救援';

  @override
  String get shopForgeSectionStrategyStakes => '策略与风险';

  @override
  String get shopForgeInsuranceTitle => '甲骨文保险';

  @override
  String shopForgeInsuranceBody(
    int highAnte,
    int royalAnte,
    int refundPct,
    int maxCharges,
  ) {
    return '如果您输掉了下一次高额赌注 ($highAnte LUX ante) 或皇家 ($royalAnte LUX ante) 比赛，Oracle 将退还该参赛赌注的 $refundPct%。最多可叠加 $maxCharges 颗电荷。';
  }

  @override
  String shopForgeInsuranceCharges(int count, int max) {
    return '$count / $max 费用';
  }

  @override
  String get shopForgeRoyalBountyTitle => '皇家赏金';

  @override
  String shopForgeRoyalBountyBody(int bonusLux, int royalWinLux) {
    return '一旦您完成了皇家目标，您的下一次皇家胜利将获得+$bonusLux奖金LUX（除了通常的${royalWinLux}LUX获胜奖金之外）。一次一项活跃赏金。';
  }

  @override
  String get shopForgeRoyalBountyActive => '活跃 — 下一场皇家胜利将支付额外费用';

  @override
  String get shopSnackForgeInsurancePurchased => '加了保险费。';

  @override
  String get shopSnackForgeRoyalBountyPurchased => '皇家赏金将为您的下一次皇家胜利而激活。';

  @override
  String get shopSnackForgeInsuranceFull => '您已持有 3 项保险费用。';

  @override
  String get shopSnackForgeRoyalBountyActive => '皇家赏金已经激活。';

  @override
  String get shopForgeChronoPulseTitle => '计时储备';

  @override
  String shopForgeChronoPulseBody(int maxCharges) {
    return '当会话计时器归零时，一次充电会将条充满，以便跑步继续。最多可叠加 $maxCharges 电荷。教程期间不活动。';
  }

  @override
  String shopForgeChronoPulseCharges(int count, int max) {
    return '$count / $max 费用';
  }

  @override
  String get shopForgeMercySalvageTitle => '甲骨文的仁慈';

  @override
  String shopForgeMercySalvageBody(int maxCharges) {
    return '机架已满且没有有效匹配：一次充电会将机架末端重塑为可玩的三重，以便您继续前进。最多可叠加 $maxCharges 电荷。教程期间不活动。';
  }

  @override
  String shopForgeMercySalvageCharges(int count, int max) {
    return '$count / $max 费用';
  }

  @override
  String get shopSnackForgeChronoPulsePurchased => '添加了计时储备费用。';

  @override
  String get shopSnackForgeChronoPulseFull => '你已经持有 2 个计时费用。';

  @override
  String get shopSnackForgeMercySalvagePurchased => '添加了慈悲救助费用。';

  @override
  String get shopSnackForgeMercySalvageFull => '您已被指控 2 项怜悯罪。';

  @override
  String get shopIapUnavailable => '此设备不支持应用内购买。';

  @override
  String get shopIapProductsUnavailable => 'LUX 包目前无法从商店购买。';

  @override
  String get shopIapCancelled => '购买已取消。';

  @override
  String get shopIapOffline => '没有互联网连接。请禁用飞行模式并重试。';

  @override
  String shopIapError(String details) {
    return '付款错误：$details';
  }

  @override
  String get shopIapErrorBusy => '另一项购买已经在进行中。请稍等。';

  @override
  String get shopIapErrorUnknown => '付款时出了点问题。请再试一次。';

  @override
  String get shopIapErrorServerVerificationFailed =>
      '我们无法通过服务器验证此次购买。检查您的连接并重试。';

  @override
  String get shopIapErrorDuplicateTransaction => '该购买已被处理。';

  @override
  String get shopIapErrorRestoredIgnored => '恢复购买不会为消耗品包提供 LUX。';

  @override
  String get statsTitle => '我的职业生涯';

  @override
  String statsStreakSession(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '连胜 · $count 天',
      one: '连胜 · 1 天',
    );
    return '$_temp0';
  }

  @override
  String get statsLuxEarned => '赢得的勒克斯';

  @override
  String get statsBestGain => '最佳胜利';

  @override
  String get statsMaxLevel => '最高等级';

  @override
  String get statsShapesPlaced => '放置的形状';

  @override
  String get statsMatches => '比赛';

  @override
  String get statsTotalTime => '总时间';

  @override
  String get statsPrecisionTitle => '准确度';

  @override
  String get statsPrecisionHelp => '匹配位置比。\n更高意味着更干净的运行。';

  @override
  String get statsModesTitle => '模式分割';

  @override
  String get statsModeCasual => '休闲';

  @override
  String get statsModeHighStakes => '高风险';

  @override
  String get statsModeRoyal => '皇家';

  @override
  String get gameHudMenuTooltip => '菜单';

  @override
  String get pauseTitle => '暂停';

  @override
  String get pauseResume => '继续';

  @override
  String get pauseBackToMenu => '返回菜单';

  @override
  String get premiumForfeitTitle => '没收？';

  @override
  String premiumForfeitLead(String session) {
    return '如果您离开本次$session会话，您将失去您的股份';
  }

  @override
  String get premiumForfeitTrail => '永久勒克斯。';

  @override
  String get premiumSessionHighStakes => '高风险';

  @override
  String get premiumSessionRoyal => '皇家';

  @override
  String get premiumStay => '留下来';

  @override
  String get premiumForfeit => '没收';

  @override
  String get gameOverTitleSessionEnd => '会话完成';

  @override
  String get gameOverTitleVictory => '胜利';

  @override
  String get gameOverTitleDefeat => '失败';

  @override
  String get gameOverSessionScore => '会话分数';

  @override
  String get gameOverZeroLuxHintCasual =>
      '本场比赛没有匹配 LUX — 计时器已用完或者您在第一次增益之前就离开了。';

  @override
  String get gameOverZeroLuxHintHighStakes => '比赛结束前没有任何 LUX 入库——目标未达到或时间已到。';

  @override
  String get gameOverZeroLuxHintRoyal => '比赛结束前没有任何 LUX 入库——目标未达到或时间已到。';

  @override
  String get gameOverFinalScore => '最终得分';

  @override
  String get gameOverLuxWon => '力士赢';

  @override
  String get gameOverPersonalBest => '新个人最佳成绩';

  @override
  String gameOverCareerRecordHint(int high) {
    return '职业记录（已保存）：$high';
  }

  @override
  String get gameOverReplay => '再玩一次';

  @override
  String get gameOverMainMenu => '主菜单';

  @override
  String get gameOverPrestigeBonus => '声望奖励';

  @override
  String get gameOverFooterHighStakesFail => '赌注输了：本金被没收';

  @override
  String get gameOverFooterHighStakesWin150 => '您将赢得 150 勒克斯';

  @override
  String get gameOverFooterRoyalFail => '皇家赌注输了：赌注被没收';

  @override
  String get gameOverFooterRoyalWin1250 => '您将赢得 1250 勒克斯';

  @override
  String get gameOverOracleInsuranceTitle => '甲骨文封面';

  @override
  String gameOverOracleInsuranceRefund(int lux) {
    return '+$lux LUX 回到您的钱包';
  }

  @override
  String get gameOverOracleNamingBannerTitle => '进入排行榜';

  @override
  String get gameOverOracleNamingBannerBody => '印上您的名字即可出现在全球排行榜上。';

  @override
  String get gameOverOracleNamingNameNowButton => '命名它';

  @override
  String welcomeGiftBannerLux(int lux) {
    return '丝绒迎宾：+$lux LUX';
  }

  @override
  String get oracleNamingDialogTitle => '卓越定义您';

  @override
  String get oracleNamingDialogBody => '选择 Oracle 会认识您的名字。它将以小写形式存储以避免重复。';

  @override
  String get oracleNamingValidationRequired => '姓名必填';

  @override
  String get oracleNamingValidationTooLong => '最多 15 个字符';

  @override
  String get oracleNamingValidationInvalidChars => '仅字母、数字和 _（最多 15 个）';

  @override
  String get oracleNamingSaveError => '无法保存（网络或服务器）。请重试或稍后关闭。';

  @override
  String get oracleNamingSealButton => '封上我的名字';

  @override
  String get oracleNamingFieldHint => 'ORACLE_NAME';

  @override
  String get criticalFailureTitle => '系统过载';

  @override
  String get criticalFailureSubtitle => '连接丢失';

  @override
  String get criticalFailureResetButton => '重置系统';

  @override
  String get gameSequenceCompletedTitle => '序列完成';

  @override
  String get oracleDockStep1Shape => '形状 = +100 LUX（最小）\n相同轮廓• 3 种颜色 → 机架';

  @override
  String get oracleDockStep2Color => '颜色 = +150 LUX\n相同色调•3种形状→架子';

  @override
  String get oracleDockStep3Perfect =>
      '完美 = +500 LUX\n3 颗相同的宝石 → 机架\n背靠背完美构建热度：奖励 LUX 和时间。\n在实际运行中，分数下方的热度栏会跟踪您的连胜记录。';

  @override
  String get oracleDockCelebration =>
      '100 < 150 < 500 勒克斯\n在真正的比赛中，完美的连续得分为热火队提供了动力。';

  @override
  String get oracleDockStep1StrategyLine => '第一：一个轮廓，三种不同的颜色。';

  @override
  String get oracleDockStep2StrategyLine => '如果距离完美只有一颗宝石，就不要选择弱三重。';

  @override
  String get oracleDockStep3StrategyLine => '较弱的形状/颜色可以消除热量 - 规划您的完美链条。';

  @override
  String get oracleDockCelebrationStrategyLine => '后来：热量和计时器都会决定你所冒的风险。';

  @override
  String get tutorialTrinityShapeIntro => '形状即结构。将他们分组。';

  @override
  String get tutorialTrinityColorIntro => '色彩是和谐的。它创造了机会。';

  @override
  String get tutorialTrinityPerfectIntro =>
      '完美搭配：绝对的结合。触发 LUX 爆发。连锁完美建立热度以获得更大的支出。';

  @override
  String get narrativeFloatShapeBonus => '+100 LUX：结构（形状）';

  @override
  String get narrativeFloatColorBonus => '+150 LUX：和谐（颜色）';

  @override
  String get narrativeFloatPerfectBonus => '+500 LUX：整体亮度';

  @override
  String get gameNarrativePerfectMatchBanner => '完美搭配';

  @override
  String get prepTitle => '会话设置';

  @override
  String get prepLuxScoreCaption => '力士币';

  @override
  String get prepGuidedTutorialCasualOnly => '本教程仅提供经典模式。';

  @override
  String get prepGuidedTutorialGoalTitle => '您的目标是什么';

  @override
  String get prepGuidedTutorialGoalBody =>
      '每场比赛都会增加运行中的 LUX 并提升您的水平。更丰富的匹配类型（尤其是完美匹配）比较弱的三元组支付的费用要高得多。真正的技巧是选择你采取哪种清除以及何时采取。\n\n连续完美匹配会提高热度（实际运行中的计量表）：更高的级别会在每个完美匹配上添加 LUX，并且可以补充时间；弱三元组让它冷却下来。';

  @override
  String get prepGuidedTutorialStrategyTitle => '在第三颗宝石之前思考';

  @override
  String get prepGuidedTutorialStrategyBody =>
      '在您提交第三颗宝石之前，请阅读您的宝石架：如果您距离三颗相同宝石（相同形状和相同颜色）只有一颗宝石，那么抓住一个更简单的纯颜色三颗宝石可能会破坏设置并在桌子上留下很多 LUX。\n\n在本演练中，计时器保持暂停状态，以便您可以平静地练习。在实际运行中，等待需要成本、压力和回报之间的权衡。';

  @override
  String get prepModeCasualTitle => '经典模式';

  @override
  String prepModeCasualBody(int ante) {
    return '赌注：${ante}LUX。自由练习。';
  }

  @override
  String get prepModeHighStakesTitle => '高风险';

  @override
  String prepModeHighStakesBody(int ante, int goal, int reward) {
    return '赌注：${ante}LUX。目标：等级$goal。奖励：${reward}LUX。';
  }

  @override
  String get prepModeRoyalTitle => '皇家丝绒';

  @override
  String prepModeRoyalBody(int ante, int goal, int reward) {
    return '赌注：${ante}LUX。目标：等级$goal。奖励：${reward}LUX。';
  }

  @override
  String get prepInsufficientLux => 'LUX 平衡不足。';

  @override
  String get prepConfirm => '确认';

  @override
  String get prepBuyLux => '购买勒克斯';

  @override
  String get prepSelectedChip => '已选';

  @override
  String get leaderboardTitle => '世界排行榜';

  @override
  String get leaderboardColRank => '排名';

  @override
  String get leaderboardColPlayer => '玩家';

  @override
  String get leaderboardColScore => '分数';

  @override
  String leaderboardError(String details) {
    return '排行榜暂时不可用。\n检查您的连接或 Firestore 规则。\n($details)';
  }

  @override
  String get leaderboardLoading => '正在加载排名...';

  @override
  String get leaderboardEmpty => '尚未记录分数。';

  @override
  String get leaderboardYourRankFooter => '你的等级';

  @override
  String leaderboardPlayerAnon(String id) {
    return '玩家$id';
  }

  @override
  String get leaderboardPodiumFirst => '第一名';

  @override
  String get leaderboardPodiumSecond => '第二名';

  @override
  String get leaderboardPodiumThird => '第三名';

  @override
  String get leaderboardPodiumOther => '讲台';

  @override
  String gameFloatLuxGain(int gain) {
    return '+$gain勒克斯';
  }

  @override
  String gameFloatLuxGainMult(int gain, String mult) {
    return '+$gain勒克斯×$mult';
  }

  @override
  String gameFloatPerfectGain(int gain) {
    return '+$gain完美';
  }

  @override
  String gameFloatPerfectGainMult(int gain, String mult) {
    return '+$gain完美×$mult';
  }

  @override
  String gameFloatCombo(String mult) {
    return '组合×$mult';
  }

  @override
  String get gameHudScore => '分数';

  @override
  String get gameHudTime => '时间';

  @override
  String get gameHudPerfectHeatLabel => '热火';

  @override
  String get gameHudPerfectHeatNearFloater => '近';

  @override
  String get gameHudPerfectHeatRebound => '反弹';

  @override
  String gameHudLevelShort(int level) {
    return '左心室$level';
  }

  @override
  String gameHudLuxAmount(int lux) {
    return '$lux勒克斯';
  }

  @override
  String get gameHudLuxThisRun => '这次跑步';

  @override
  String get gameHudLevelTag => '等级';

  @override
  String get gameHudLevelUpTitle => '升级！';

  @override
  String gameHudLevelUpSubtitle(int level) {
    return '等级$level';
  }

  @override
  String get gameHudPerfectHeatSurgeTitle => '热浪';

  @override
  String gameHudPerfectHeatSurgeSubtitle(int heatTier) {
    return '阶段$heatTier';
  }

  @override
  String gameHudPerfectHeatHudBonus(int luxPercent, String multLabel) {
    return '+$luxPercent% $multLabel';
  }

  @override
  String gameHudForgeChronoA11y(int count) {
    return '计时储备，$count费用';
  }

  @override
  String gameHudForgeMercyA11y(int count) {
    return '神谕怜悯，$count收费';
  }

  @override
  String get gameHudTimeResolvingA11y => '连击解决，宝石短暂锁定。';

  @override
  String get settingsSectionAccessibility => '运动与可达性';

  @override
  String get settingsAccessibilityBody =>
      '在系统设置应用程序（辅助功能 → 运动）中打开“减少运动”，以获得更平静的视觉效果和更少的闪烁。Velor 会自动检测到这一点。';

  @override
  String a11yGemButtonLabel(String shape, String color) {
    return '$shape, $color';
  }

  @override
  String get a11yGemShape1 => '水晶';

  @override
  String get a11yGemShape2 => '球体';

  @override
  String get a11yGemShape3 => '金字塔';

  @override
  String get a11yGemShape4 => '明星';

  @override
  String get a11yGemShape5 => '钻石';

  @override
  String get a11yGemShape6 => '五角大楼';

  @override
  String get a11yGemShape7 => '六角星';

  @override
  String get a11yGemColor0 => '白色';

  @override
  String get a11yGemColor1 => '青色';

  @override
  String get a11yGemColor2 => '黄金';

  @override
  String get a11yGemColor3 => '洋红色';

  @override
  String get a11yGemColor4 => '绿色';

  @override
  String get a11yGemColor5 => '紫色';

  @override
  String get a11yGemColor6 => '橙色';

  @override
  String get a11yGemColor7 => '苍白';

  @override
  String a11yRackSlotEmpty(int slot, int max) {
    return '$max 的机架插槽 $slot 为空。';
  }

  @override
  String a11yRackSlotOccupied(int slot, int max) {
    return '$max 的机架插槽 $slot 已被占用。';
  }

  @override
  String get a11yRackSlotImminentHint => '相邻的一对几乎完成。';
}
