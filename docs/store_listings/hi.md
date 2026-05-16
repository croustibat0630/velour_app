# Velour — où coller ces textes (guide en français)

Les titres ## sont en hindi (ou translittération) ; les lignes *italiques* indiquent où coller, en français.

Les textes à publier sont en texte plat (sans `**` Markdown) pour un copier-coller direct vers Apple et Google.

Locale pour ce fichier : App Store Connect → Hindi · Play Console → hindi (ou hindi (Inde) selon les options).

### App Store Connect

1. [App Store Connect](https://appstoreconnect.apple.com) → Mes apps → Velour → App Store → version iOS → localisation Hindi.
2. Champs cibles : Name, Subtitle, Keywords, Promotional Text, Description, What’s New in This Version (libellés anglais courants dans l’interface Apple) — même emplacement que pour les autres langues.
3. Promotional Text : parfois modifiable sans nouvelle build.
4. What’s New in This Version : obligatoire par langue — voir section dédiée plus bas (adapter à chaque release ; réf. dépôt : 1.2.0+18).

### Google Play Console

1. [Play Console](https://play.google.com/console) → Velour → Présence sur le Play Store → Fiches principales du store → langue hindi → Titre, Courte description, Description complète.
2. Lors d’un déploiement de version (AAB) : étape Release notes par langue — voir section en fin de fichier.

---

# App Store Connect (हिन्दी — hi)

## नाम (30 वर्ण तक)

*Champ Name — nom public App Store (30 caractères max côté Apple ; compter en caractères / *glyphs* pour le devanagari selon la console).*

Velour: Luxury Sort & Stack

## उपशीर्षक (30 वर्ण तक)

*Champ Subtitle.*

नीयॉन लॉजिक • वैश्विक रैंक

## कीवर्ड (100 वर्ण तक, अंग्रेज़ी में अल्पविराम, अल्पविराम के बाद रिक्त स्थान नहीं)

*Champ Keywords — une ligne, mots-clés en anglais comme indiqué, virgules sans espace après.*

puzzle,strategy,neon,arcade,gems,LUX,leaderboard,perfect,skill,brain,logic,triple

## प्रचार पाठ (170 वर्ण तक, वैकल्पिक)

*Champ Promotional Text.*

जो दबाव में चमकते हैं: रैक पढ़ो, क्लियर चेन करो, घड़ी घिसने से पहले परफेक्ट पकड़ो। डार्क नीयॉन + लाइव वर्ल्ड रैंक—दिखाओ कि नर्व टूटते नहीं।

## विवरण (4000 वर्ण तक)

*Champ Description.*

रैक दिखता है। समय सौदा नहीं करता। Velour एक हाई‑स्किल नीयॉन पज़ल है, जो रन पर टिकता है: हर रखना लॉजिक पर दांव है—आकार/रंग क्लियर और परफेक्ट (तीन समान रत्न) जो स्कोर उछालता है और Heat भरता है ताकि ज़्यादा LUX और क्लच टाइम रिकवरी मिले। उन खिलाड़ियों के लिए जो पलक झपकते पहले सोचना चाहते हैं।

फिर से क्यों खेलोगे
• चुनौती पहले: पैटर्न तेज़ पढ़ो—अगर परफेक्ट एक रत्न दूर है तो “आसान” ट्रिपल मत लो।  
• खूबसूरती काम आए: डार्क‑मैट नीयॉन, साफ पढ़ने योग्य मोशन, सिस्टम कम मोशन का सम्मान।  
• दुनिया के सामने साबित करो: वर्ल्ड लीडरबोर्ड पर सर्वश्रेष्ठ रन; Oracle नाम जब ऐप कहे।

मोड
क्लासिक अभ्यास; हाई स्टेक्स / रॉयल जब जोखिम‑इनाम बढ़ाना हो।

प्रगति
शॉप में LUX से स्किन/बूस्ट; होम पर दैनिक LUX (योग्यता नियम)।

विश्वास
स्टोर बिल्ड में विश्लेषण/क्रैश रिपोर्टिंग संभव—लिंक की गई गोपनीयता नीति पढ़ें।

डाउनलोड करो अगर तुम्हें लॉजिक दबाव में, नीयॉन साफ़ सौंदर्य, और “एक और रन” चाहिए—फिर लीडरबोर्ड पर नाम दिखाओ।

## इस वर्ज़न में नया — App Store (हर भाषा में ज़रूरी)

*वही iOS वर्ज़न लोकलाइज़ेशन पेज जहाँ Name/Description होते हैं: What’s New in This Version। हर भाषा के लिए भरें। हर रिलीज़ पर अपडेट करें (रिपो संदर्भ: 1.2.0+18).*

• कोल्ड स्टार्ट और ऑनलाइन सिंक (प्रगति, लीडरबोर्ड) में बेहतर स्थिरता।
• बगफ़िक्स और प्रदर्शन सुधार।

---

# Google Play Console (हिन्दी)

*Play → Fiches principales du store → langue hindi (voir *Locale pour ce fichier*).*

## शीर्षक (30 वर्ण तक)

*Champ Title / Titre.*

Velour: Luxury Sort & Stack

## संक्षिप्त विवरण (80 वर्ण तक)

*Champ Short description.*

हाई‑स्किल नीयॉन पज़ल: परफेक्ट, LUX, वर्ल्ड रैंक—बार‑बार खेलने लायक।

## पूर्ण विवरण (4000 वर्ण तक)

*Champ Full description.*

बोर्ड परखता है। समय फैसला सुनाता है। Velour = नीयॉन पज़ल + स्ट्रैटेजी वाले रन: ट्रिपल, परफेक्ट, LUX, Heat—उन खिलाड़ियों के लिए जो तनाव में सोचना पसंद करते हैं।

गेमप्ले
आकार/रंग संतुलन; तीन समान = परफेक्ट + Heat. डार्क नीयॉन, फोकस, शोर नहीं।

प्रतिस्पर्धा
वर्ल्ड लीडरबोर्ड + Oracle नाम।

मोड
क्लासिक सेटअप; हाई स्टेक्स / रॉयल जोखिम।

LUX
स्किन, बूस्ट, दैनिक बोनस (नियम)।

गोपनीयता
लिंक की नीति देखें।

रैंक, साफ़ नीयॉन, कड़ी रन पसंद है? इंस्टॉल करो—और लीडरबोर्ड पर दावा छोड़ो।

## रिलीज़ नोट्स — Google Play (रिलीज़ करते समय)

*मुख्य स्टोर लिस्टिंग पेज पर नहीं: नई रिलीज़ बनाते समय AAB अपलोड के बाद Release notes चरण — इसी फ़ाइल वाली भाषा चुनें। कैरेक्टर लिमिट देखें।*

• कोल्ड स्टार्ट व ऑनलाइन सिंक स्थिरता; फिक्स व प्रदर्शन (v. 1.2.0)।
