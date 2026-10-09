// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Pounce';

  @override
  String get navHome => 'Главная';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navLibrary => 'Медиатека';

  @override
  String get navSettings => 'Настройки';

  @override
  String get greetingMorning => 'Доброе утро';

  @override
  String get greetingAfternoon => 'Добрый день';

  @override
  String get greetingEvening => 'Добрый вечер';

  @override
  String get homeContinue => 'Продолжить';

  @override
  String homeBecauseYouPlayed(String title) {
    return 'Потому что вы слушали $title';
  }

  @override
  String get errorLoading => 'Не удалось загрузить';

  @override
  String get retry => 'Повторить';

  @override
  String get noResults => 'Ничего не найдено';

  @override
  String get searchHint => 'Треки, исполнители, плейлисты или ссылки';

  @override
  String get searchRecent => 'Недавние запросы';

  @override
  String get searchEmptyTitle => 'Найдите, что послушать';

  @override
  String get tabTracks => 'Треки';

  @override
  String get tabPlaylists => 'Плейлисты';

  @override
  String get tabAlbums => 'Альбомы';

  @override
  String get tabArtists => 'Исполнители';

  @override
  String get likedTracks => 'Любимые треки';

  @override
  String get history => 'История';

  @override
  String get playlists => 'Плейлисты';

  @override
  String get newPlaylist => 'Новый плейлист';

  @override
  String get playlistName => 'Название';

  @override
  String get create => 'Создать';

  @override
  String get cancel => 'Отмена';

  @override
  String get rename => 'Переименовать';

  @override
  String get delete => 'Удалить';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get clearHistory => 'Очистить историю';

  @override
  String get emptyLikes => 'Здесь появятся понравившиеся треки';

  @override
  String get emptyHistory => 'Вы ещё ничего не слушали';

  @override
  String get emptyPlaylist => 'Плейлист пуст';

  @override
  String get emptyPlaylists => 'Создавайте плейлисты и добавляйте треки через меню ⋮.';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count трека',
      many: '$count треков',
      few: '$count трека',
      one: '$count трек',
      zero: 'Нет треков',
    );
    return '$_temp0';
  }

  @override
  String followers(String count) {
    return 'Подписчики: $count';
  }

  @override
  String get playNext => 'Играть следующим';

  @override
  String get addToQueue => 'Добавить в очередь';

  @override
  String get addToPlaylist => 'Добавить в плейлист';

  @override
  String get removeFromPlaylist => 'Удалить из плейлиста';

  @override
  String get like => 'Нравится';

  @override
  String get unlike => 'Убрать из любимых';

  @override
  String get goToArtist => 'Перейти к исполнителю';

  @override
  String get copyLink => 'Копировать ссылку';

  @override
  String get linkCopied => 'Ссылка скопирована';

  @override
  String get addedToQueue => 'Добавлено в очередь';

  @override
  String addedToPlaylist(String name) {
    return 'Добавлено в «$name»';
  }

  @override
  String alreadyInPlaylist(String name) {
    return 'Уже в «$name»';
  }

  @override
  String get nowPlaying => 'Сейчас играет';

  @override
  String get queue => 'Очередь';

  @override
  String get lyrics => 'Текст';

  @override
  String get noLyrics => 'Текст не найден';

  @override
  String lyricsSource(String source) {
    return 'Текст: $source';
  }

  @override
  String get sleepTimer => 'Таймер сна';

  @override
  String get sleepOff => 'Выключить таймер';

  @override
  String sleepIn(int minutes) {
    return 'Остановка через $minutes мин';
  }

  @override
  String minutes(int count) {
    return '$count мин';
  }

  @override
  String get speed => 'Скорость';

  @override
  String get shuffle => 'Перемешать';

  @override
  String get repeatOff => 'Повтор выключен';

  @override
  String get repeatAll => 'Повторять все';

  @override
  String get repeatOne => 'Повторять один';

  @override
  String get play => 'Играть';

  @override
  String get pause => 'Пауза';

  @override
  String get next => 'Следующий';

  @override
  String get previous => 'Предыдущий';

  @override
  String get popularTracks => 'Популярное';

  @override
  String get playbackError => 'Не удаётся воспроизвести трек';

  @override
  String get preview => 'Превью';

  @override
  String get protected => 'Защищено';

  @override
  String get protectedHint => 'Трек защищён DRM и пока не воспроизводится в Pounce – даже после входа';

  @override
  String get protectedPlayable => 'Защищено DRM – расшифровывается DRM-модулем браузера';

  @override
  String get account => 'Аккаунт';

  @override
  String get login => 'Войти через SoundCloud';

  @override
  String get loginSubtitle => 'Синхронизация лайков, плейлистов и ленты';

  @override
  String get signup => 'Создать аккаунт';

  @override
  String get loginPrivacy => 'Вход происходит на странице SoundCloud. Pounce не видит ваш пароль.';

  @override
  String get loginWaiting => 'Завершите вход в браузере…';

  @override
  String get loginReopen => 'Открыть снова';

  @override
  String get loginPasteLabel => 'Вставьте ссылку перенаправления';

  @override
  String get loginPasteHint =>
      'После входа SoundCloud перенаправляет на ссылку sc://auth?code=… Если приложение не получило её автоматически, вставьте её сюда.';

  @override
  String get loginPasteHintWeb =>
      'Откроется новая вкладка. После входа в ней будет адрес вида soundcloud.com/signin/callback?code=… Скопируйте этот адрес и вставьте сюда.';

  @override
  String get loginConfirm => 'Продолжить';

  @override
  String get loginFailed => 'Не удалось войти';

  @override
  String loggedInAs(String name) {
    return 'Вы вошли как $name';
  }

  @override
  String get logout => 'Выйти';

  @override
  String get logoutConfirm => 'Выйти? Лайки останутся на этом устройстве.';

  @override
  String get homeStream => 'Ваша лента';

  @override
  String get scPlaylists => 'Ваши плейлисты SoundCloud';

  @override
  String transferLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Перенести $count локальных лайка в аккаунт?',
      many: 'Перенести $count локальных лайков в аккаунт?',
      few: 'Перенести $count локальных лайка в аккаунт?',
      one: 'Перенести $count локальный лайк в аккаунт?',
    );
    return '$_temp0';
  }

  @override
  String get transfer => 'Перенести';

  @override
  String get notNow => 'Не сейчас';

  @override
  String get loudTitle => 'Режим громкости';

  @override
  String get loudDesc =>
      'Выравнивает громкие и тихие треки (ITU-R BS.1770), встроенный лимитер защищает от перегрузки.';

  @override
  String get loudOff => 'Выкл.';

  @override
  String get loudQuiet => 'Тихо';

  @override
  String get loudNormal => 'Норма';

  @override
  String get loudLoud => 'Громко';

  @override
  String get loudUnsupported => 'Пока недоступно на этой платформе';

  @override
  String get signal => 'Сигнал';

  @override
  String get sigSource => 'Источник';

  @override
  String get sigLoudness => 'Громкость источника';

  @override
  String get sigMomentary => 'Мгновенная';

  @override
  String get sigGain => 'Усиление';

  @override
  String get sigLimiter => 'Лимитер';

  @override
  String get sigOutput => 'Выход';

  @override
  String get sigAnalysis => 'Анализ';

  @override
  String get sigLive => 'FFT в реальном времени';

  @override
  String get sigEnvelope => 'Огибающая волны';

  @override
  String get sigClip => 'Перегрузка';

  @override
  String get sigClean => 'Чисто';

  @override
  String get volume => 'Громкость';

  @override
  String get mute => 'Без звука';

  @override
  String get inspector => 'Инспектор';

  @override
  String get expandPlayer => 'Режим фокуса';

  @override
  String get expandRail => 'Развернуть панель';

  @override
  String get collapseRail => 'Свернуть панель';

  @override
  String get accentAmber => 'Электро-янтарь';

  @override
  String get accentCyan => 'Крио-циан';

  @override
  String get accentCover => 'Из обложки';

  @override
  String get beatBg => 'Фон в такт музыке';

  @override
  String get beatBgDesc => 'Цвета пульсируют и меняются на каждой доле';

  @override
  String get beatLight => 'Слабо';

  @override
  String get beatMedium => 'Средне';

  @override
  String get beatStrong => 'Сильно';

  @override
  String get appearance => 'Оформление';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get pureBlack => 'Чисто чёрный';

  @override
  String get pureBlackDesc => 'Чёрный фон в тёмной теме (OLED)';

  @override
  String get dynamicColor => 'Системные цвета';

  @override
  String get dynamicColorDesc => 'Использовать акцентный цвет системы';

  @override
  String get artworkColors => 'Цвета обложки';

  @override
  String get artworkColorsDesc => 'Плеер подстраивает цвета под обложку';

  @override
  String get accentColor => 'Акцентный цвет';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Язык системы';

  @override
  String get playback => 'Воспроизведение';

  @override
  String get quality => 'Качество потока';

  @override
  String get qualityHigh => 'Высокое';

  @override
  String get qualitySaver => 'Экономия трафика';

  @override
  String get autoplay => 'Автовоспроизведение';

  @override
  String get autoplayDesc => 'Продолжать похожими треками после очереди';

  @override
  String get network => 'Сеть';

  @override
  String get proxy => 'CORS-прокси';

  @override
  String get proxyDesc => 'Нужен в браузере: SoundCloud разрешает запросы только со своего сайта.';

  @override
  String get about => 'О приложении';

  @override
  String get aboutText => 'Вдохновлено KittyTune (alan7383), написано с нуля на Flutter. Свободное ПО под GPL-3.0.';

  @override
  String get licenses => 'Лицензии открытого ПО';

  @override
  String get previewBadge => 'Превью (30 с)';

  @override
  String get previewHint => 'SoundCloud предлагает только 30-секундное превью этого трека.';

  @override
  String get openInYtMusic => 'Открыть в YouTube Music';

  @override
  String get skipPreviews => 'Пропускать превью';

  @override
  String get skipPreviewsDesc => 'Пропускать 30-секундные превью при переходе по очереди';

  @override
  String get fastStart => 'Быстрый старт';

  @override
  String get fastStartDesc =>
      'Выбранные треки запускаются как MP3 128 кбит/с – быстрее, чуть ниже качество. Предзагруженные треки сохраняют выбранное качество.';

  @override
  String get navDj => 'DJ';

  @override
  String get djHeadline => 'Твой диджей';

  @override
  String get djIntro =>
      'Выбери, что хочешь слушать, – Pounce сведёт твои лайки и похожие треки с переходами по тональности, темпу и дропу.';

  @override
  String get djCategories => 'Категории';

  @override
  String get djBlend => 'Смесь';

  @override
  String get djFavorites => 'Избранное';

  @override
  String get djDiscover => 'Новое';

  @override
  String get djLookahead => 'Анализ заранее';

  @override
  String djLookaheadDesc(int count, int mb) {
    return '$count треков заранее (~$mb МБ)';
  }

  @override
  String get djStart => 'Запустить микс';

  @override
  String get djBuilding => 'Собираем микс…';

  @override
  String get djNothing => 'Ничего не найдено – попробуй другую категорию.';

  @override
  String get djPickCategory => 'Выбери хотя бы одну категорию';

  @override
  String djAnalyzed(int done, int total) {
    return 'Проанализировано $done из $total';
  }

  @override
  String djMixStarted(int count) {
    return 'Микс из $count треков запущен';
  }

  @override
  String get djStop => 'Выключить DJ';

  @override
  String get djSkip => 'Пропустить (свести и запомнить)';

  @override
  String get srcAll => 'Все';

  @override
  String get srcRadio => 'Радио';

  @override
  String get radioSection => 'Прямой эфир · Станции';

  @override
  String get radioFavorites => 'Любимые станции';

  @override
  String get radioTop => 'Самые популярные';

  @override
  String get radioAll => 'Все станции';

  @override
  String get radioSource => 'Интернет-радио';

  @override
  String get radioSourceDesc => 'Десятки тысяч станций с radio-browser.info. Выкл.: ни одного запроса.';

  @override
  String get live => 'ЭФИР';

  @override
  String get updates => 'Обновления';

  @override
  String get updatesAuto => 'Проверять обновления автоматически';

  @override
  String get updatesAutoDesc => 'Не чаще раза в день, один запрос к GitHub без ID устройства. Сам ничего не скачивает.';

  @override
  String get updatesCheck => 'Проверить';

  @override
  String get updatesNone => 'Pounce обновлён';

  @override
  String get updatesUnavailable => 'В этой сборке обновления недоступны';

  @override
  String updateTitle(String version) {
    return 'Обновление до $version';
  }

  @override
  String updateDownload(String mb) {
    return 'Скачать и установить ($mb МБ)';
  }

  @override
  String get updateViaPlay => 'Обновить через Google Play';

  @override
  String get updateLater => 'Позже';

  @override
  String get updateReleasePage => 'Страница релиза';

  @override
  String get updateChecksumFailed => 'Контрольная сумма не совпала – загрузка удалена.';

  @override
  String get updateNeedsPermission => 'Разреши Pounce устанавливать приложения и нажми снова.';

  @override
  String get updateFailed => 'Не удалось обновить – попробуй позже.';

  @override
  String get beta => 'Бета';

  @override
  String get betaNote =>
      'Pounce в бета-версии. Что-то может меняться или ломаться – отзывы на GitHub очень приветствуются.';

  @override
  String get setupWelcome => 'Добро пожаловать в Pounce';

  @override
  String get setupTagline => 'Быстрая музыка из SoundCloud и интернет-радио – с диджеем, который сводит для вас.';

  @override
  String get setupStart => 'Поехали';

  @override
  String get setupNext => 'Далее';

  @override
  String get setupBack => 'Назад';

  @override
  String get setupSkip => 'Пропустить настройку';

  @override
  String get setupDone => 'Начать слушать';

  @override
  String get setupSourcesTitle => 'Откуда брать музыку?';

  @override
  String get setupSoundcloudDesc => 'Миллионы треков, миксов и ремиксов. Всегда включено.';

  @override
  String get setupRadioDesc => 'Более 30 000 станций через radio-browser.info. Выкл. = ни одного запроса.';

  @override
  String get setupAccountTitle => 'Перенести ваши лайки?';

  @override
  String get setupAccountDesc =>
      'По желанию: войдите в SoundCloud, чтобы перенести лайки и плейлисты. Pounce работает и без аккаунта.';

  @override
  String get setupSignIn => 'Войти в SoundCloud';

  @override
  String get setupDjTitle => 'Что будет играть ваш диджей?';

  @override
  String get setupDjDesc => 'Выберите несколько стилей. Их можно изменить во вкладке DJ.';

  @override
  String get setupPrivacyTitle => 'Ваша конфиденциальность';

  @override
  String get setupPrivacyDesc => 'Без трекинга, рекламы и ID устройства. Всё ниже выключено, пока вы сами не включите.';

  @override
  String get setupRecognition => 'Распознавание песен (Echolot)';

  @override
  String get setupRecognitionDesc =>
      'Появится в следующей бете. Отправляет на сервер Echolot только анонимные аудиоотпечатки – никогда записи.';

  @override
  String get setupAgain => 'Запустить настройку заново';

  @override
  String version(String version) {
    return 'Версия $version';
  }

  @override
  String syncLast(int count) {
    return 'Синхронизировано (новых событий: $count)';
  }

  @override
  String get syncTitle => 'Синхронизация устройств';

  @override
  String get syncBackground => 'Фоновая синхронизация';

  @override
  String syncServerActive(int port) {
    return 'Сервер активен (порт $port) · P2P в локальной сети';
  }

  @override
  String get syncDisabled => 'Выключено';

  @override
  String get syncShowCode => 'Показать код сопряжения';

  @override
  String get syncShowCodeDesc => 'Код для других устройств';

  @override
  String get syncCodeTitle => 'Код сопряжения';

  @override
  String get syncCodeHint => 'Введите этот код на другом устройстве:';

  @override
  String get syncCodeCopied => 'Код сопряжения скопирован';

  @override
  String get copy => 'Копировать';

  @override
  String get done => 'Готово';

  @override
  String get syncPair => 'Подключить устройство';

  @override
  String get syncNoPeers => 'Нет подключённых устройств';

  @override
  String syncPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count устройства',
      many: '$count устройств',
      few: '$count устройства',
      one: '$count устройство',
    );
    return '$_temp0';
  }

  @override
  String get syncPasteCode => 'Вставьте код сопряжения';

  @override
  String get syncPairAction => 'Подключить';

  @override
  String get syncPaired => 'Подключено!';

  @override
  String get syncPairFailed => 'Не удалось подключить';

  @override
  String get syncNow => 'Синхронизировать сейчас';

  @override
  String get syncNever => 'Ещё не синхронизировано';

  @override
  String get syncDone => 'Синхронизировано';

  @override
  String get engineTitle => 'Аудиодвижок и производительность';

  @override
  String engineRustDesc(String label) {
    return '$label · сетка битов, тональность (хрома), громкость и ИИ-отпечаток по реальному звуку';
  }

  @override
  String get engineUnavailable => 'Недоступно – только оценка по форме волны';

  @override
  String get djFlowActiveDesc => 'Автоподбор фраз и тональности';

  @override
  String get djFlowAutomix => 'DJ Flow & Automix';

  @override
  String get djBpm => 'BPM';

  @override
  String get djTapToActivate => 'Нажмите, чтобы включить';

  @override
  String get djAnalyzing => 'Анализ аудио…';

  @override
  String get djNoKey => 'Тональность не определена';

  @override
  String get djKeyUncertain => 'неуверенно';

  @override
  String djBar(int bar) {
    return 'Такт $bar/4';
  }

  @override
  String djPhraseBeat(int beat) {
    return 'Доля фразы $beat/16';
  }

  @override
  String get statGrid => 'Сетка';

  @override
  String get statKey => 'Тональность';

  @override
  String get statLoudness => 'Громкость';

  @override
  String get statEnergy => 'Энергия';

  @override
  String get statSource => 'Источник';

  @override
  String get srcAudio => 'Аудио';

  @override
  String get srcWaveform => 'Форма волны';

  @override
  String get srcTitle => 'Название';

  @override
  String get djEnergiesLive => 'Энергия аудио (live)';

  @override
  String djTransitionIn(int beats) {
    return 'Переход через $beats долей';
  }

  @override
  String get djEnergyMode => 'Гармонический режим энергии';

  @override
  String get djModeBuildUp => 'Разогнать';

  @override
  String get djModeHold => 'Держать';

  @override
  String get djModeWindDown => 'Остыть';

  @override
  String get djHarmonic => 'Гармонично';

  @override
  String get djNextBest => 'Следующий трек (лучшее совпадение)';

  @override
  String djMatch(String pct) {
    return 'Совпадение $pct%';
  }

  @override
  String get djMixNow => 'Свести сейчас';

  @override
  String get bandBass => 'БАС (бочка и саб)';

  @override
  String get bandMid => 'СЕРЕДИНА (вокал и мелодия)';

  @override
  String get bandHigh => 'ВЕРХ (хэты и воздух)';

  @override
  String planDrop(String time) {
    return 'Дроп $time';
  }

  @override
  String get planNoDrop => 'без дропа';

  @override
  String get planSearching => 'ищем дроп…';

  @override
  String planText(String entry, String drop, String fade) {
    return 'Вход $entry · $drop · переход $fade с';
  }
}
