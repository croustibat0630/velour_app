// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Velour';

  @override
  String get brandTitleDisplay => 'VELOUR';

  @override
  String get startScreenInitializeSystem => 'सिस्टम आरंभ करें';

  @override
  String startScreenHighScoreLine(int high) {
    return 'उच्च स्कोर $high';
  }

  @override
  String get menuEditionSubtitle => 'डार्क मैट संस्करण';

  @override
  String menuStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'स्ट्रीक: $count दिन',
      one: 'स्ट्रीक: 1 दिन',
    );
    return '$_temp0';
  }

  @override
  String get menuPlay => 'खेलें';

  @override
  String menuDailyLuxBonus(int amount) {
    return '+$amount लक्स - दैनिक बोनस';
  }

  @override
  String get menuDailyLuxBonusSuccess => 'दैनिक बोनस का दावा किया गया.';

  @override
  String get menuDailyLuxBonusQueued =>
      'बोनस सहेजा गया - जब आप ऑनलाइन होंगे तो यह सिंक हो जाएगा।';

  @override
  String get menuDailyLuxBonusSynced => 'सर्वर से बैलेंस सिंक किया गया.';

  @override
  String get menuDailyLuxBonusAlready => 'आज पहले ही दावा किया जा चुका है.';

  @override
  String get menuDailyLuxBonusRetry =>
      'सर्वर तक नहीं पहुंच सका.पुनः प्रयास करें।';

  @override
  String get menuLeaderboard => 'विश्व लीडरबोर्ड';

  @override
  String get menuShop => 'दुकान';

  @override
  String get menuCareer => 'कैरियर';

  @override
  String get menuSettings => 'सेटिंग्स';

  @override
  String get menuGuidedTutorial => 'ट्यूटोरियल';

  @override
  String luxHudPrefix(int highScore) {
    return 'उच्च स्कोर $highScore • लक्स सिक्के';
  }

  @override
  String get settingsSectionLanguage => 'भाषा';

  @override
  String get settingsLanguageRowTitle => 'भाषा प्रदर्शित करें';

  @override
  String get settingsLocaleSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get settingsLocaleEnglish => 'अंग्रेजी';

  @override
  String get settingsLocaleFrench => 'फ़्रेंच';

  @override
  String get settingsLocaleGerman => 'जर्मन';

  @override
  String get settingsLocaleChinese => 'चीनी (सरलीकृत)';

  @override
  String get settingsLocaleHindi => 'हिन्दी';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsSectionAudio => 'ऑडियो';

  @override
  String get settingsMusicTitle => 'संगीत';

  @override
  String get settingsMusicOn => 'पर';

  @override
  String get settingsMusicOff => 'बंद';

  @override
  String get settingsSfxTitle => 'ध्वनि प्रभाव';

  @override
  String get settingsSfxOn => 'पर';

  @override
  String get settingsSfxOff => 'बंद';

  @override
  String get settingsSectionHaptics => 'हाप्टिक्स';

  @override
  String get settingsHapticsTitle => 'हैप्टिक फीडबैक';

  @override
  String get settingsHapticsOn => 'चालू (प्रीमियम)';

  @override
  String get settingsHapticsOff => 'बंद';

  @override
  String get settingsSectionInfos => 'जानकारी';

  @override
  String get settingsVersionLabel => 'संस्करण';

  @override
  String get settingsCopyPlayerIdTitle => 'प्लेयर आईडी कॉपी करें';

  @override
  String get settingsCopyPlayerIdSubtitle =>
      'समर्थन और बग रिपोर्ट के लिए उपयोगी';

  @override
  String get settingsCopyPlayerIdFailed => 'प्लेयर आईडी अभी उपलब्ध नहीं है.';

  @override
  String settingsCopyPlayerIdSnack(String uid) {
    return 'कॉपी किया गया: $uid';
  }

  @override
  String get settingsPingServerTitle => 'सर्वर स्थिति';

  @override
  String get settingsPingServerSubtitle => 'पिंग बैकएंड (वेलोरहेल्थ)';

  @override
  String get settingsPingServerOk => 'सर्वर ठीक है.';

  @override
  String get settingsPingServerFail =>
      'सर्वर पहुंच योग्य नहीं है (नेटवर्क जांचें / ऐप जांचें)।';

  @override
  String get settingsCopyDiagnosticsTitle =>
      'डायग्नोस्टिक्स की प्रतिलिपि बनाएँ';

  @override
  String get settingsCopyDiagnosticsSubtitle =>
      'संस्करण, स्थान, प्लेयर आईडी और सर्वर स्थिति की प्रतिलिपि बनाएँ';

  @override
  String get settingsCopyDiagnosticsSnack => 'निदान की प्रतिलिपि बनाई गई.';

  @override
  String get settingsPrivacyPolicyTitle => 'गोपनीयता नीति';

  @override
  String get settingsPrivacyPolicySubtitle => 'ब्राउज़र में खोलें';

  @override
  String get settingsPrivacyPolicyLaunchFail => 'लिंक नहीं खुल सका.';

  @override
  String get luxCloudRejectedUpdateRequired =>
      'LUX सिंक अस्वीकृत.कृपया ऐप को अपडेट करें.यदि यह बनी रहती है, तो सेटिंग्स → जानकारी में अपनी प्लेयर आईडी कॉपी करें।';

  @override
  String get luxCloudRejectedTryLater =>
      'LUX सिंक अस्वीकृत.कृपया बाद में पुन: प्रयास करें।';

  @override
  String get luxCloudRejectedGeneric =>
      'LUX सिंक विफल रहा.नेटवर्क जांचें और पुनः प्रयास करें.';

  @override
  String get settingsCreditsTitle => 'श्रेय';

  @override
  String get settingsCreditsSubtitle => 'योगदानकर्ताओं को देखें';

  @override
  String get settingsSectionDebug => 'डिबग';

  @override
  String get settingsResetTitle => 'सभी रीसेट करें';

  @override
  String get settingsResetSubtitle =>
      'गेम डेटा (प्रीफ़्स) साफ़ करता है और ऑनबोर्डिंग पुनः आरंभ करता है';

  @override
  String get settingsResetSnack =>
      'गेम रीसेट.ट्यूटोरियल देखने के लिए ऐप को दोबारा लॉन्च करें।';

  @override
  String get settingsDebugResetWelcomeTitle => 'स्वागत उपहार रीसेट करें';

  @override
  String get settingsDebugResetWelcomeSubtitle =>
      'फर्स्टलॉन्च + लक्स 0 (अगले मेनू टैप पर 250 लक्स का परीक्षण करें)';

  @override
  String get settingsDebugResetWelcomeSnack =>
      'स्वागत उपहार रीसेट.मुख्य मेनू पर लौटें और एक बटन टैप करें।';

  @override
  String get settingsFooterTagline => 'डार्क मैट • वेलोर एक्सेंट';

  @override
  String get settingsCreditsDialogTitle => 'क्रेडिट';

  @override
  String get settingsCreditsBody =>
      'वेलोर - डार्क मैट संस्करण\n\nडिज़ाइन एवं निर्देशन: वेलोर स्टूडियो\nइंजीनियरिंग: स्पंदन\nऑडियो: वेलोर एसएफएक्स पैक';

  @override
  String get settingsClose => 'बंद करें';

  @override
  String get shopBackTooltip => 'वापस';

  @override
  String get shopVaultTitle => 'तिजोरी';

  @override
  String get shopProductSparkReserve => 'स्पार्क रिजर्व';

  @override
  String get shopProductOracleTreasure => 'ओरेकल का खजाना';

  @override
  String get shopProductRoyalLegacy => 'शाही विरासत';

  @override
  String get shopBadgeBestDeal => 'सबसे अच्छा सौदा';

  @override
  String shopLuxAmount(int lux) {
    return '$lux लक्स';
  }

  @override
  String get shopForgeTitle => 'ओरेकल फोर्ज';

  @override
  String get shopSkinEquipped => 'सुसज्जित';

  @override
  String get shopSkinOwned => 'स्वामित्व';

  @override
  String shopPriceLux(int price) {
    return '$price लक्स';
  }

  @override
  String get shopVaultLoading => 'तिजोरी से संपर्क किया जा रहा है...';

  @override
  String get shopVaultPricePending => '—';

  @override
  String get shopPurchaseSuccess => 'सफलता';

  @override
  String shopPurchaseLuxAdded(int lux) {
    return '+$lux लक्स';
  }

  @override
  String get shopBackToGame => 'खेल पर वापस जाएँ';

  @override
  String get shopSnackInsufficientLux => 'पर्याप्त लक्स नहीं.';

  @override
  String get shopSnackSkinEquipped => 'त्वचा सुसज्जित.';

  @override
  String get shopSnackSkinUnlocked => 'त्वचा खुली और सुसज्जित।';

  @override
  String get shopForgeBoostsSection => 'सत्र को बढ़ावा';

  @override
  String get shopForgeSectionRunSalvage => 'बचाव चलाएँ';

  @override
  String get shopForgeSectionStrategyStakes => 'रणनीति और दांव';

  @override
  String get shopForgeInsuranceTitle => 'ओरेकल बीमा';

  @override
  String shopForgeInsuranceBody(
    int highAnte,
    int royalAnte,
    int refundPct,
    int maxCharges,
  ) {
    return 'यदि आप अपना अगला हाई स्टेक ($highAnte LUX ante) या रॉयल ($royalAnte LUX ante) रन हार जाते हैं, तो Oracle उस प्रवेश हिस्सेदारी का $refundPct% वापस कर देता है।$maxCharges शुल्क तक ढेर।';
  }

  @override
  String shopForgeInsuranceCharges(int count, int max) {
    return '$count / $max शुल्क';
  }

  @override
  String get shopForgeRoyalBountyTitle => 'शाही इनाम';

  @override
  String shopForgeRoyalBountyBody(int bonusLux, int royalWinLux) {
    return 'एक बार जब आप रॉयल उद्देश्य पूरा कर लेते हैं तो आपकी अगली रॉयल जीत पर +$bonusLux बोनस लक्स (सामान्य $royalWinLux लक्स जीत भुगतान के अतिरिक्त)।एक समय में एक सक्रिय इनाम।';
  }

  @override
  String get shopForgeRoyalBountyActive =>
      'सक्रिय - अगली रॉयल जीत अतिरिक्त भुगतान करती है';

  @override
  String get shopSnackForgeInsurancePurchased => 'बीमा शुल्क जोड़ा गया.';

  @override
  String get shopSnackForgeRoyalBountyPurchased =>
      'आपकी अगली रॉयल जीत के लिए रॉयल इनाम सक्रिय है।';

  @override
  String get shopSnackForgeInsuranceFull =>
      'आपके पास पहले से ही 3 बीमा शुल्क हैं।';

  @override
  String get shopSnackForgeRoyalBountyActive =>
      'रॉयल इनाम पहले से ही सक्रिय है।';

  @override
  String get shopForgeChronoPulseTitle => 'क्रोनो रिजर्व';

  @override
  String shopForgeChronoPulseBody(int maxCharges) {
    return 'जब सत्र टाइमर शून्य पर पहुंच जाता है, तो एक बार चार्ज करने पर बार पूरी तरह भर जाता है, जिससे रन जारी रहता है।$maxCharges शुल्क तक ढेर।ट्यूटोरियल के दौरान निष्क्रिय.';
  }

  @override
  String shopForgeChronoPulseCharges(int count, int max) {
    return '$count / $max शुल्क';
  }

  @override
  String get shopForgeMercySalvageTitle => 'ओरेकल की दया';

  @override
  String shopForgeMercySalvageBody(int maxCharges) {
    return 'बिना किसी वैध मिलान के रैक भरा हुआ: एक चार्ज आपके रैक के अंत को खेलने योग्य ट्रिपल में बदल देता है ताकि आप चलते रहें।$maxCharges शुल्क तक ढेर।ट्यूटोरियल के दौरान निष्क्रिय.';
  }

  @override
  String shopForgeMercySalvageCharges(int count, int max) {
    return '$count / $max शुल्क';
  }

  @override
  String get shopSnackForgeChronoPulsePurchased =>
      'क्रोनो रिजर्व चार्ज जोड़ा गया।';

  @override
  String get shopSnackForgeChronoPulseFull =>
      'आपके पास पहले से ही 2 क्रोनो चार्ज हैं।';

  @override
  String get shopSnackForgeMercySalvagePurchased => 'दया बचाव शुल्क जोड़ा गया।';

  @override
  String get shopSnackForgeMercySalvageFull =>
      'आप पर पहले से ही 2 दया आरोप हैं।';

  @override
  String get shopIapUnavailable => 'इस डिवाइस पर इन-ऐप खरीदारी उपलब्ध नहीं है।';

  @override
  String get shopIapProductsUnavailable =>
      'LUX पैक अभी स्टोर से उपलब्ध नहीं हैं।';

  @override
  String get shopIapCancelled => 'खरीदारी रद्द कर दी गई.';

  @override
  String get shopIapOffline =>
      'कोई इंटरनेट कनेक्शन नहीं.कृपया एयरप्लेन मोड अक्षम करें और पुनः प्रयास करें।';

  @override
  String shopIapError(String details) {
    return 'भुगतान त्रुटि: $details';
  }

  @override
  String get shopIapErrorBusy =>
      'एक और खरीदारी पहले से ही प्रगति पर है.कृपया प्रतीक्षा करें।';

  @override
  String get shopIapErrorUnknown =>
      'भुगतान में कुछ गड़बड़ी हुई.कृपया पुन: प्रयास करें।';

  @override
  String get shopIapErrorServerVerificationFailed =>
      'हम इस खरीदारी को सर्वर से सत्यापित नहीं कर सके.अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get shopIapErrorDuplicateTransaction =>
      'यह खरीदारी पहले ही संसाधित हो चुकी थी.';

  @override
  String get shopIapErrorRestoredIgnored =>
      'पुनर्स्थापित खरीदारी उपभोज्य पैक के लिए LUX प्रदान नहीं करती है।';

  @override
  String get statsTitle => 'मेरा करियर';

  @override
  String statsStreakSession(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'स्ट्रीक · $count दिन',
      one: 'स्ट्रीक · 1 दिन',
    );
    return '$_temp0';
  }

  @override
  String get statsLuxEarned => 'लक्स कमाया';

  @override
  String get statsBestGain => 'सर्वोत्तम जीत';

  @override
  String get statsMaxLevel => 'अधिकतम स्तर';

  @override
  String get statsShapesPlaced => 'आकृतियाँ रखी गईं';

  @override
  String get statsMatches => 'मिलान';

  @override
  String get statsTotalTime => 'कुल समय';

  @override
  String get statsPrecisionTitle => 'सटीकता';

  @override
  String get statsPrecisionHelp =>
      'मिलान-से-प्लेसमेंट अनुपात.\nउच्चतर का अर्थ है साफ़-सुथरा चलना।';

  @override
  String get statsModesTitle => 'मोड स्प्लिट';

  @override
  String get statsModeCasual => 'आकस्मिक';

  @override
  String get statsModeHighStakes => 'ऊंचे दांव';

  @override
  String get statsModeRoyal => 'शाही';

  @override
  String get gameHudMenuTooltip => 'मेनू';

  @override
  String get pauseTitle => 'रोका गया';

  @override
  String get pauseResume => 'फिर से शुरू करें';

  @override
  String get pauseBackToMenu => 'मेनू पर वापस जाएँ';

  @override
  String get premiumForfeitTitle => 'जब्त?';

  @override
  String premiumForfeitLead(String session) {
    return 'यदि आप इस $session सत्र को छोड़ देते हैं, तो आपकी हिस्सेदारी जब्त हो जाएगी';
  }

  @override
  String get premiumForfeitTrail => 'लक्स स्थायी रूप से।';

  @override
  String get premiumSessionHighStakes => 'ऊंचे दांव';

  @override
  String get premiumSessionRoyal => 'शाही';

  @override
  String get premiumStay => 'रहो';

  @override
  String get premiumForfeit => 'ज़ब्त';

  @override
  String get gameOverTitleSessionEnd => 'सत्र पूरा हुआ';

  @override
  String get gameOverTitleVictory => 'विजय';

  @override
  String get gameOverTitleDefeat => 'हार';

  @override
  String get gameOverSessionScore => 'सत्र स्कोर';

  @override
  String get gameOverZeroLuxHintCasual =>
      'इस सत्र में LUX का कोई मुकाबला नहीं - टाइमर ख़त्म हो गया या आप पहली बढ़त से पहले ही चले गए।';

  @override
  String get gameOverZeroLuxHintHighStakes =>
      'अंत से पहले कोई लक्स बैंक नहीं हुआ - लक्ष्य पूरा नहीं हुआ या समय समाप्त हो गया।';

  @override
  String get gameOverZeroLuxHintRoyal =>
      'अंत से पहले कोई लक्स बैंक नहीं हुआ - लक्ष्य पूरा नहीं हुआ या समय समाप्त हो गया।';

  @override
  String get gameOverFinalScore => 'अंतिम स्कोर';

  @override
  String get gameOverLuxWon => 'लक्स जीत गया';

  @override
  String get gameOverPersonalBest => 'नया व्यक्तिगत सर्वोत्तम';

  @override
  String gameOverCareerRecordHint(int high) {
    return 'कैरियर रिकॉर्ड (सहेजा गया): $high';
  }

  @override
  String get gameOverReplay => 'फिर से खेलें';

  @override
  String get gameOverMainMenu => 'मुख्य मेनू';

  @override
  String get gameOverPrestigeBonus => 'प्रतिष्ठा बोनस';

  @override
  String get gameOverFooterHighStakesFail =>
      'दांव हार गया: हिस्सेदारी जब्त हो गई';

  @override
  String get gameOverFooterHighStakesWin150 => 'आप 150 लक्स जीतें';

  @override
  String get gameOverFooterRoyalFail =>
      'शाही दांव हार गया: हिस्सेदारी जब्त हो गई';

  @override
  String get gameOverFooterRoyalWin1250 => 'आप 1250 लक्स जीतें';

  @override
  String get gameOverOracleInsuranceTitle => 'ओरेकल कवर';

  @override
  String gameOverOracleInsuranceRefund(int lux) {
    return '+$lux LUX आपके पर्स में वापस आ गया';
  }

  @override
  String get gameOverOracleNamingBannerTitle => 'लीडरबोर्ड प्रविष्टि';

  @override
  String get gameOverOracleNamingBannerBody =>
      'वैश्विक लीडरबोर्ड पर प्रदर्शित होने के लिए अपना नाम सील करें।';

  @override
  String get gameOverOracleNamingNameNowButton => 'इसे नाम दें';

  @override
  String welcomeGiftBannerLux(int lux) {
    return 'वेलोर स्वागत: +$lux लक्स';
  }

  @override
  String get oracleNamingDialogTitle => 'उत्कृष्टता आपको परिभाषित करती है';

  @override
  String get oracleNamingDialogBody =>
      'वह नाम चुनें जिससे Oracle आपको जानेगा।डुप्लिकेट से बचने के लिए इसे लोअरकेस में संग्रहीत किया जाएगा।';

  @override
  String get oracleNamingValidationRequired => 'नाम आवश्यक है';

  @override
  String get oracleNamingValidationTooLong => 'अधिकतम 15 अक्षर';

  @override
  String get oracleNamingValidationInvalidChars =>
      'केवल अक्षर, अंक और _ (अधिकतम 15)';

  @override
  String get oracleNamingSaveError =>
      'सहेजा नहीं जा सका (नेटवर्क या सर्वर).पुनः प्रयास करें या बाद के लिए बंद करें।';

  @override
  String get oracleNamingSealButton => 'मेरा नाम सील करें';

  @override
  String get oracleNamingFieldHint => 'ORACLE_NAME';

  @override
  String get criticalFailureTitle => 'सिस्टम ओवरचार्ज';

  @override
  String get criticalFailureSubtitle => 'कनेक्शन टूट गया';

  @override
  String get criticalFailureResetButton => 'रीसेट प्रणाली';

  @override
  String get gameSequenceCompletedTitle => 'अनुक्रम पूरा';

  @override
  String get oracleDockStep1Shape =>
      'आकार = +100 लक्स (न्यूनतम)\nसमान सिल्हूट • 3 रंग → रैक';

  @override
  String get oracleDockStep2Color =>
      'रंग = +150 लक्स\nएक ही रंग • 3 आकार → रैक';

  @override
  String get oracleDockStep3Perfect =>
      'परफेक्ट = +500 लक्स\n3 समान रत्न → रैक\nबैक-टू-बैक परफेक्ट्स हीट का निर्माण करते हैं: बोनस लक्स और समय।\nवास्तविक रनों में, स्कोर के नीचे हीट बार आपकी स्ट्रीक को ट्रैक करता है।';

  @override
  String get oracleDockCelebration =>
      '100 <150 <500 लक्स\nअसली गेम में परफेक्ट स्ट्रीक्स पॉवर हीट।';

  @override
  String get oracleDockStep1StrategyLine =>
      'पहला: एक सिल्हूट, तीन अलग-अलग रंग।';

  @override
  String get oracleDockStep2StrategyLine =>
      'यदि कोई परफेक्ट एक रत्न दूर है तो एक कमजोर ट्रिपल न लें।';

  @override
  String get oracleDockStep3StrategyLine =>
      'कमजोर आकार/रंग गर्मी को कम करता है - अपनी संपूर्ण श्रृंखला की योजना बनाएं।';

  @override
  String get oracleDockCelebrationStrategyLine =>
      'बाद में: गर्मी और टाइमर दोनों ही आपके जोखिम को आकार देते हैं।';

  @override
  String get tutorialTrinityShapeIntro => 'आकार संरचना है.उन्हें समूहित करें.';

  @override
  String get tutorialTrinityColorIntro => 'रंग सद्भाव है.यह अवसर पैदा करता है.';

  @override
  String get tutorialTrinityPerfectIntro =>
      'परफेक्ट मैच: पूर्ण मिलन।लक्स फटने को ट्रिगर करता है।चेनिंग परफेक्ट्स बड़े भुगतान के लिए हीट बनाता है।';

  @override
  String get narrativeFloatShapeBonus => '+100 लक्स : संरचना (आकार)';

  @override
  String get narrativeFloatColorBonus => '+150 लक्स : सद्भाव (रंग)';

  @override
  String get narrativeFloatPerfectBonus => '+500 लक्स : कुल प्रतिभा';

  @override
  String get gameNarrativePerfectMatchBanner => 'बिल्कुल सही मिलान';

  @override
  String get prepTitle => 'सत्र सेटअप';

  @override
  String get prepLuxScoreCaption => 'लक्स सिक्के';

  @override
  String get prepGuidedTutorialCasualOnly =>
      'इस ट्यूटोरियल के लिए केवल क्लासिक मोड उपलब्ध है।';

  @override
  String get prepGuidedTutorialGoalTitle => 'आप किस ओर निर्माण कर रहे हैं';

  @override
  String get prepGuidedTutorialGoalBody =>
      'प्रत्येक मैच इन-रन LUX जोड़ता है और आपके स्तर को बढ़ाता है।अधिक समृद्ध मिलान प्रकार—विशेष रूप से उत्तम—कमजोर त्रिगुणों की तुलना में कहीं अधिक भुगतान करते हैं।असली कौशल यह चुनना है कि आप कौन सा क्लियर लें और कब लें।\n\nपरफेक्ट मैचों को चेन करने से हीट बढ़ जाती है (वास्तविक रन में मीटर): उच्च स्तर प्रत्येक परफेक्ट पर लक्स जोड़ते हैं और समय को फिर से भर सकते हैं;कमजोर त्रिगुण इसे ठंडा कर देते हैं।';

  @override
  String get prepGuidedTutorialStrategyTitle => 'तीसरे रत्न से पहले सोचें';

  @override
  String get prepGuidedTutorialStrategyBody =>
      'इससे पहले कि आप तीसरा रत्न चुनें, अपना रैक पढ़ें: यदि आप तीन समान रत्नों (समान आकार और समान रंग) से एक रत्न दूर हैं, तो एक आसान रंग-केवल ट्रिपल को पकड़ने से सेटअप टूट सकता है और मेज पर बहुत सारा लक्स रह सकता है।\n\nइस वॉकथ्रू में टाइमर रुका रहता है ताकि आप शांति से अभ्यास कर सकें।असल में, प्रतीक्षा की एक कीमत होती है-दबाव और इनाम का समझौता।';

  @override
  String get prepModeCasualTitle => 'क्लासिक मोड';

  @override
  String prepModeCasualBody(int ante) {
    return 'हिस्सेदारी: $ante लक्स।निःशुल्क अभ्यास.';
  }

  @override
  String get prepModeHighStakesTitle => 'ऊंचे दांव';

  @override
  String prepModeHighStakesBody(int ante, int goal, int reward) {
    return 'हिस्सेदारी: $ante लक्स।लक्ष्य: स्तर $goal.इनाम: $reward लक्स।';
  }

  @override
  String get prepModeRoyalTitle => 'वेलोर रॉयल';

  @override
  String prepModeRoyalBody(int ante, int goal, int reward) {
    return 'हिस्सेदारी: $ante लक्स।लक्ष्य: स्तर $goal.इनाम: $reward लक्स।';
  }

  @override
  String get prepInsufficientLux => 'अपर्याप्त लक्स संतुलन.';

  @override
  String get prepConfirm => 'पुष्टि करें';

  @override
  String get prepBuyLux => 'लक्स खरीदें';

  @override
  String get prepSelectedChip => 'चयनित';

  @override
  String get leaderboardTitle => 'विश्व लीडरबोर्ड';

  @override
  String get leaderboardColRank => 'रैंक';

  @override
  String get leaderboardColPlayer => 'खिलाड़ी';

  @override
  String get leaderboardColScore => 'स्कोर';

  @override
  String leaderboardError(String details) {
    return 'लीडरबोर्ड अभी उपलब्ध नहीं है.\nअपना कनेक्शन या फायरस्टोर नियम जांचें।\n($details)';
  }

  @override
  String get leaderboardLoading => 'रैंकिंग लोड हो रही है...';

  @override
  String get leaderboardEmpty => 'अभी तक कोई अंक दर्ज नहीं किया गया.';

  @override
  String get leaderboardYourRankFooter => 'आपकी रैंक';

  @override
  String leaderboardPlayerAnon(String id) {
    return 'प्लेयर $id';
  }

  @override
  String get leaderboardPodiumFirst => 'प्रथम स्थान';

  @override
  String get leaderboardPodiumSecond => 'दूसरा स्थान';

  @override
  String get leaderboardPodiumThird => 'तीसरा स्थान';

  @override
  String get leaderboardPodiumOther => 'मंच';

  @override
  String gameFloatLuxGain(int gain) {
    return '+$gain लक्स';
  }

  @override
  String gameFloatLuxGainMult(int gain, String mult) {
    return '+$gain लक्स ×$mult';
  }

  @override
  String gameFloatPerfectGain(int gain) {
    return '+$gain उत्तम';
  }

  @override
  String gameFloatPerfectGainMult(int gain, String mult) {
    return '+$gain उत्तम ×$mult';
  }

  @override
  String gameFloatCombo(String mult) {
    return 'कॉम्बो ×$mult';
  }

  @override
  String get gameHudScore => 'स्कोर';

  @override
  String get gameHudTime => 'समय';

  @override
  String get gameHudPerfectHeatLabel => 'गरमी';

  @override
  String get gameHudPerfectHeatNearFloater => 'निकट';

  @override
  String get gameHudPerfectHeatRebound => 'पलटाव';

  @override
  String gameHudLevelShort(int level) {
    return 'एलवी $level';
  }

  @override
  String gameHudLuxAmount(int lux) {
    return '$lux लक्स';
  }

  @override
  String get gameHudLuxThisRun => 'यह दौड़';

  @override
  String get gameHudLevelTag => 'स्तर';

  @override
  String get gameHudLevelUpTitle => 'स्तर ऊपर!';

  @override
  String gameHudLevelUpSubtitle(int level) {
    return 'स्तर $level';
  }

  @override
  String get gameHudPerfectHeatSurgeTitle => 'गर्मी का बढ़ना';

  @override
  String gameHudPerfectHeatSurgeSubtitle(int heatTier) {
    return 'स्टेज $heatTier';
  }

  @override
  String gameHudPerfectHeatHudBonus(int luxPercent, String multLabel) {
    return '+$luxPercent% $multLabel';
  }

  @override
  String gameHudForgeChronoA11y(int count) {
    return 'क्रोनो रिजर्व, $count शुल्क';
  }

  @override
  String gameHudForgeMercyA11y(int count) {
    return 'ओरेकल दया, $count आरोप';
  }

  @override
  String get gameHudTimeResolvingA11y =>
      'कॉम्बो रिज़ॉल्यूशन, रत्नों को संक्षेप में लॉक किया गया।';

  @override
  String get settingsSectionAccessibility => 'गति और पहुंच';

  @override
  String get settingsAccessibilityBody =>
      'शांत दृश्यों और कम फ्लैश के लिए सिस्टम सेटिंग्स ऐप (एक्सेसिबिलिटी → मोशन) में \"रिड्यूस मोशन\" चालू करें।वेलोर स्वचालित रूप से इसका पता लगाता है।';

  @override
  String a11yGemButtonLabel(String shape, String color) {
    return '$shape, $color';
  }

  @override
  String get a11yGemShape1 => 'क्रिस्टल';

  @override
  String get a11yGemShape2 => 'गोला';

  @override
  String get a11yGemShape3 => 'पिरामिड';

  @override
  String get a11yGemShape4 => 'सितारा';

  @override
  String get a11yGemShape5 => 'हीरा';

  @override
  String get a11yGemShape6 => 'पेंटागन';

  @override
  String get a11yGemShape7 => 'षट्कोण तारा';

  @override
  String get a11yGemColor0 => 'सफ़ेद';

  @override
  String get a11yGemColor1 => 'सियान';

  @override
  String get a11yGemColor2 => 'सोना';

  @override
  String get a11yGemColor3 => 'मजेंटा';

  @override
  String get a11yGemColor4 => 'हरा';

  @override
  String get a11yGemColor5 => 'बैंगनी';

  @override
  String get a11yGemColor6 => 'नारंगी';

  @override
  String get a11yGemColor7 => 'पीला';

  @override
  String a11yRackSlotEmpty(int slot, int max) {
    return 'रैक स्लॉट $max में से $slot, खाली।';
  }

  @override
  String a11yRackSlotOccupied(int slot, int max) {
    return '$max में से रैक स्लॉट $slot पर कब्जा कर लिया गया।';
  }

  @override
  String get a11yRackSlotImminentHint => 'आसन्न जोड़ी लगभग पूरी हो गई है।';
}
