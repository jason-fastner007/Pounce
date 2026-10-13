// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Pounce';

  @override
  String get navHome => 'Start';

  @override
  String get navSearch => 'Suche';

  @override
  String get navLibrary => 'Bibliothek';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get greetingMorning => 'Guten Morgen';

  @override
  String get greetingAfternoon => 'Guten Tag';

  @override
  String get greetingEvening => 'Guten Abend';

  @override
  String get homeContinue => 'Weiterhören';

  @override
  String homeBecauseYouPlayed(String title) {
    return 'Weil du $title gehört hast';
  }

  @override
  String get errorLoading => 'Inhalte konnten nicht geladen werden';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String get searchHint => 'Songs, Künstler, Playlists oder Links';

  @override
  String get searchRecent => 'Letzte Suchen';

  @override
  String get searchEmptyTitle => 'Finde etwas zum Abspielen';

  @override
  String get tabTracks => 'Tracks';

  @override
  String get tabPlaylists => 'Playlists';

  @override
  String get tabAlbums => 'Alben';

  @override
  String get tabArtists => 'Künstler';

  @override
  String get likedTracks => 'Lieblingstracks';

  @override
  String get history => 'Verlauf';

  @override
  String get playlists => 'Playlists';

  @override
  String get newPlaylist => 'Neue Playlist';

  @override
  String get playlistName => 'Name';

  @override
  String get create => 'Erstellen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get delete => 'Löschen';

  @override
  String deletePlaylistConfirm(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get clearHistory => 'Verlauf löschen';

  @override
  String get emptyLikes => 'Tracks, die du likest, erscheinen hier';

  @override
  String get emptyHistory => 'Noch nichts gehört';

  @override
  String get emptyPlaylist => 'Diese Playlist ist leer';

  @override
  String get emptyPlaylists =>
      'Erstelle Playlists und füge Tracks über das ⋮-Menü hinzu.';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tracks',
      one: '1 Track',
      zero: 'Keine Tracks',
    );
    return '$_temp0';
  }

  @override
  String followers(String count) {
    return '$count Follower';
  }

  @override
  String get playNext => 'Als Nächstes abspielen';

  @override
  String get addToQueue => 'Zur Warteschlange';

  @override
  String get addToPlaylist => 'Zu Playlist hinzufügen';

  @override
  String get removeFromPlaylist => 'Aus Playlist entfernen';

  @override
  String get like => 'Liken';

  @override
  String get unlike => 'Aus Likes entfernen';

  @override
  String get goToArtist => 'Zum Künstler';

  @override
  String get copyLink => 'Link kopieren';

  @override
  String get linkCopied => 'Link kopiert';

  @override
  String get addedToQueue => 'Zur Warteschlange hinzugefügt';

  @override
  String addedToPlaylist(String name) {
    return 'Zu $name hinzugefügt';
  }

  @override
  String alreadyInPlaylist(String name) {
    return 'Schon in $name';
  }

  @override
  String get nowPlaying => 'Läuft gerade';

  @override
  String get queue => 'Warteschlange';

  @override
  String get lyrics => 'Songtext';

  @override
  String get noLyrics => 'Kein Songtext gefunden';

  @override
  String lyricsSource(String source) {
    return 'Songtext: $source';
  }

  @override
  String get sleepTimer => 'Schlaf-Timer';

  @override
  String get sleepOff => 'Timer ausschalten';

  @override
  String sleepIn(int minutes) {
    return 'Stoppt in $minutes Min.';
  }

  @override
  String minutes(int count) {
    return '$count Min.';
  }

  @override
  String get speed => 'Tempo';

  @override
  String get shuffle => 'Zufall';

  @override
  String get repeatOff => 'Wiederholen aus';

  @override
  String get repeatAll => 'Alle wiederholen';

  @override
  String get repeatOne => 'Einen wiederholen';

  @override
  String get play => 'Abspielen';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Weiter';

  @override
  String get previous => 'Zurück';

  @override
  String get popularTracks => 'Beliebt';

  @override
  String get playbackError => 'Dieser Track kann nicht abgespielt werden';

  @override
  String get preview => 'Vorschau';

  @override
  String get protected => 'Geschützt';

  @override
  String get protectedHint =>
      'Dieser Track ist DRM-geschützt und in Pounce noch nicht abspielbar – auch nicht mit Anmeldung';

  @override
  String get protectedPlayable =>
      'DRM-geschützt – entschlüsselt vom DRM-Modul deines Browsers';

  @override
  String get account => 'Konto';

  @override
  String get login => 'Mit SoundCloud anmelden';

  @override
  String get loginSubtitle =>
      'Likes, Playlists und deinen Stream synchronisieren';

  @override
  String get signup => 'Konto erstellen';

  @override
  String get loginPrivacy =>
      'Die Anmeldung läuft auf der Seite von SoundCloud. Pounce sieht dein Passwort nie.';

  @override
  String get loginWaiting => 'Schließe die Anmeldung im Browser ab …';

  @override
  String get loginReopen => 'Erneut öffnen';

  @override
  String get loginPasteLabel => 'Rückleitungs-Link einfügen';

  @override
  String get loginPasteHint =>
      'Nach der Anmeldung leitet SoundCloud auf einen Link sc://auth?code=… weiter. Falls die App ihn nicht automatisch erhält, füge ihn hier ein.';

  @override
  String get loginPasteHintWeb =>
      'Es öffnet sich ein neuer Tab. Nach der Anmeldung steht dort eine Adresse wie soundcloud.com/signin/callback?code=… Kopiere diese Adresse und füge sie hier ein.';

  @override
  String get loginConfirm => 'Weiter';

  @override
  String get loginFailed => 'Anmeldung fehlgeschlagen';

  @override
  String loggedInAs(String name) {
    return 'Angemeldet als $name';
  }

  @override
  String get logout => 'Abmelden';

  @override
  String get logoutConfirm => 'Abmelden? Deine Likes bleiben auf diesem Gerät.';

  @override
  String get homeStream => 'Dein Stream';

  @override
  String get scPlaylists => 'Deine SoundCloud-Playlists';

  @override
  String transferLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lokale Likes in dein Konto übertragen?',
      one: '1 lokalen Like in dein Konto übertragen?',
    );
    return '$_temp0';
  }

  @override
  String get transfer => 'Übertragen';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get loudTitle => 'Laut/Leise-Modus';

  @override
  String get loudDesc =>
      'Gleicht laute und leise Titel an (ITU-R BS.1770), mit integriertem Limiter gegen Übersteuern.';

  @override
  String get loudOff => 'Aus';

  @override
  String get loudQuiet => 'Leise';

  @override
  String get loudNormal => 'Normal';

  @override
  String get loudLoud => 'Laut';

  @override
  String get loudUnsupported => 'Auf dieser Plattform noch nicht verfügbar';

  @override
  String get signal => 'Signal';

  @override
  String get sigSource => 'Quelle';

  @override
  String get sigLoudness => 'Quell-Lautheit';

  @override
  String get sigMomentary => 'Momentan';

  @override
  String get sigGain => 'Verstärkung';

  @override
  String get sigLimiter => 'Limiter';

  @override
  String get sigOutput => 'Ausgang';

  @override
  String get sigAnalysis => 'Analyse';

  @override
  String get sigLive => 'Live-FFT';

  @override
  String get sigEnvelope => 'Wellenform-Hüllkurve';

  @override
  String get sigClip => 'Übersteuert';

  @override
  String get sigClean => 'Sauber';

  @override
  String get volume => 'Lautstärke';

  @override
  String get mute => 'Stumm';

  @override
  String get inspector => 'Inspector';

  @override
  String get expandPlayer => 'Fokus-Ansicht';

  @override
  String get expandRail => 'Leiste ausklappen';

  @override
  String get collapseRail => 'Leiste einklappen';

  @override
  String get accentAmber => 'Electric Amber';

  @override
  String get accentCyan => 'Cryo Cyan';

  @override
  String get accentCover => 'Aus dem Cover';

  @override
  String get beatBg => 'Hintergrund im Takt';

  @override
  String get beatBgDesc =>
      'Farben pulsieren und wechseln bei jedem erkannten Beat';

  @override
  String get beatLight => 'Leicht';

  @override
  String get beatMedium => 'Mittel';

  @override
  String get beatStrong => 'Stark';

  @override
  String get appearance => 'Darstellung';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get pureBlack => 'Reines Schwarz';

  @override
  String get pureBlackDesc => 'Schwarzer Hintergrund im Dunkelmodus (OLED)';

  @override
  String get dynamicColor => 'Systemfarben';

  @override
  String get dynamicColorDesc => 'Akzentfarbe des Systems verwenden';

  @override
  String get artworkColors => 'Farben aus dem Cover';

  @override
  String get artworkColorsDesc =>
      'Der Player passt seine Farben an das Cover an';

  @override
  String get accentColor => 'Akzentfarbe';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String get playback => 'Wiedergabe';

  @override
  String get quality => 'Streamqualität';

  @override
  String get qualityHigh => 'Hoch';

  @override
  String get qualitySaver => 'Datensparen';

  @override
  String get autoplay => 'Autoplay';

  @override
  String get autoplayDesc =>
      'Nach der Warteschlange ähnliche Tracks weiterspielen';

  @override
  String get network => 'Netzwerk';

  @override
  String get proxy => 'CORS-Proxy';

  @override
  String get proxyDesc =>
      'Im Browser nötig, weil SoundCloud nur die eigene Website zulässt.';

  @override
  String get about => 'Über';

  @override
  String get aboutText =>
      'Inspiriert von KittyTune (alan7383), komplett neu in Flutter geschrieben. Freie Software unter GPL-3.0.';

  @override
  String get licenses => 'Open-Source-Lizenzen';

  @override
  String get previewBadge => 'Vorschau (30 s)';

  @override
  String get previewHint =>
      'SoundCloud bietet von diesem Track nur eine 30-Sekunden-Vorschau an.';

  @override
  String get openInYtMusic => 'Auf YouTube Music öffnen';

  @override
  String get skipPreviews => 'Vorschauen überspringen';

  @override
  String get skipPreviewsDesc =>
      '30-Sekunden-Vorschauen beim Weiterschalten der Warteschlange auslassen';

  @override
  String get fastStart => 'Schnellstart';

  @override
  String get fastStartDesc =>
      'Angetippte Tracks starten als MP3 128 kbit/s – schneller, etwas geringere Qualität. Vorgepufferte Tracks behalten die gewählte Qualität.';

  @override
  String get navDj => 'DJ';

  @override
  String get djHeadline => 'Dein DJ';

  @override
  String get djIntro =>
      'Wähle, was du hören willst – Pounce mixt aus deinen Likes und Ähnlichem, mit Übergängen passend zu Tonart, Tempo und Drop.';

  @override
  String get djCategories => 'Kategorien';

  @override
  String get djBlend => 'Mischung';

  @override
  String get djFavorites => 'Favoriten';

  @override
  String get djDiscover => 'Entdecken';

  @override
  String get djLookahead => 'Vorausanalyse';

  @override
  String djLookaheadDesc(int count, int mb) {
    return '$count Songs im Voraus (~$mb MB)';
  }

  @override
  String get djStart => 'Mix starten';

  @override
  String get djBuilding => 'Mix wird gebaut…';

  @override
  String get djNothing =>
      'Nichts Passendes gefunden – probier eine andere Kategorie.';

  @override
  String get djPickCategory => 'Wähle mindestens eine Kategorie';

  @override
  String djAnalyzed(int done, int total) {
    return '$done von $total Songs analysiert';
  }

  @override
  String djMixStarted(int count) {
    return 'Mix mit $count Songs gestartet';
  }

  @override
  String get djStop => 'DJ beenden';

  @override
  String get djSkip => 'Skip (blendet über und lernt)';

  @override
  String get srcAll => 'Alle';

  @override
  String get srcRadio => 'Webradio';

  @override
  String get radioSection => 'Live-Radio · Sender';

  @override
  String get radioFavorites => 'Lieblingssender';

  @override
  String get radioTop => 'Meistgehört';

  @override
  String get radioAll => 'Alle Sender';

  @override
  String get radioSource => 'Webradio';

  @override
  String get radioSourceDesc =>
      'Zehntausende Sender von radio-browser.info. Aus: keine einzige Anfrage.';

  @override
  String get live => 'LIVE';

  @override
  String get updates => 'Updates';

  @override
  String get updatesAuto => 'Automatisch nach Updates suchen';

  @override
  String get updatesAutoDesc =>
      'Höchstens einmal täglich, eine Anfrage an GitHub ohne Geräte-ID. Lädt nie selbst herunter.';

  @override
  String get updatesCheck => 'Jetzt prüfen';

  @override
  String get updatesNone => 'Pounce ist aktuell';

  @override
  String get updatesUnavailable =>
      'In diesem Build sind keine Updates verfügbar';

  @override
  String updateTitle(String version) {
    return 'Update auf $version';
  }

  @override
  String updateDownload(String mb) {
    return 'Herunterladen & installieren ($mb MB)';
  }

  @override
  String get updateViaPlay => 'Über Google Play aktualisieren';

  @override
  String get updateLater => 'Später';

  @override
  String get updateReleasePage => 'Release-Seite';

  @override
  String get updateChecksumFailed =>
      'Prüfsumme stimmt nicht – der Download wurde verworfen.';

  @override
  String get updateNeedsPermission =>
      'Erlaube Pounce das Installieren von Apps und tippe dann erneut.';

  @override
  String get updateFailed =>
      'Update fehlgeschlagen – bitte später erneut versuchen.';

  @override
  String get beta => 'Beta';

  @override
  String get betaNote =>
      'Pounce ist in der Beta. Manches kann sich ändern oder haken – Feedback auf GitHub ist sehr willkommen.';

  @override
  String get setupWelcome => 'Willkommen bei Pounce';

  @override
  String get setupTagline =>
      'Schnelle Musik von SoundCloud und Webradio – mit einem DJ, der für dich mixt.';

  @override
  String get setupStart => 'Los geht\'s';

  @override
  String get setupNext => 'Weiter';

  @override
  String get setupBack => 'Zurück';

  @override
  String get setupSkip => 'Einrichtung überspringen';

  @override
  String get setupDone => 'Musik starten';

  @override
  String get setupSourcesTitle => 'Woher soll die Musik kommen?';

  @override
  String get setupSoundcloudDesc =>
      'Millionen Tracks, Mixe und Remixe. Immer an.';

  @override
  String get setupRadioDesc =>
      'Über 30.000 Sender über radio-browser.info. Aus = keine einzige Anfrage.';

  @override
  String get setupAccountTitle => 'Deine Likes mitnehmen?';

  @override
  String get setupAccountDesc =>
      'Optional: Melde dich bei SoundCloud an, um Likes und Playlists zu übernehmen. Pounce funktioniert auch ohne Konto.';

  @override
  String get setupSignIn => 'Bei SoundCloud anmelden';

  @override
  String get setupDjTitle => 'Was soll dein DJ spielen?';

  @override
  String get setupDjDesc =>
      'Wähle ein paar Stile. Du kannst sie jederzeit im DJ-Tab ändern.';

  @override
  String get setupPrivacyTitle => 'Deine Privatsphäre';

  @override
  String get setupPrivacyDesc =>
      'Kein Tracking, keine Werbung, keine Geräte-IDs. Alles hier ist aus, bis du es einschaltest.';

  @override
  String get setupRecognition => 'Songerkennung (Echolot)';

  @override
  String get setupRecognitionDesc =>
      'Kommt in einer späteren Beta. Sendet nur anonyme Audio-Fingerabdrücke – nie Aufnahmen – an den Echolot-Server.';

  @override
  String get setupAgain => 'Einrichtung erneut starten';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String syncLast(int count) {
    return 'Synchronisiert ($count neue Events)';
  }

  @override
  String get syncTitle => 'Gerätesynchronisation';

  @override
  String get syncBackground => 'Hintergrund-Synchronisation';

  @override
  String syncServerActive(int port) {
    return 'Server aktiv (Port $port) · P2P-Sync im lokalen WLAN';
  }

  @override
  String get syncDisabled => 'Deaktiviert';

  @override
  String get syncShowCode => 'Kopplungscode anzeigen';

  @override
  String get syncShowCodeDesc => 'Code für andere Geräte zum Synchronisieren';

  @override
  String get syncCodeTitle => 'Kopplungscode';

  @override
  String get syncCodeHint => 'Gib diesen Code auf deinem anderen Gerät ein:';

  @override
  String get syncCodeCopied => 'Kopplungscode in Zwischenablage kopiert';

  @override
  String get copy => 'Kopieren';

  @override
  String get done => 'Fertig';

  @override
  String get syncPair => 'Gerät koppeln';

  @override
  String get syncNoPeers => 'Kein anderes Gerät verbunden';

  @override
  String syncPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Geräte gekoppelt',
      one: '1 Gerät gekoppelt',
    );
    return '$_temp0';
  }

  @override
  String get syncPasteCode => 'Kopplungscode einfügen';

  @override
  String get syncPairAction => 'Koppeln';

  @override
  String get syncPaired => 'Erfolgreich gekoppelt!';

  @override
  String get syncPairFailed => 'Kopplung fehlgeschlagen';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get syncNever => 'Noch nicht synchronisiert';

  @override
  String get syncDone => 'Synchronisiert';

  @override
  String get engineTitle => 'Audio Engine & Performance';

  @override
  String engineRustDesc(String label) {
    return '$label · Beat-Raster, Tonart (Chroma), Lautheit, KI-Fingerabdruck aus echtem Audio';
  }

  @override
  String get engineUnavailable =>
      'Nicht verfügbar – nur Schätzung aus der Wellenform';

  @override
  String get djFlowActiveDesc => 'Autonome Phrasen- & Tonart-Abstimmung';

  @override
  String get djTapToActivate => 'Tippen zum Aktivieren';

  @override
  String get djAnalyzing => 'Audio wird analysiert…';

  @override
  String get djNoKey => 'Keine Tonart erkennbar';

  @override
  String get djKeyUncertain => 'unsicher';

  @override
  String djBar(int bar) {
    return 'Takt $bar/4';
  }

  @override
  String djPhraseBeat(int beat) {
    return 'Phrase Beat $beat/16';
  }

  @override
  String get statGrid => 'Raster';

  @override
  String get statKey => 'Tonart';

  @override
  String get statLoudness => 'Lautheit';

  @override
  String get statEnergy => 'Energie';

  @override
  String get statSource => 'Quelle';

  @override
  String get srcAudio => 'Audio';

  @override
  String get srcWaveform => 'Wellenform';

  @override
  String get srcTitle => 'Titel';

  @override
  String get djEnergiesLive => 'Audio-Energien (live)';

  @override
  String djTransitionIn(int beats) {
    return 'Übergang in $beats Beats';
  }

  @override
  String get djEnergyMode => 'Harmonischer Energie-Modus';

  @override
  String get djModeBuildUp => 'Aufbauen';

  @override
  String get djModeHold => 'Halten';

  @override
  String get djModeWindDown => 'Abkühlen';

  @override
  String get djHarmonic => 'Harmonisch';

  @override
  String get djNextBest => 'Nächster Track (Bester Match)';

  @override
  String djMatch(String pct) {
    return '$pct% Match';
  }

  @override
  String get djMixNow => 'Jetzt mixen';

  @override
  String get bandBass => 'BASS (Kick & Sub)';

  @override
  String get bandMid => 'MID (Vocals & Melodie)';

  @override
  String get bandHigh => 'HIGH (Hi-Hats & Air)';

  @override
  String planDrop(String time) {
    return 'Drop $time';
  }

  @override
  String get planNoDrop => 'kein Drop';

  @override
  String get planSearching => 'Drop wird gesucht…';

  @override
  String planText(String entry, String drop, String fade) {
    return 'Einstieg $entry · $drop · $fade s Blende';
  }
}
