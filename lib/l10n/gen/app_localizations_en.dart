// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Pounce';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navLibrary => 'Library';

  @override
  String get navSettings => 'Settings';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get homeContinue => 'Jump back in';

  @override
  String homeBecauseYouPlayed(String title) {
    return 'Because you played $title';
  }

  @override
  String get errorLoading => 'Couldn\'t load content';

  @override
  String get retry => 'Retry';

  @override
  String get noResults => 'No results';

  @override
  String get searchHint => 'Songs, artists, playlists or links';

  @override
  String get searchRecent => 'Recent searches';

  @override
  String get searchEmptyTitle => 'Find something to play';

  @override
  String get tabTracks => 'Tracks';

  @override
  String get tabPlaylists => 'Playlists';

  @override
  String get tabAlbums => 'Albums';

  @override
  String get tabArtists => 'Artists';

  @override
  String get likedTracks => 'Liked tracks';

  @override
  String get history => 'History';

  @override
  String get playlists => 'Playlists';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get playlistName => 'Name';

  @override
  String get create => 'Create';

  @override
  String get cancel => 'Cancel';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get clearHistory => 'Clear history';

  @override
  String get emptyLikes => 'Tracks you like appear here';

  @override
  String get emptyHistory => 'Nothing played yet';

  @override
  String get emptyPlaylist => 'This playlist is empty';

  @override
  String get emptyPlaylists => 'Create playlists and add tracks via the ⋮ menu.';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
      zero: 'No tracks',
    );
    return '$_temp0';
  }

  @override
  String followers(String count) {
    return '$count followers';
  }

  @override
  String get playNext => 'Play next';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get removeFromPlaylist => 'Remove from playlist';

  @override
  String get like => 'Like';

  @override
  String get unlike => 'Remove from likes';

  @override
  String get goToArtist => 'Go to artist';

  @override
  String get copyLink => 'Copy link';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get addedToQueue => 'Added to queue';

  @override
  String addedToPlaylist(String name) {
    return 'Added to $name';
  }

  @override
  String alreadyInPlaylist(String name) {
    return 'Already in $name';
  }

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get queue => 'Queue';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get noLyrics => 'No lyrics found';

  @override
  String lyricsSource(String source) {
    return 'Lyrics: $source';
  }

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String get sleepOff => 'Turn off timer';

  @override
  String sleepIn(int minutes) {
    return 'Stops in $minutes min';
  }

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get speed => 'Speed';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get repeatOff => 'Repeat off';

  @override
  String get repeatAll => 'Repeat all';

  @override
  String get repeatOne => 'Repeat one';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get popularTracks => 'Popular';

  @override
  String get playbackError => 'Can\'t play this track';

  @override
  String get preview => 'Preview';

  @override
  String get protected => 'Protected';

  @override
  String get protectedHint => 'This track is DRM-protected and can’t be played in Pounce yet – even when signed in';

  @override
  String get protectedPlayable => 'DRM-protected – decrypted by your browser’s DRM module';

  @override
  String get account => 'Account';

  @override
  String get login => 'Sign in with SoundCloud';

  @override
  String get loginSubtitle => 'Sync likes, playlists and your stream';

  @override
  String get signup => 'Create account';

  @override
  String get loginPrivacy => 'You sign in on SoundCloud’s own page. Pounce never sees your password.';

  @override
  String get loginWaiting => 'Finish signing in in the browser…';

  @override
  String get loginReopen => 'Open again';

  @override
  String get loginPasteLabel => 'Paste redirect link';

  @override
  String get loginPasteHint =>
      'After signing in, SoundCloud redirects to a link starting with sc://auth?code=… If the app doesn’t pick it up automatically, copy it here.';

  @override
  String get loginPasteHintWeb =>
      'A new tab opens. After signing in it shows an address like soundcloud.com/signin/callback?code=… Copy that address and paste it here.';

  @override
  String get loginConfirm => 'Continue';

  @override
  String get loginFailed => 'Sign-in failed';

  @override
  String loggedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get logout => 'Sign out';

  @override
  String get logoutConfirm => 'Sign out? Your likes stay on this device.';

  @override
  String get homeStream => 'Your stream';

  @override
  String get scPlaylists => 'Your SoundCloud playlists';

  @override
  String transferLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Transfer $count local likes to your account?',
      one: 'Transfer 1 local like to your account?',
    );
    return '$_temp0';
  }

  @override
  String get transfer => 'Transfer';

  @override
  String get notNow => 'Not now';

  @override
  String get loudTitle => 'Loudness mode';

  @override
  String get loudDesc => 'Evens out loud and quiet tracks (ITU-R BS.1770) with a built-in limiter against clipping.';

  @override
  String get loudOff => 'Off';

  @override
  String get loudQuiet => 'Quiet';

  @override
  String get loudNormal => 'Normal';

  @override
  String get loudLoud => 'Loud';

  @override
  String get loudUnsupported => 'Not available on this platform yet';

  @override
  String get signal => 'Signal';

  @override
  String get sigSource => 'Source';

  @override
  String get sigLoudness => 'Source loudness';

  @override
  String get sigMomentary => 'Momentary';

  @override
  String get sigGain => 'Gain';

  @override
  String get sigLimiter => 'Limiter';

  @override
  String get sigOutput => 'Output';

  @override
  String get sigAnalysis => 'Analysis';

  @override
  String get sigLive => 'Live FFT';

  @override
  String get sigEnvelope => 'Waveform envelope';

  @override
  String get sigClip => 'Clipping';

  @override
  String get sigClean => 'Clean';

  @override
  String get volume => 'Volume';

  @override
  String get mute => 'Mute';

  @override
  String get inspector => 'Inspector';

  @override
  String get expandPlayer => 'Focus view';

  @override
  String get expandRail => 'Expand sidebar';

  @override
  String get collapseRail => 'Collapse sidebar';

  @override
  String get accentAmber => 'Electric Amber';

  @override
  String get accentCyan => 'Cryo Cyan';

  @override
  String get accentCover => 'From artwork';

  @override
  String get beatBg => 'Background in time with the beat';

  @override
  String get beatBgDesc => 'Colors pulse and change with every detected beat';

  @override
  String get beatLight => 'Light';

  @override
  String get beatMedium => 'Medium';

  @override
  String get beatStrong => 'Strong';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get pureBlack => 'Pure black';

  @override
  String get pureBlackDesc => 'Black background in dark mode (OLED)';

  @override
  String get dynamicColor => 'System colors';

  @override
  String get dynamicColorDesc => 'Use your system\'s accent color';

  @override
  String get artworkColors => 'Colors from artwork';

  @override
  String get artworkColorsDesc => 'The player adapts its colors to the cover';

  @override
  String get accentColor => 'Accent color';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get playback => 'Playback';

  @override
  String get quality => 'Stream quality';

  @override
  String get qualityHigh => 'High';

  @override
  String get qualitySaver => 'Data saver';

  @override
  String get autoplay => 'Autoplay';

  @override
  String get autoplayDesc => 'Keep playing similar tracks when the queue ends';

  @override
  String get network => 'Network';

  @override
  String get proxy => 'CORS proxy';

  @override
  String get proxyDesc => 'Required in the browser, because SoundCloud only allows its own website.';

  @override
  String get about => 'About';

  @override
  String get aboutText =>
      'Inspired by KittyTune by alan7383 and written from scratch in Flutter. Free software under GPL-3.0.';

  @override
  String get licenses => 'Open-source licenses';

  @override
  String get previewBadge => 'Preview (30s)';

  @override
  String get previewHint => 'SoundCloud only offers a 30-second preview of this track.';

  @override
  String get openInYtMusic => 'Open in YouTube Music';

  @override
  String get skipPreviews => 'Skip previews';

  @override
  String get skipPreviewsDesc => 'Skip 30-second previews when the queue moves on';

  @override
  String get fastStart => 'Fast start';

  @override
  String get fastStartDesc =>
      'Tapped tracks start as MP3 128 kbit/s – faster, slightly lower quality. Pre-buffered tracks keep the chosen quality.';

  @override
  String get navDj => 'DJ';

  @override
  String get djHeadline => 'Your DJ';

  @override
  String get djIntro =>
      'Pick what you want to hear – Pounce mixes your likes and similar tracks, with transitions matched on key, tempo and drop.';

  @override
  String get djCategories => 'Categories';

  @override
  String get djBlend => 'Blend';

  @override
  String get djFavorites => 'Favorites';

  @override
  String get djDiscover => 'Discover';

  @override
  String get djLookahead => 'Analyse ahead';

  @override
  String djLookaheadDesc(int count, int mb) {
    return '$count songs ahead (~$mb MB)';
  }

  @override
  String get djStart => 'Start mix';

  @override
  String get djBuilding => 'Building your mix…';

  @override
  String get djNothing => 'Nothing suitable found – try another category.';

  @override
  String get djPickCategory => 'Pick at least one category';

  @override
  String djAnalyzed(int done, int total) {
    return '$done of $total songs analysed';
  }

  @override
  String djMixStarted(int count) {
    return 'Mix with $count songs started';
  }

  @override
  String get djStop => 'Stop DJ';

  @override
  String get djSkip => 'Skip (mixes over and learns)';

  @override
  String get srcAll => 'All';

  @override
  String get srcRadio => 'Web radio';

  @override
  String get radioSection => 'Live radio · Stations';

  @override
  String get radioFavorites => 'Favourite stations';

  @override
  String get radioTop => 'Most listened';

  @override
  String get radioAll => 'All stations';

  @override
  String get radioSource => 'Web radio';

  @override
  String get radioSourceDesc => 'Tens of thousands of stations from radio-browser.info. Off: no requests at all.';

  @override
  String get live => 'LIVE';

  @override
  String get updates => 'Updates';

  @override
  String get updatesAuto => 'Check for updates automatically';

  @override
  String get updatesAutoDesc =>
      'At most once a day, one request to GitHub without any device ID. Never downloads by itself.';

  @override
  String get updatesCheck => 'Check now';

  @override
  String get updatesNone => 'Pounce is up to date';

  @override
  String get updatesUnavailable => 'Updates are not available in this build';

  @override
  String updateTitle(String version) {
    return 'Update to $version';
  }

  @override
  String updateDownload(String mb) {
    return 'Download & install ($mb MB)';
  }

  @override
  String get updateViaPlay => 'Update via Google Play';

  @override
  String get updateLater => 'Later';

  @override
  String get updateReleasePage => 'Release page';

  @override
  String get updateChecksumFailed => 'Checksum mismatch – the download was discarded.';

  @override
  String get updateNeedsPermission => 'Allow Pounce to install apps, then tap again.';

  @override
  String get updateFailed => 'Update failed – please try again later.';

  @override
  String get beta => 'Beta';

  @override
  String get betaNote => 'Pounce is in beta. Things may change or break – feedback on GitHub is very welcome.';

  @override
  String get setupWelcome => 'Welcome to Pounce';

  @override
  String get setupTagline => 'Fast music from SoundCloud and web radio – with a DJ that mixes for you.';

  @override
  String get setupStart => 'Let\'s go';

  @override
  String get setupNext => 'Next';

  @override
  String get setupBack => 'Back';

  @override
  String get setupSkip => 'Skip setup';

  @override
  String get setupDone => 'Start listening';

  @override
  String get setupSourcesTitle => 'Where should music come from?';

  @override
  String get setupSoundcloudDesc => 'Millions of tracks, mixes and remixes. Always on.';

  @override
  String get setupRadioDesc => '30,000+ stations via radio-browser.info. Off = no requests at all.';

  @override
  String get setupAccountTitle => 'Bring your likes along?';

  @override
  String get setupAccountDesc =>
      'Optional: sign in to SoundCloud to import likes and playlists. Pounce works fine without an account.';

  @override
  String get setupSignIn => 'Sign in to SoundCloud';

  @override
  String get setupDjTitle => 'What does your DJ play?';

  @override
  String get setupDjDesc => 'Pick a few styles. You can change them any time in the DJ tab.';

  @override
  String get setupPrivacyTitle => 'Your privacy';

  @override
  String get setupPrivacyDesc => 'No tracking, no ads, no device IDs. Everything below is off unless you turn it on.';

  @override
  String get setupRecognition => 'Song recognition (Echolot)';

  @override
  String get setupRecognitionDesc =>
      'Coming in a later beta. Would send only anonymous audio fingerprints – never recordings – to the Echolot server.';

  @override
  String get setupAgain => 'Run setup again';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String syncLast(int count) {
    return 'Synced ($count new events)';
  }

  @override
  String get syncTitle => 'Device sync';

  @override
  String get syncBackground => 'Background sync';

  @override
  String syncServerActive(int port) {
    return 'Server active (port $port) · peer-to-peer on your local network';
  }

  @override
  String get syncDisabled => 'Off';

  @override
  String get syncShowCode => 'Show pairing code';

  @override
  String get syncShowCodeDesc => 'Code for your other devices';

  @override
  String get syncCodeTitle => 'Pairing code';

  @override
  String get syncCodeHint => 'Enter this code on your other device:';

  @override
  String get syncCodeCopied => 'Pairing code copied';

  @override
  String get copy => 'Copy';

  @override
  String get done => 'Done';

  @override
  String get syncPair => 'Pair a device';

  @override
  String get syncNoPeers => 'No other device connected';

  @override
  String syncPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices paired',
      one: '1 device paired',
    );
    return '$_temp0';
  }

  @override
  String get syncPasteCode => 'Paste pairing code';

  @override
  String get syncPairAction => 'Pair';

  @override
  String get syncPaired => 'Paired!';

  @override
  String get syncPairFailed => 'Pairing failed';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncNever => 'Not synced yet';

  @override
  String get syncDone => 'Synced';

  @override
  String get engineTitle => 'Audio engine & performance';

  @override
  String engineRustDesc(String label) {
    return '$label · beat grid, key (chroma), loudness and AI fingerprint from real audio';
  }

  @override
  String get engineUnavailable => 'Not available – estimate from the waveform only';

  @override
  String get djFlowActiveDesc => 'Automatic phrase & key matching';

  @override
  String get djFlowAutomix => 'DJ Flow & Automix';

  @override
  String get djBpm => 'BPM';

  @override
  String get djTapToActivate => 'Tap to activate';

  @override
  String get djAnalyzing => 'Analysing audio…';

  @override
  String get djNoKey => 'No key detected';

  @override
  String get djKeyUncertain => 'uncertain';

  @override
  String djBar(int bar) {
    return 'Bar $bar/4';
  }

  @override
  String djPhraseBeat(int beat) {
    return 'Phrase beat $beat/16';
  }

  @override
  String get statGrid => 'Grid';

  @override
  String get statKey => 'Key';

  @override
  String get statLoudness => 'Loudness';

  @override
  String get statEnergy => 'Energy';

  @override
  String get statSource => 'Source';

  @override
  String get srcAudio => 'Audio';

  @override
  String get srcWaveform => 'Waveform';

  @override
  String get srcTitle => 'Title';

  @override
  String get djEnergiesLive => 'Audio energies (live)';

  @override
  String djTransitionIn(int beats) {
    return 'Transition in $beats beats';
  }

  @override
  String get djEnergyMode => 'Harmonic energy mode';

  @override
  String get djModeBuildUp => 'Build up';

  @override
  String get djModeHold => 'Hold';

  @override
  String get djModeWindDown => 'Cool down';

  @override
  String get djHarmonic => 'Harmonic';

  @override
  String get djNextBest => 'Next track (best match)';

  @override
  String djMatch(String pct) {
    return '$pct% match';
  }

  @override
  String get djMixNow => 'Mix now';

  @override
  String get bandBass => 'BASS (kick & sub)';

  @override
  String get bandMid => 'MID (vocals & melody)';

  @override
  String get bandHigh => 'HIGH (hi-hats & air)';

  @override
  String planDrop(String time) {
    return 'Drop $time';
  }

  @override
  String get planNoDrop => 'no drop';

  @override
  String get planSearching => 'looking for the drop…';

  @override
  String planText(String entry, String drop, String fade) {
    return 'Entry $entry · $drop · $fade s fade';
  }
}
