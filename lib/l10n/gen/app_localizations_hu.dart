// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appName => 'Pounce';

  @override
  String get navHome => 'Kezdőlap';

  @override
  String get navSearch => 'Keresés';

  @override
  String get navLibrary => 'Könyvtár';

  @override
  String get navSettings => 'Beállítások';

  @override
  String get greetingMorning => 'Jó reggelt';

  @override
  String get greetingAfternoon => 'Szép napot';

  @override
  String get greetingEvening => 'Jó estét';

  @override
  String get homeContinue => 'Folytatás';

  @override
  String homeBecauseYouPlayed(String title) {
    return 'Mert ezt hallgattad: $title';
  }

  @override
  String get errorLoading => 'Nem sikerült betölteni';

  @override
  String get retry => 'Újra';

  @override
  String get noResults => 'Nincs találat';

  @override
  String get searchHint => 'Dalok, előadók, lejátszási listák vagy linkek';

  @override
  String get searchRecent => 'Legutóbbi keresések';

  @override
  String get searchEmptyTitle => 'Keress valamit, amit meghallgatnál';

  @override
  String get tabTracks => 'Számok';

  @override
  String get tabPlaylists => 'Listák';

  @override
  String get tabAlbums => 'Albumok';

  @override
  String get tabArtists => 'Előadók';

  @override
  String get likedTracks => 'Kedvelt számok';

  @override
  String get history => 'Előzmények';

  @override
  String get playlists => 'Lejátszási listák';

  @override
  String get newPlaylist => 'Új lista';

  @override
  String get playlistName => 'Név';

  @override
  String get create => 'Létrehozás';

  @override
  String get cancel => 'Mégse';

  @override
  String get rename => 'Átnevezés';

  @override
  String get delete => 'Törlés';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Törlöd: „$name”?';
  }

  @override
  String get clearHistory => 'Előzmények törlése';

  @override
  String get emptyLikes => 'A kedvelt számok itt jelennek meg';

  @override
  String get emptyHistory => 'Még nem hallgattál semmit';

  @override
  String get emptyPlaylist => 'Ez a lista üres';

  @override
  String get emptyPlaylists => 'Hozz létre listákat, és adj hozzá számokat a ⋮ menüvel.';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count szám', zero: 'Nincs szám');
    return '$_temp0';
  }

  @override
  String followers(String count) {
    return '$count követő';
  }

  @override
  String get playNext => 'Lejátszás következőként';

  @override
  String get addToQueue => 'Hozzáadás a sorhoz';

  @override
  String get addToPlaylist => 'Hozzáadás listához';

  @override
  String get removeFromPlaylist => 'Eltávolítás a listából';

  @override
  String get like => 'Kedvelés';

  @override
  String get unlike => 'Eltávolítás a kedveltek közül';

  @override
  String get goToArtist => 'Ugrás az előadóhoz';

  @override
  String get copyLink => 'Link másolása';

  @override
  String get linkCopied => 'Link másolva';

  @override
  String get addedToQueue => 'Hozzáadva a sorhoz';

  @override
  String addedToPlaylist(String name) {
    return 'Hozzáadva: $name';
  }

  @override
  String alreadyInPlaylist(String name) {
    return 'Már szerepel itt: $name';
  }

  @override
  String get nowPlaying => 'Most szól';

  @override
  String get queue => 'Lejátszási sor';

  @override
  String get lyrics => 'Dalszöveg';

  @override
  String get noLyrics => 'Nem található dalszöveg';

  @override
  String lyricsSource(String source) {
    return 'Dalszöveg: $source';
  }

  @override
  String get sleepTimer => 'Elalvási időzítő';

  @override
  String get sleepOff => 'Időzítő kikapcsolása';

  @override
  String sleepIn(int minutes) {
    return 'Leáll $minutes perc múlva';
  }

  @override
  String minutes(int count) {
    return '$count perc';
  }

  @override
  String get speed => 'Sebesség';

  @override
  String get shuffle => 'Keverés';

  @override
  String get repeatOff => 'Ismétlés ki';

  @override
  String get repeatAll => 'Összes ismétlése';

  @override
  String get repeatOne => 'Egy ismétlése';

  @override
  String get play => 'Lejátszás';

  @override
  String get pause => 'Szünet';

  @override
  String get next => 'Következő';

  @override
  String get previous => 'Előző';

  @override
  String get popularTracks => 'Népszerű';

  @override
  String get playbackError => 'Ez a szám nem játszható le';

  @override
  String get preview => 'Előnézet';

  @override
  String get protected => 'Védett';

  @override
  String get protectedHint => 'Ez a szám DRM-védett, és a Pounce még nem tudja lejátszani – bejelentkezve sem';

  @override
  String get protectedPlayable => 'DRM-védett – a böngésző DRM-modulja oldja fel';

  @override
  String get account => 'Fiók';

  @override
  String get login => 'Bejelentkezés SoundClouddal';

  @override
  String get loginSubtitle => 'Kedvelések, listák és a hírfolyam szinkronizálása';

  @override
  String get signup => 'Fiók létrehozása';

  @override
  String get loginPrivacy => 'A bejelentkezés a SoundCloud oldalán történik. A Pounce sosem látja a jelszavadat.';

  @override
  String get loginWaiting => 'Fejezd be a bejelentkezést a böngészőben…';

  @override
  String get loginReopen => 'Újra megnyitás';

  @override
  String get loginPasteLabel => 'Átirányító link beillesztése';

  @override
  String get loginPasteHint =>
      'Bejelentkezés után a SoundCloud egy sc://auth?code=… linkre irányít. Ha az app nem kapja meg automatikusan, illeszd be ide.';

  @override
  String get loginPasteHintWeb =>
      'Új lap nyílik meg. Bejelentkezés után egy soundcloud.com/signin/callback?code=… címet mutat. Másold ki és illeszd be ide.';

  @override
  String get loginConfirm => 'Tovább';

  @override
  String get loginFailed => 'A bejelentkezés sikertelen';

  @override
  String loggedInAs(String name) {
    return 'Bejelentkezve: $name';
  }

  @override
  String get logout => 'Kijelentkezés';

  @override
  String get logoutConfirm => 'Kijelentkezel? A kedveléseid megmaradnak ezen az eszközön.';

  @override
  String get homeStream => 'Hírfolyamod';

  @override
  String get scPlaylists => 'SoundCloud-listáid';

  @override
  String transferLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Átviszel $count helyi kedvelést a fiókodba?',
    );
    return '$_temp0';
  }

  @override
  String get transfer => 'Átvitel';

  @override
  String get notNow => 'Most nem';

  @override
  String get loudTitle => 'Hangerő-mód';

  @override
  String get loudDesc =>
      'Kiegyenlíti a hangos és halk számokat (ITU-R BS.1770), beépített limiterrel a túlvezérlés ellen.';

  @override
  String get loudOff => 'Ki';

  @override
  String get loudQuiet => 'Halk';

  @override
  String get loudNormal => 'Normál';

  @override
  String get loudLoud => 'Hangos';

  @override
  String get loudUnsupported => 'Ezen a platformon még nem érhető el';

  @override
  String get signal => 'Jel';

  @override
  String get sigSource => 'Forrás';

  @override
  String get sigLoudness => 'Forrás hangossága';

  @override
  String get sigMomentary => 'Pillanatnyi';

  @override
  String get sigGain => 'Erősítés';

  @override
  String get sigLimiter => 'Limiter';

  @override
  String get sigOutput => 'Kimenet';

  @override
  String get sigAnalysis => 'Elemzés';

  @override
  String get sigLive => 'Élő FFT';

  @override
  String get sigEnvelope => 'Hullámforma-burkoló';

  @override
  String get sigClip => 'Túlvezérlés';

  @override
  String get sigClean => 'Tiszta';

  @override
  String get volume => 'Hangerő';

  @override
  String get mute => 'Némítás';

  @override
  String get inspector => 'Inspector';

  @override
  String get expandPlayer => 'Fókusz nézet';

  @override
  String get expandRail => 'Oldalsáv kinyitása';

  @override
  String get collapseRail => 'Oldalsáv becsukása';

  @override
  String get accentAmber => 'Elektromos borostyán';

  @override
  String get accentCyan => 'Krio cián';

  @override
  String get accentCover => 'A borítóból';

  @override
  String get beatBg => 'Háttér az ütemre';

  @override
  String get beatBgDesc => 'A színek minden észlelt ütemre lüktetnek és váltanak';

  @override
  String get beatLight => 'Enyhe';

  @override
  String get beatMedium => 'Közepes';

  @override
  String get beatStrong => 'Erős';

  @override
  String get appearance => 'Megjelenés';

  @override
  String get themeSystem => 'Rendszer';

  @override
  String get themeLight => 'Világos';

  @override
  String get themeDark => 'Sötét';

  @override
  String get pureBlack => 'Tiszta fekete';

  @override
  String get pureBlackDesc => 'Fekete háttér sötét módban (OLED)';

  @override
  String get dynamicColor => 'Rendszerszínek';

  @override
  String get dynamicColorDesc => 'A rendszer kiemelőszínének használata';

  @override
  String get artworkColors => 'Színek a borítóból';

  @override
  String get artworkColorsDesc => 'A lejátszó a borítóhoz igazítja a színeit';

  @override
  String get accentColor => 'Kiemelőszín';

  @override
  String get language => 'Nyelv';

  @override
  String get languageSystem => 'Rendszer nyelve';

  @override
  String get playback => 'Lejátszás';

  @override
  String get quality => 'Streamminőség';

  @override
  String get qualityHigh => 'Magas';

  @override
  String get qualitySaver => 'Adattakarékos';

  @override
  String get autoplay => 'Automatikus lejátszás';

  @override
  String get autoplayDesc => 'Hasonló számok lejátszása a sor végén';

  @override
  String get network => 'Hálózat';

  @override
  String get proxy => 'CORS-proxy';

  @override
  String get proxyDesc => 'Böngészőben szükséges, mert a SoundCloud csak a saját oldalát engedi.';

  @override
  String get about => 'Névjegy';

  @override
  String get aboutText => 'A KittyTune (alan7383) ihlette, Flutterben az alapoktól megírva. Szabad szoftver, GPL-3.0.';

  @override
  String get licenses => 'Nyílt forráskódú licencek';

  @override
  String get previewBadge => 'Előnézet (30 mp)';

  @override
  String get previewHint => 'A SoundCloud ebből a számból csak 30 másodperces előnézetet kínál.';

  @override
  String get openInYtMusic => 'Megnyitás a YouTube Musicban';

  @override
  String get skipPreviews => 'Előnézetek kihagyása';

  @override
  String get skipPreviewsDesc => 'A 30 másodperces előnézetek kihagyása a lejátszási sor léptetésekor';

  @override
  String get fastStart => 'Gyorsindítás';

  @override
  String get fastStartDesc =>
      'A koppintott számok MP3 128 kbit/s-ként indulnak – gyorsabb, kicsit gyengébb minőség. Az előre pufferelt számok megtartják a választott minőséget.';

  @override
  String get navDj => 'DJ';

  @override
  String get djHeadline => 'A te DJ-d';

  @override
  String get djIntro =>
      'Válaszd ki, mit hallgatnál – a Pounce a kedvenceidből és hasonló számokból mixel, hangnemhez, tempóhoz és drophoz illő átmenetekkel.';

  @override
  String get djCategories => 'Kategóriák';

  @override
  String get djBlend => 'Keverék';

  @override
  String get djFavorites => 'Kedvencek';

  @override
  String get djDiscover => 'Felfedezés';

  @override
  String get djLookahead => 'Előzetes elemzés';

  @override
  String djLookaheadDesc(int count, int mb) {
    return '$count szám előre (~$mb MB)';
  }

  @override
  String get djStart => 'Mix indítása';

  @override
  String get djBuilding => 'Mix készül…';

  @override
  String get djNothing => 'Nincs találat – próbálj másik kategóriát.';

  @override
  String get djPickCategory => 'Válassz legalább egy kategóriát';

  @override
  String djAnalyzed(int done, int total) {
    return '$total számból $done elemezve';
  }

  @override
  String djMixStarted(int count) {
    return '$count számos mix elindult';
  }

  @override
  String get djStop => 'DJ leállítása';

  @override
  String get djSkip => 'Kihagyás (átkever és tanul)';

  @override
  String get srcAll => 'Mind';

  @override
  String get srcRadio => 'Webrádió';

  @override
  String get radioSection => 'Élő rádió · Adók';

  @override
  String get radioFavorites => 'Kedvenc adók';

  @override
  String get radioTop => 'Legtöbbet hallgatott';

  @override
  String get radioAll => 'Összes adó';

  @override
  String get radioSource => 'Webrádió';

  @override
  String get radioSourceDesc => 'Több tízezer adó a radio-browser.info-ról. Kikapcsolva: egyetlen kérés sem.';

  @override
  String get live => 'ÉLŐ';

  @override
  String get updates => 'Frissítések';

  @override
  String get updatesAuto => 'Frissítések automatikus keresése';

  @override
  String get updatesAutoDesc =>
      'Legfeljebb naponta egyszer, egy kérés a GitHubnak eszközazonosító nélkül. Soha nem tölt le magától.';

  @override
  String get updatesCheck => 'Ellenőrzés';

  @override
  String get updatesNone => 'A Pounce naprakész';

  @override
  String get updatesUnavailable => 'Ebben a buildben nincs frissítés';

  @override
  String updateTitle(String version) {
    return 'Frissítés: $version';
  }

  @override
  String updateDownload(String mb) {
    return 'Letöltés és telepítés ($mb MB)';
  }

  @override
  String get updateViaPlay => 'Frissítés a Google Playen';

  @override
  String get updateLater => 'Később';

  @override
  String get updateReleasePage => 'Kiadás oldala';

  @override
  String get updateChecksumFailed => 'Hibás ellenőrzőösszeg – a letöltés törölve.';

  @override
  String get updateNeedsPermission => 'Engedélyezd a Pounce-nak az alkalmazások telepítését, majd koppints újra.';

  @override
  String get updateFailed => 'A frissítés sikertelen – próbáld később.';

  @override
  String get beta => 'Béta';

  @override
  String get betaNote =>
      'A Pounce béta. Valami változhat vagy elromolhat – a GitHubon szívesen fogadjuk a visszajelzést.';

  @override
  String get setupWelcome => 'Üdv a Pounce-ban';

  @override
  String get setupTagline => 'Gyors zene SoundCloudról és webrádióból – egy DJ-vel, aki neked keverget.';

  @override
  String get setupStart => 'Kezdjük';

  @override
  String get setupNext => 'Tovább';

  @override
  String get setupBack => 'Vissza';

  @override
  String get setupSkip => 'Beállítás kihagyása';

  @override
  String get setupDone => 'Hallgatás indítása';

  @override
  String get setupSourcesTitle => 'Honnan jöjjön a zene?';

  @override
  String get setupSoundcloudDesc => 'Milliónyi szám, mix és remix. Mindig be van kapcsolva.';

  @override
  String get setupRadioDesc => 'Több mint 30 000 állomás a radio-browser.info-n keresztül. Ki = egyetlen kérés sem.';

  @override
  String get setupAccountTitle => 'Hozod a kedvenceidet?';

  @override
  String get setupAccountDesc =>
      'Opcionális: jelentkezz be a SoundCloudba a kedvencek és listák átvételéhez. A Pounce fiók nélkül is működik.';

  @override
  String get setupSignIn => 'Bejelentkezés a SoundCloudba';

  @override
  String get setupDjTitle => 'Mit játsszon a DJ-d?';

  @override
  String get setupDjDesc => 'Válassz néhány stílust. A DJ fülön bármikor módosíthatod.';

  @override
  String get setupPrivacyTitle => 'Az adataid';

  @override
  String get setupPrivacyDesc =>
      'Nincs követés, reklám vagy eszközazonosító. Minden ki van kapcsolva, amíg be nem kapcsolod.';

  @override
  String get setupRecognition => 'Dalfelismerés (Echolot)';

  @override
  String get setupRecognitionDesc =>
      'Egy későbbi bétában érkezik. Csak névtelen hang-ujjlenyomatokat küld az Echolot szervernek – felvételt soha.';

  @override
  String get setupAgain => 'Beállítás újraindítása';

  @override
  String version(String version) {
    return 'Verzió: $version';
  }

  @override
  String syncLast(int count) {
    return 'Szinkronizálva ($count új esemény)';
  }

  @override
  String get syncTitle => 'Eszközszinkronizálás';

  @override
  String get syncBackground => 'Háttérszinkronizálás';

  @override
  String syncServerActive(int port) {
    return 'Szerver aktív ($port. port) · P2P a helyi hálózaton';
  }

  @override
  String get syncDisabled => 'Kikapcsolva';

  @override
  String get syncShowCode => 'Párosítási kód megjelenítése';

  @override
  String get syncShowCodeDesc => 'Kód a többi eszközödhöz';

  @override
  String get syncCodeTitle => 'Párosítási kód';

  @override
  String get syncCodeHint => 'Írd be ezt a kódot a másik eszközödön:';

  @override
  String get syncCodeCopied => 'Párosítási kód másolva';

  @override
  String get copy => 'Másolás';

  @override
  String get done => 'Kész';

  @override
  String get syncPair => 'Eszköz párosítása';

  @override
  String get syncNoPeers => 'Nincs más eszköz csatlakoztatva';

  @override
  String syncPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count eszköz párosítva');
    return '$_temp0';
  }

  @override
  String get syncPasteCode => 'Párosítási kód beillesztése';

  @override
  String get syncPairAction => 'Párosítás';

  @override
  String get syncPaired => 'Párosítva!';

  @override
  String get syncPairFailed => 'A párosítás sikertelen';

  @override
  String get syncNow => 'Szinkronizálás most';

  @override
  String get syncNever => 'Még nincs szinkronizálva';

  @override
  String get syncDone => 'Szinkronizálva';

  @override
  String get engineTitle => 'Hangmotor és teljesítmény';

  @override
  String engineRustDesc(String label) {
    return '$label · ütemrács, hangnem (kroma), hangosság és MI-ujjlenyomat valódi hangból';
  }

  @override
  String get engineUnavailable => 'Nem elérhető – csak becslés a hullámformából';

  @override
  String get djFlowActiveDesc => 'Automatikus frázis- és hangnemillesztés';

  @override
  String get djTapToActivate => 'Koppints az aktiváláshoz';

  @override
  String get djAnalyzing => 'Hang elemzése…';

  @override
  String get djNoKey => 'Nem ismerhető fel hangnem';

  @override
  String get djKeyUncertain => 'bizonytalan';

  @override
  String djBar(int bar) {
    return '$bar/4. ütem';
  }

  @override
  String djPhraseBeat(int beat) {
    return 'Frázisütés $beat/16';
  }

  @override
  String get statGrid => 'Rács';

  @override
  String get statKey => 'Hangnem';

  @override
  String get statLoudness => 'Hangosság';

  @override
  String get statEnergy => 'Energia';

  @override
  String get statSource => 'Forrás';

  @override
  String get srcAudio => 'Hang';

  @override
  String get srcWaveform => 'Hullámforma';

  @override
  String get srcTitle => 'Cím';

  @override
  String get djEnergiesLive => 'Hangenergiák (élő)';

  @override
  String djTransitionIn(int beats) {
    return 'Átmenet $beats ütés múlva';
  }

  @override
  String get djEnergyMode => 'Harmonikus energiamód';

  @override
  String get djModeBuildUp => 'Felépítés';

  @override
  String get djModeHold => 'Tartás';

  @override
  String get djModeWindDown => 'Levezetés';

  @override
  String get djHarmonic => 'Harmonikus';

  @override
  String get djNextBest => 'Következő szám (legjobb egyezés)';

  @override
  String djMatch(String pct) {
    return '$pct% egyezés';
  }

  @override
  String get djMixNow => 'Keverés most';

  @override
  String get bandBass => 'BASSZUS (lábdob és sub)';

  @override
  String get bandMid => 'KÖZÉP (ének és dallam)';

  @override
  String get bandHigh => 'MAGAS (cintányér és levegő)';

  @override
  String planDrop(String time) {
    return 'Drop $time';
  }

  @override
  String get planNoDrop => 'nincs drop';

  @override
  String get planSearching => 'drop keresése…';

  @override
  String planText(String entry, String drop, String fade) {
    return 'Belépés $entry · $drop · $fade mp áttűnés';
  }

  @override
  String get modules => 'Modulok';

  @override
  String get modulesDesc => 'Források és dizájnok – be- és kikapcsolás, újak hozzáadása';

  @override
  String get modulesSources => 'Források ebben a verzióban';

  @override
  String get modulesNoSources => 'Ebben a verzióban nincs forrásmodul – a webrádió és a könyvtár továbbra is működik.';

  @override
  String get modulesThemes => 'Dizájnok';

  @override
  String get themeDefault => 'Alapértelmezett';

  @override
  String get themeDefaultDesc => 'Kiemelőszín a beállításokból';

  @override
  String themeActive(String name) {
    return 'A(z) „$name” dizájn aktív – válassz színt a visszaváltáshoz';
  }

  @override
  String get modulesCatalog => 'Katalógus';

  @override
  String get modulesBrowse => 'Modulok böngészése';

  @override
  String get modulesBrowseDesc => 'Letölti a katalógust a GitHubról – egy kérés, rólad semmit nem küld';

  @override
  String get moduleInstall => 'Telepítés';

  @override
  String get moduleRemove => 'Eltávolítás';

  @override
  String get moduleIncluded => 'BENNE VAN';

  @override
  String get moduleNotInBuild => 'NINCS EBBEN A VERZIÓBAN';

  @override
  String moduleByline(String version, String author) {
    return 'v$version · készítette: $author';
  }

  @override
  String get modulesDevelop => 'Fejlesztőknek';

  @override
  String get modulesDevelopTitle => 'Saját modul készítése';

  @override
  String get modulesDevelopDesc => 'Dizájnok, zeneforrások és hogyan kerülnek a katalógusba';

  @override
  String get moduleUnavailable => 'A tartalomhoz tartozó modul ki van kapcsolva, vagy nem része ennek a verziónak';

  @override
  String get homeNoSources =>
      'Webrádiókat a Keresésben találsz – további források modulként érhetők el (Beállítások → Modulok).';

  @override
  String get djNoSources => 'A DJ-mixekhez olyan zeneforrás-modul kell, amely támogatja őket (Beállítások → Modulok).';
}
