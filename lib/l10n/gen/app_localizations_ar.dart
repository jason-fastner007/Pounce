// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Pounce';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navSearch => 'بحث';

  @override
  String get navLibrary => 'المكتبة';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingAfternoon => 'مساء الخير';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String get homeContinue => 'تابع الاستماع';

  @override
  String homeBecauseYouPlayed(String title) {
    return 'لأنك استمعت إلى $title';
  }

  @override
  String get errorLoading => 'تعذّر تحميل المحتوى';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get searchHint => 'أغانٍ أو فنانون أو قوائم تشغيل أو روابط';

  @override
  String get searchRecent => 'عمليات البحث الأخيرة';

  @override
  String get searchEmptyTitle => 'ابحث عن شيء لتشغيله';

  @override
  String get tabTracks => 'المقاطع';

  @override
  String get tabPlaylists => 'قوائم التشغيل';

  @override
  String get tabAlbums => 'الألبومات';

  @override
  String get tabArtists => 'الفنانون';

  @override
  String get likedTracks => 'المقاطع المفضلة';

  @override
  String get history => 'السجل';

  @override
  String get playlists => 'قوائم التشغيل';

  @override
  String get newPlaylist => 'قائمة تشغيل جديدة';

  @override
  String get playlistName => 'الاسم';

  @override
  String get create => 'إنشاء';

  @override
  String get cancel => 'إلغاء';

  @override
  String get rename => 'إعادة التسمية';

  @override
  String get delete => 'حذف';

  @override
  String deletePlaylistConfirm(String name) {
    return 'حذف \"$name\"؟';
  }

  @override
  String get clearHistory => 'مسح السجل';

  @override
  String get emptyLikes => 'تظهر هنا المقاطع التي تعجبك';

  @override
  String get emptyHistory => 'لم يتم تشغيل أي شيء بعد';

  @override
  String get emptyPlaylist => 'قائمة التشغيل هذه فارغة';

  @override
  String get emptyPlaylists => 'أنشئ قوائم تشغيل وأضف مقاطع عبر القائمة ⋮.';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقطع',
      many: '$count مقطعًا',
      few: '$count مقاطع',
      two: 'مقطعان',
      one: 'مقطع واحد',
      zero: 'لا توجد مقاطع',
    );
    return '$_temp0';
  }

  @override
  String followers(String count) {
    return '$count متابع';
  }

  @override
  String get playNext => 'التشغيل التالي';

  @override
  String get addToQueue => 'إضافة إلى قائمة الانتظار';

  @override
  String get addToPlaylist => 'إضافة إلى قائمة تشغيل';

  @override
  String get removeFromPlaylist => 'إزالة من قائمة التشغيل';

  @override
  String get like => 'إعجاب';

  @override
  String get unlike => 'إزالة من المفضلة';

  @override
  String get goToArtist => 'الانتقال إلى الفنان';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get linkCopied => 'تم نسخ الرابط';

  @override
  String get addedToQueue => 'تمت الإضافة إلى قائمة الانتظار';

  @override
  String addedToPlaylist(String name) {
    return 'تمت الإضافة إلى $name';
  }

  @override
  String alreadyInPlaylist(String name) {
    return 'موجود بالفعل في $name';
  }

  @override
  String get nowPlaying => 'قيد التشغيل الآن';

  @override
  String get queue => 'قائمة الانتظار';

  @override
  String get lyrics => 'الكلمات';

  @override
  String get noLyrics => 'لم يتم العثور على كلمات';

  @override
  String lyricsSource(String source) {
    return 'الكلمات: $source';
  }

  @override
  String get sleepTimer => 'مؤقت النوم';

  @override
  String get sleepOff => 'إيقاف المؤقت';

  @override
  String sleepIn(int minutes) {
    return 'يتوقف بعد $minutes د';
  }

  @override
  String minutes(int count) {
    return '$count دقيقة';
  }

  @override
  String get speed => 'السرعة';

  @override
  String get shuffle => 'ترتيب عشوائي';

  @override
  String get repeatOff => 'التكرار متوقف';

  @override
  String get repeatAll => 'تكرار الكل';

  @override
  String get repeatOne => 'تكرار مقطع واحد';

  @override
  String get play => 'تشغيل';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get next => 'التالي';

  @override
  String get previous => 'السابق';

  @override
  String get popularTracks => 'الأكثر شعبية';

  @override
  String get playbackError => 'تعذّر تشغيل هذا المقطع';

  @override
  String get preview => 'معاينة';

  @override
  String get protected => 'محمي';

  @override
  String get protectedHint =>
      'هذا المقطع محمي بإدارة الحقوق الرقمية ولا يمكن لـ Pounce تشغيله بعد، حتى بعد تسجيل الدخول';

  @override
  String get protectedPlayable => 'محمي بإدارة الحقوق الرقمية – تفك وحدة DRM في متصفحك تشفيره';

  @override
  String get account => 'الحساب';

  @override
  String get login => 'تسجيل الدخول عبر SoundCloud';

  @override
  String get loginSubtitle => 'مزامنة الإعجابات وقوائم التشغيل وبثّك';

  @override
  String get signup => 'إنشاء حساب';

  @override
  String get loginPrivacy => 'يتم تسجيل الدخول على صفحة SoundCloud نفسها، ولا يرى Pounce كلمة مرورك أبدًا.';

  @override
  String get loginWaiting => 'أكمل تسجيل الدخول في المتصفح…';

  @override
  String get loginReopen => 'فتح مرة أخرى';

  @override
  String get loginPasteLabel => 'الصق رابط إعادة التوجيه';

  @override
  String get loginPasteHint =>
      'بعد تسجيل الدخول يعيد SoundCloud التوجيه إلى رابط يبدأ بـ sc://auth?code=… إذا لم يستلمه التطبيق تلقائيًا فالصقه هنا.';

  @override
  String get loginPasteHintWeb =>
      'ستُفتح علامة تبويب جديدة. بعد تسجيل الدخول سيظهر عنوان مثل soundcloud.com/signin/callback?code=… انسخ هذا العنوان والصقه هنا.';

  @override
  String get loginConfirm => 'متابعة';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String loggedInAs(String name) {
    return 'تم تسجيل الدخول باسم $name';
  }

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirm => 'تسجيل الخروج؟ ستبقى إعجاباتك على هذا الجهاز.';

  @override
  String get homeStream => 'بثّك';

  @override
  String get scPlaylists => 'قوائم تشغيل SoundCloud الخاصة بك';

  @override
  String transferLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نقل $count إعجاب محلي إلى حسابك؟',
      many: 'نقل $count إعجابًا محليًا إلى حسابك؟',
      few: 'نقل $count إعجابات محلية إلى حسابك؟',
      two: 'نقل إعجابين محليين إلى حسابك؟',
      one: 'نقل إعجاب محلي واحد إلى حسابك؟',
      zero: 'لا توجد إعجابات محلية',
    );
    return '$_temp0';
  }

  @override
  String get transfer => 'نقل';

  @override
  String get notNow => 'ليس الآن';

  @override
  String get loudTitle => 'وضع الصوت';

  @override
  String get loudDesc => 'يوازن بين المقاطع العالية والمنخفضة (ITU-R BS.1770) مع محدِّد مدمج ضد التشويه.';

  @override
  String get loudOff => 'إيقاف';

  @override
  String get loudQuiet => 'منخفض';

  @override
  String get loudNormal => 'عادي';

  @override
  String get loudLoud => 'مرتفع';

  @override
  String get loudUnsupported => 'غير متاح على هذه المنصة بعد';

  @override
  String get signal => 'الإشارة';

  @override
  String get sigSource => 'المصدر';

  @override
  String get sigLoudness => 'جهارة المصدر';

  @override
  String get sigMomentary => 'لحظي';

  @override
  String get sigGain => 'الكسب';

  @override
  String get sigLimiter => 'المحدِّد';

  @override
  String get sigOutput => 'المخرج';

  @override
  String get sigAnalysis => 'التحليل';

  @override
  String get sigLive => 'FFT مباشر';

  @override
  String get sigEnvelope => 'غلاف الموجة';

  @override
  String get sigClip => 'تشويه';

  @override
  String get sigClean => 'نظيف';

  @override
  String get volume => 'مستوى الصوت';

  @override
  String get mute => 'كتم';

  @override
  String get inspector => 'لوحة التفاصيل';

  @override
  String get expandPlayer => 'عرض التركيز';

  @override
  String get expandRail => 'توسيع الشريط';

  @override
  String get collapseRail => 'طي الشريط';

  @override
  String get accentAmber => 'كهرماني';

  @override
  String get accentCyan => 'سماوي بارد';

  @override
  String get accentCover => 'من الغلاف';

  @override
  String get beatBg => 'خلفية مع الإيقاع';

  @override
  String get beatBgDesc => 'تنبض الألوان وتتغير مع كل نبضة مكتشفة';

  @override
  String get beatLight => 'خفيف';

  @override
  String get beatMedium => 'متوسط';

  @override
  String get beatStrong => 'قوي';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get pureBlack => 'أسود خالص';

  @override
  String get pureBlackDesc => 'خلفية سوداء في الوضع الداكن (OLED)';

  @override
  String get dynamicColor => 'ألوان النظام';

  @override
  String get dynamicColorDesc => 'استخدام لون التمييز الخاص بالنظام';

  @override
  String get artworkColors => 'ألوان من الغلاف';

  @override
  String get artworkColorsDesc => 'يكيّف المشغل ألوانه وفقًا للغلاف';

  @override
  String get accentColor => 'لون التمييز';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'لغة النظام';

  @override
  String get playback => 'التشغيل';

  @override
  String get quality => 'جودة البث';

  @override
  String get qualityHigh => 'عالية';

  @override
  String get qualitySaver => 'توفير البيانات';

  @override
  String get autoplay => 'التشغيل التلقائي';

  @override
  String get autoplayDesc => 'متابعة تشغيل مقاطع مشابهة عند انتهاء قائمة الانتظار';

  @override
  String get network => 'الشبكة';

  @override
  String get proxy => 'وكيل CORS';

  @override
  String get proxyDesc => 'مطلوب في المتصفح لأن SoundCloud لا يسمح إلا بموقعه الخاص.';

  @override
  String get about => 'حول';

  @override
  String get aboutText => 'مستوحى من KittyTune (alan7383) ومكتوب من الصفر بـ Flutter. برنامج حر بترخيص GPL-3.0.';

  @override
  String get licenses => 'تراخيص المصادر المفتوحة';

  @override
  String get previewBadge => 'معاينة (30 ث)';

  @override
  String get previewHint => 'لا يقدّم SoundCloud سوى معاينة مدتها 30 ثانية لهذا المقطع.';

  @override
  String get openInYtMusic => 'فتح في YouTube Music';

  @override
  String get skipPreviews => 'تخطي المعاينات';

  @override
  String get skipPreviewsDesc => 'تخطي معاينات الثلاثين ثانية عند الانتقال في قائمة الانتظار';

  @override
  String get fastStart => 'بدء سريع';

  @override
  String get fastStartDesc =>
      'تبدأ المقاطع المختارة بصيغة MP3 بمعدل 128 كيلوبت/ث – أسرع مع جودة أقل قليلًا. تحتفظ المقاطع المحمّلة مسبقًا بالجودة المختارة.';

  @override
  String get navDj => 'دي جي';

  @override
  String get djHeadline => 'الدي جي الخاص بك';

  @override
  String get djIntro =>
      'اختر ما تريد سماعه – يمزج Pounce إعجاباتك ومقاطع مشابهة بانتقالات متوافقة مع المقام والإيقاع والدروب.';

  @override
  String get djCategories => 'الفئات';

  @override
  String get djBlend => 'المزيج';

  @override
  String get djFavorites => 'المفضلة';

  @override
  String get djDiscover => 'اكتشاف';

  @override
  String get djLookahead => 'تحليل مسبق';

  @override
  String djLookaheadDesc(int count, int mb) {
    return '$count مقطعًا مسبقًا (~$mb م.ب)';
  }

  @override
  String get djStart => 'ابدأ المزج';

  @override
  String get djBuilding => 'جارٍ إنشاء المزج…';

  @override
  String get djNothing => 'لم يُعثر على شيء مناسب – جرّب فئة أخرى.';

  @override
  String get djPickCategory => 'اختر فئة واحدة على الأقل';

  @override
  String djAnalyzed(int done, int total) {
    return 'تم تحليل $done من $total';
  }

  @override
  String djMixStarted(int count) {
    return 'بدأ مزج من $count مقطعًا';
  }

  @override
  String get djStop => 'إيقاف الدي جي';

  @override
  String get djSkip => 'تخطٍّ (مزج سلس وتعلّم)';

  @override
  String get srcAll => 'الكل';

  @override
  String get srcRadio => 'راديو الويب';

  @override
  String get radioSection => 'بث مباشر · محطات';

  @override
  String get radioFavorites => 'المحطات المفضلة';

  @override
  String get radioTop => 'الأكثر استماعًا';

  @override
  String get radioAll => 'كل المحطات';

  @override
  String get radioSource => 'راديو الويب';

  @override
  String get radioSourceDesc => 'عشرات الآلاف من المحطات من radio-browser.info. عند الإيقاف: لا طلبات إطلاقًا.';

  @override
  String get live => 'مباشر';

  @override
  String get updates => 'التحديثات';

  @override
  String get updatesAuto => 'البحث عن التحديثات تلقائيًا';

  @override
  String get updatesAutoDesc =>
      'مرة واحدة يوميًا كحد أقصى، طلب واحد إلى GitHub دون أي معرّف للجهاز. لا يُنزّل شيئًا من تلقاء نفسه.';

  @override
  String get updatesCheck => 'تحقّق الآن';

  @override
  String get updatesNone => 'Pounce محدّث';

  @override
  String get updatesUnavailable => 'التحديثات غير متاحة في هذا الإصدار';

  @override
  String updateTitle(String version) {
    return 'تحديث إلى $version';
  }

  @override
  String updateDownload(String mb) {
    return 'تنزيل وتثبيت ($mb م.ب)';
  }

  @override
  String get updateViaPlay => 'التحديث عبر Google Play';

  @override
  String get updateLater => 'لاحقًا';

  @override
  String get updateReleasePage => 'صفحة الإصدار';

  @override
  String get updateChecksumFailed => 'المجموع الاختباري غير مطابق – تم حذف التنزيل.';

  @override
  String get updateNeedsPermission => 'اسمح لـ Pounce بتثبيت التطبيقات ثم اضغط مجددًا.';

  @override
  String get updateFailed => 'فشل التحديث – حاول لاحقًا.';

  @override
  String get beta => 'تجريبي';

  @override
  String get betaNote => 'Pounce في مرحلة تجريبية. قد تتغير بعض الأشياء أو تتعطل – ملاحظاتك على GitHub مرحب بها.';

  @override
  String get setupWelcome => 'مرحبًا بك في Pounce';

  @override
  String get setupTagline => 'موسيقى سريعة من SoundCloud والراديو عبر الإنترنت – مع دي جي يمزج لك.';

  @override
  String get setupStart => 'لنبدأ';

  @override
  String get setupNext => 'التالي';

  @override
  String get setupBack => 'رجوع';

  @override
  String get setupSkip => 'تخطي الإعداد';

  @override
  String get setupDone => 'ابدأ الاستماع';

  @override
  String get setupSourcesTitle => 'من أين تأتي الموسيقى؟';

  @override
  String get setupSoundcloudDesc => 'ملايين المقاطع والمزجات والريمكسات. مفعّل دائمًا.';

  @override
  String get setupRadioDesc => 'أكثر من 30,000 محطة عبر radio-browser.info. إيقاف = لا طلبات إطلاقًا.';

  @override
  String get setupAccountTitle => 'هل تريد جلب إعجاباتك؟';

  @override
  String get setupAccountDesc =>
      'اختياري: سجّل الدخول إلى SoundCloud لاستيراد الإعجابات وقوائم التشغيل. يعمل Pounce أيضًا بدون حساب.';

  @override
  String get setupSignIn => 'تسجيل الدخول إلى SoundCloud';

  @override
  String get setupDjTitle => 'ماذا يشغّل الدي جي الخاص بك؟';

  @override
  String get setupDjDesc => 'اختر بعض الأنماط. يمكنك تغييرها في أي وقت من تبويب DJ.';

  @override
  String get setupPrivacyTitle => 'خصوصيتك';

  @override
  String get setupPrivacyDesc => 'لا تتبّع ولا إعلانات ولا معرّفات للجهاز. كل ما يلي معطّل حتى تفعّله.';

  @override
  String get setupRecognition => 'التعرّف على الأغاني (Echolot)';

  @override
  String get setupRecognitionDesc =>
      'سيتوفر في إصدار تجريبي لاحق. يرسل فقط بصمات صوتية مجهولة – وليس تسجيلات أبدًا – إلى خادم Echolot.';

  @override
  String get setupAgain => 'إعادة تشغيل الإعداد';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }

  @override
  String syncLast(int count) {
    return 'تمت المزامنة ($count أحداث جديدة)';
  }

  @override
  String get syncTitle => 'مزامنة الأجهزة';

  @override
  String get syncBackground => 'المزامنة في الخلفية';

  @override
  String syncServerActive(int port) {
    return 'الخادم نشط (المنفذ $port) · نظير لنظير على شبكتك المحلية';
  }

  @override
  String get syncDisabled => 'متوقف';

  @override
  String get syncShowCode => 'عرض رمز الاقتران';

  @override
  String get syncShowCodeDesc => 'رمز لأجهزتك الأخرى';

  @override
  String get syncCodeTitle => 'رمز الاقتران';

  @override
  String get syncCodeHint => 'أدخل هذا الرمز على جهازك الآخر:';

  @override
  String get syncCodeCopied => 'تم نسخ رمز الاقتران';

  @override
  String get copy => 'نسخ';

  @override
  String get done => 'تم';

  @override
  String get syncPair => 'إقران جهاز';

  @override
  String get syncNoPeers => 'لا يوجد جهاز آخر متصل';

  @override
  String syncPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أجهزة مقترنة',
      one: 'جهاز واحد مقترن',
    );
    return '$_temp0';
  }

  @override
  String get syncPasteCode => 'الصق رمز الاقتران';

  @override
  String get syncPairAction => 'إقران';

  @override
  String get syncPaired => 'تم الاقتران!';

  @override
  String get syncPairFailed => 'فشل الاقتران';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String get syncNever => 'لم تتم المزامنة بعد';

  @override
  String get syncDone => 'تمت المزامنة';

  @override
  String get engineTitle => 'محرك الصوت والأداء';

  @override
  String engineRustDesc(String label) {
    return '$label · شبكة الإيقاع والمقام (كروما) وشدة الصوت وبصمة الذكاء الاصطناعي من الصوت الحقيقي';
  }

  @override
  String get engineUnavailable => 'غير متاح – تقدير من شكل الموجة فقط';

  @override
  String get djFlowActiveDesc => 'مطابقة تلقائية للجمل والمقام';

  @override
  String get djFlowAutomix => 'DJ Flow & Automix';

  @override
  String get djBpm => 'BPM';

  @override
  String get djTapToActivate => 'اضغط للتفعيل';

  @override
  String get djAnalyzing => 'جارٍ تحليل الصوت…';

  @override
  String get djNoKey => 'لم يُكتشف مقام';

  @override
  String get djKeyUncertain => 'غير مؤكد';

  @override
  String djBar(int bar) {
    return 'المازورة $bar/4';
  }

  @override
  String djPhraseBeat(int beat) {
    return 'نبضة الجملة $beat/16';
  }

  @override
  String get statGrid => 'الشبكة';

  @override
  String get statKey => 'المقام';

  @override
  String get statLoudness => 'شدة الصوت';

  @override
  String get statEnergy => 'الطاقة';

  @override
  String get statSource => 'المصدر';

  @override
  String get srcAudio => 'الصوت';

  @override
  String get srcWaveform => 'شكل الموجة';

  @override
  String get srcTitle => 'العنوان';

  @override
  String get djEnergiesLive => 'طاقات الصوت (مباشر)';

  @override
  String djTransitionIn(int beats) {
    return 'انتقال بعد $beats نبضات';
  }

  @override
  String get djEnergyMode => 'وضع الطاقة التوافقي';

  @override
  String get djModeBuildUp => 'تصاعد';

  @override
  String get djModeHold => 'ثبات';

  @override
  String get djModeWindDown => 'تهدئة';

  @override
  String get djHarmonic => 'توافقي';

  @override
  String get djNextBest => 'المقطع التالي (أفضل تطابق)';

  @override
  String djMatch(String pct) {
    return 'تطابق $pct%';
  }

  @override
  String get djMixNow => 'امزج الآن';

  @override
  String get bandBass => 'الجهير (الركلة والسب)';

  @override
  String get bandMid => 'الوسط (الغناء واللحن)';

  @override
  String get bandHigh => 'الحاد (الصنج والهواء)';

  @override
  String planDrop(String time) {
    return 'الذروة $time';
  }

  @override
  String get planNoDrop => 'لا ذروة';

  @override
  String get planSearching => 'جارٍ البحث عن الذروة…';

  @override
  String planText(String entry, String drop, String fade) {
    return 'الدخول $entry · $drop · تلاشٍ $fade ث';
  }
}
