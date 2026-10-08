import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hu'),
    Locale('ru'),
    Locale('vi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Pounce'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @homeContinue.
  ///
  /// In en, this message translates to:
  /// **'Jump back in'**
  String get homeContinue;

  /// No description provided for @homeBecauseYouPlayed.
  ///
  /// In en, this message translates to:
  /// **'Because you played {title}'**
  String homeBecauseYouPlayed(String title);

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load content'**
  String get errorLoading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Songs, artists, playlists or links'**
  String get searchHint;

  /// No description provided for @searchRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecent;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Find something to play'**
  String get searchEmptyTitle;

  /// No description provided for @tabTracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get tabTracks;

  /// No description provided for @tabPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get tabPlaylists;

  /// No description provided for @tabAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get tabAlbums;

  /// No description provided for @tabArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get tabArtists;

  /// No description provided for @likedTracks.
  ///
  /// In en, this message translates to:
  /// **'Liked tracks'**
  String get likedTracks;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get newPlaylist;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get playlistName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deletePlaylistConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deletePlaylistConfirm(String name);

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @emptyLikes.
  ///
  /// In en, this message translates to:
  /// **'Tracks you like appear here'**
  String get emptyLikes;

  /// No description provided for @emptyHistory.
  ///
  /// In en, this message translates to:
  /// **'Nothing played yet'**
  String get emptyHistory;

  /// No description provided for @emptyPlaylist.
  ///
  /// In en, this message translates to:
  /// **'This playlist is empty'**
  String get emptyPlaylist;

  /// No description provided for @emptyPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Create playlists and add tracks via the ⋮ menu.'**
  String get emptyPlaylists;

  /// No description provided for @tracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tracks} =1{1 track} other{{count} tracks}}'**
  String tracksCount(int count);

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'{count} followers'**
  String followers(String count);

  /// No description provided for @playNext.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get playNext;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get addToQueue;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get addToPlaylist;

  /// No description provided for @removeFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get removeFromPlaylist;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @unlike.
  ///
  /// In en, this message translates to:
  /// **'Remove from likes'**
  String get unlike;

  /// No description provided for @goToArtist.
  ///
  /// In en, this message translates to:
  /// **'Go to artist'**
  String get goToArtist;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @addedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to queue'**
  String get addedToQueue;

  /// No description provided for @addedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added to {name}'**
  String addedToPlaylist(String name);

  /// No description provided for @alreadyInPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Already in {name}'**
  String alreadyInPlaylist(String name);

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyrics;

  /// No description provided for @noLyrics.
  ///
  /// In en, this message translates to:
  /// **'No lyrics found'**
  String get noLyrics;

  /// No description provided for @lyricsSource.
  ///
  /// In en, this message translates to:
  /// **'Lyrics: {source}'**
  String lyricsSource(String source);

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @sleepOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off timer'**
  String get sleepOff;

  /// No description provided for @sleepIn.
  ///
  /// In en, this message translates to:
  /// **'Stops in {minutes} min'**
  String sleepIn(int minutes);

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutes(int count);

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @repeatOff.
  ///
  /// In en, this message translates to:
  /// **'Repeat off'**
  String get repeatOff;

  /// No description provided for @repeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat all'**
  String get repeatAll;

  /// No description provided for @repeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat one'**
  String get repeatOne;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @popularTracks.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popularTracks;

  /// No description provided for @playbackError.
  ///
  /// In en, this message translates to:
  /// **'Can\'t play this track'**
  String get playbackError;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @protected.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get protected;

  /// No description provided for @protectedHint.
  ///
  /// In en, this message translates to:
  /// **'This track is DRM-protected and can’t be played in Pounce yet – even when signed in'**
  String get protectedHint;

  /// No description provided for @protectedPlayable.
  ///
  /// In en, this message translates to:
  /// **'DRM-protected – decrypted by your browser’s DRM module'**
  String get protectedPlayable;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign in with SoundCloud'**
  String get login;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync likes, playlists and your stream'**
  String get loginSubtitle;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signup;

  /// No description provided for @loginPrivacy.
  ///
  /// In en, this message translates to:
  /// **'You sign in on SoundCloud’s own page. Pounce never sees your password.'**
  String get loginPrivacy;

  /// No description provided for @loginWaiting.
  ///
  /// In en, this message translates to:
  /// **'Finish signing in in the browser…'**
  String get loginWaiting;

  /// No description provided for @loginReopen.
  ///
  /// In en, this message translates to:
  /// **'Open again'**
  String get loginReopen;

  /// No description provided for @loginPasteLabel.
  ///
  /// In en, this message translates to:
  /// **'Paste redirect link'**
  String get loginPasteLabel;

  /// No description provided for @loginPasteHint.
  ///
  /// In en, this message translates to:
  /// **'After signing in, SoundCloud redirects to a link starting with sc://auth?code=… If the app doesn’t pick it up automatically, copy it here.'**
  String get loginPasteHint;

  /// No description provided for @loginPasteHintWeb.
  ///
  /// In en, this message translates to:
  /// **'A new tab opens. After signing in it shows an address like soundcloud.com/signin/callback?code=… Copy that address and paste it here.'**
  String get loginPasteHintWeb;

  /// No description provided for @loginConfirm.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get loginConfirm;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed'**
  String get loginFailed;

  /// No description provided for @loggedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String loggedInAs(String name);

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out? Your likes stay on this device.'**
  String get logoutConfirm;

  /// No description provided for @homeStream.
  ///
  /// In en, this message translates to:
  /// **'Your stream'**
  String get homeStream;

  /// No description provided for @scPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Your SoundCloud playlists'**
  String get scPlaylists;

  /// No description provided for @transferLikes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Transfer 1 local like to your account?} other{Transfer {count} local likes to your account?}}'**
  String transferLikes(int count);

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @loudTitle.
  ///
  /// In en, this message translates to:
  /// **'Loudness mode'**
  String get loudTitle;

  /// No description provided for @loudDesc.
  ///
  /// In en, this message translates to:
  /// **'Evens out loud and quiet tracks (ITU-R BS.1770) with a built-in limiter against clipping.'**
  String get loudDesc;

  /// No description provided for @loudOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get loudOff;

  /// No description provided for @loudQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get loudQuiet;

  /// No description provided for @loudNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get loudNormal;

  /// No description provided for @loudLoud.
  ///
  /// In en, this message translates to:
  /// **'Loud'**
  String get loudLoud;

  /// No description provided for @loudUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Not available on this platform yet'**
  String get loudUnsupported;

  /// No description provided for @signal.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get signal;

  /// No description provided for @sigSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sigSource;

  /// No description provided for @sigLoudness.
  ///
  /// In en, this message translates to:
  /// **'Source loudness'**
  String get sigLoudness;

  /// No description provided for @sigMomentary.
  ///
  /// In en, this message translates to:
  /// **'Momentary'**
  String get sigMomentary;

  /// No description provided for @sigGain.
  ///
  /// In en, this message translates to:
  /// **'Gain'**
  String get sigGain;

  /// No description provided for @sigLimiter.
  ///
  /// In en, this message translates to:
  /// **'Limiter'**
  String get sigLimiter;

  /// No description provided for @sigOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get sigOutput;

  /// No description provided for @sigAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get sigAnalysis;

  /// No description provided for @sigLive.
  ///
  /// In en, this message translates to:
  /// **'Live FFT'**
  String get sigLive;

  /// No description provided for @sigEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Waveform envelope'**
  String get sigEnvelope;

  /// No description provided for @sigClip.
  ///
  /// In en, this message translates to:
  /// **'Clipping'**
  String get sigClip;

  /// No description provided for @sigClean.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get sigClean;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @inspector.
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get inspector;

  /// No description provided for @expandPlayer.
  ///
  /// In en, this message translates to:
  /// **'Focus view'**
  String get expandPlayer;

  /// No description provided for @expandRail.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get expandRail;

  /// No description provided for @collapseRail.
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get collapseRail;

  /// No description provided for @accentAmber.
  ///
  /// In en, this message translates to:
  /// **'Electric Amber'**
  String get accentAmber;

  /// No description provided for @accentCyan.
  ///
  /// In en, this message translates to:
  /// **'Cryo Cyan'**
  String get accentCyan;

  /// No description provided for @accentCover.
  ///
  /// In en, this message translates to:
  /// **'From artwork'**
  String get accentCover;

  /// No description provided for @beatBg.
  ///
  /// In en, this message translates to:
  /// **'Background in time with the beat'**
  String get beatBg;

  /// No description provided for @beatBgDesc.
  ///
  /// In en, this message translates to:
  /// **'Colors pulse and change with every detected beat'**
  String get beatBgDesc;

  /// No description provided for @beatLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get beatLight;

  /// No description provided for @beatMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get beatMedium;

  /// No description provided for @beatStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get beatStrong;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @pureBlack.
  ///
  /// In en, this message translates to:
  /// **'Pure black'**
  String get pureBlack;

  /// No description provided for @pureBlackDesc.
  ///
  /// In en, this message translates to:
  /// **'Black background in dark mode (OLED)'**
  String get pureBlackDesc;

  /// No description provided for @dynamicColor.
  ///
  /// In en, this message translates to:
  /// **'System colors'**
  String get dynamicColor;

  /// No description provided for @dynamicColorDesc.
  ///
  /// In en, this message translates to:
  /// **'Use your system\'s accent color'**
  String get dynamicColorDesc;

  /// No description provided for @artworkColors.
  ///
  /// In en, this message translates to:
  /// **'Colors from artwork'**
  String get artworkColors;

  /// No description provided for @artworkColorsDesc.
  ///
  /// In en, this message translates to:
  /// **'The player adapts its colors to the cover'**
  String get artworkColorsDesc;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @playback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playback;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Stream quality'**
  String get quality;

  /// No description provided for @qualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get qualityHigh;

  /// No description provided for @qualitySaver.
  ///
  /// In en, this message translates to:
  /// **'Data saver'**
  String get qualitySaver;

  /// No description provided for @autoplay.
  ///
  /// In en, this message translates to:
  /// **'Autoplay'**
  String get autoplay;

  /// No description provided for @autoplayDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep playing similar tracks when the queue ends'**
  String get autoplayDesc;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @proxy.
  ///
  /// In en, this message translates to:
  /// **'CORS proxy'**
  String get proxy;

  /// No description provided for @proxyDesc.
  ///
  /// In en, this message translates to:
  /// **'Required in the browser, because SoundCloud only allows its own website.'**
  String get proxyDesc;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'Inspired by KittyTune by alan7383 and written from scratch in Flutter. Free software under GPL-3.0.'**
  String get aboutText;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get licenses;

  /// No description provided for @previewBadge.
  ///
  /// In en, this message translates to:
  /// **'Preview (30s)'**
  String get previewBadge;

  /// No description provided for @previewHint.
  ///
  /// In en, this message translates to:
  /// **'SoundCloud only offers a 30-second preview of this track.'**
  String get previewHint;

  /// No description provided for @openInYtMusic.
  ///
  /// In en, this message translates to:
  /// **'Open in YouTube Music'**
  String get openInYtMusic;

  /// No description provided for @skipPreviews.
  ///
  /// In en, this message translates to:
  /// **'Skip previews'**
  String get skipPreviews;

  /// No description provided for @skipPreviewsDesc.
  ///
  /// In en, this message translates to:
  /// **'Skip 30-second previews when the queue moves on'**
  String get skipPreviewsDesc;

  /// No description provided for @fastStart.
  ///
  /// In en, this message translates to:
  /// **'Fast start'**
  String get fastStart;

  /// No description provided for @fastStartDesc.
  ///
  /// In en, this message translates to:
  /// **'Tapped tracks start as MP3 128 kbit/s – faster, slightly lower quality. Pre-buffered tracks keep the chosen quality.'**
  String get fastStartDesc;

  /// No description provided for @navDj.
  ///
  /// In en, this message translates to:
  /// **'DJ'**
  String get navDj;

  /// No description provided for @djHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your DJ'**
  String get djHeadline;

  /// No description provided for @djIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick what you want to hear – Pounce mixes your likes and similar tracks, with transitions matched on key, tempo and drop.'**
  String get djIntro;

  /// No description provided for @djCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get djCategories;

  /// No description provided for @djBlend.
  ///
  /// In en, this message translates to:
  /// **'Blend'**
  String get djBlend;

  /// No description provided for @djFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get djFavorites;

  /// No description provided for @djDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get djDiscover;

  /// No description provided for @djLookahead.
  ///
  /// In en, this message translates to:
  /// **'Analyse ahead'**
  String get djLookahead;

  /// No description provided for @djLookaheadDesc.
  ///
  /// In en, this message translates to:
  /// **'{count} songs ahead (~{mb} MB)'**
  String djLookaheadDesc(int count, int mb);

  /// No description provided for @djStart.
  ///
  /// In en, this message translates to:
  /// **'Start mix'**
  String get djStart;

  /// No description provided for @djBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building your mix…'**
  String get djBuilding;

  /// No description provided for @djNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing suitable found – try another category.'**
  String get djNothing;

  /// No description provided for @djPickCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one category'**
  String get djPickCategory;

  /// No description provided for @djAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} songs analysed'**
  String djAnalyzed(int done, int total);

  /// No description provided for @djMixStarted.
  ///
  /// In en, this message translates to:
  /// **'Mix with {count} songs started'**
  String djMixStarted(int count);

  /// No description provided for @djStop.
  ///
  /// In en, this message translates to:
  /// **'Stop DJ'**
  String get djStop;

  /// No description provided for @djSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip (mixes over and learns)'**
  String get djSkip;

  /// No description provided for @srcAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get srcAll;

  /// No description provided for @srcRadio.
  ///
  /// In en, this message translates to:
  /// **'Web radio'**
  String get srcRadio;

  /// No description provided for @radioSection.
  ///
  /// In en, this message translates to:
  /// **'Live radio · Stations'**
  String get radioSection;

  /// No description provided for @radioFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favourite stations'**
  String get radioFavorites;

  /// No description provided for @radioTop.
  ///
  /// In en, this message translates to:
  /// **'Most listened'**
  String get radioTop;

  /// No description provided for @radioAll.
  ///
  /// In en, this message translates to:
  /// **'All stations'**
  String get radioAll;

  /// No description provided for @radioSource.
  ///
  /// In en, this message translates to:
  /// **'Web radio'**
  String get radioSource;

  /// No description provided for @radioSourceDesc.
  ///
  /// In en, this message translates to:
  /// **'Tens of thousands of stations from radio-browser.info. Off: no requests at all.'**
  String get radioSourceDesc;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @updatesAuto.
  ///
  /// In en, this message translates to:
  /// **'Check for updates automatically'**
  String get updatesAuto;

  /// No description provided for @updatesAutoDesc.
  ///
  /// In en, this message translates to:
  /// **'At most once a day, one request to GitHub without any device ID. Never downloads by itself.'**
  String get updatesAutoDesc;

  /// No description provided for @updatesCheck.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get updatesCheck;

  /// No description provided for @updatesNone.
  ///
  /// In en, this message translates to:
  /// **'Pounce is up to date'**
  String get updatesNone;

  /// No description provided for @updatesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Updates are not available in this build'**
  String get updatesUnavailable;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update to {version}'**
  String updateTitle(String version);

  /// No description provided for @updateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download & install ({mb} MB)'**
  String updateDownload(String mb);

  /// No description provided for @updateViaPlay.
  ///
  /// In en, this message translates to:
  /// **'Update via Google Play'**
  String get updateViaPlay;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateReleasePage.
  ///
  /// In en, this message translates to:
  /// **'Release page'**
  String get updateReleasePage;

  /// No description provided for @updateChecksumFailed.
  ///
  /// In en, this message translates to:
  /// **'Checksum mismatch – the download was discarded.'**
  String get updateChecksumFailed;

  /// No description provided for @updateNeedsPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow Pounce to install apps, then tap again.'**
  String get updateNeedsPermission;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed – please try again later.'**
  String get updateFailed;

  /// No description provided for @beta.
  ///
  /// In en, this message translates to:
  /// **'Beta'**
  String get beta;

  /// No description provided for @betaNote.
  ///
  /// In en, this message translates to:
  /// **'Pounce is in beta. Things may change or break – feedback on GitHub is very welcome.'**
  String get betaNote;

  /// No description provided for @setupWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Pounce'**
  String get setupWelcome;

  /// No description provided for @setupTagline.
  ///
  /// In en, this message translates to:
  /// **'Fast music from SoundCloud and web radio – with a DJ that mixes for you.'**
  String get setupTagline;

  /// No description provided for @setupStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get setupStart;

  /// No description provided for @setupNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get setupNext;

  /// No description provided for @setupBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get setupBack;

  /// No description provided for @setupSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip setup'**
  String get setupSkip;

  /// No description provided for @setupDone.
  ///
  /// In en, this message translates to:
  /// **'Start listening'**
  String get setupDone;

  /// No description provided for @setupSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Where should music come from?'**
  String get setupSourcesTitle;

  /// No description provided for @setupSoundcloudDesc.
  ///
  /// In en, this message translates to:
  /// **'Millions of tracks, mixes and remixes. Always on.'**
  String get setupSoundcloudDesc;

  /// No description provided for @setupRadioDesc.
  ///
  /// In en, this message translates to:
  /// **'30,000+ stations via radio-browser.info. Off = no requests at all.'**
  String get setupRadioDesc;

  /// No description provided for @setupAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Bring your likes along?'**
  String get setupAccountTitle;

  /// No description provided for @setupAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Optional: sign in to SoundCloud to import likes and playlists. Pounce works fine without an account.'**
  String get setupAccountDesc;

  /// No description provided for @setupSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to SoundCloud'**
  String get setupSignIn;

  /// No description provided for @setupDjTitle.
  ///
  /// In en, this message translates to:
  /// **'What does your DJ play?'**
  String get setupDjTitle;

  /// No description provided for @setupDjDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick a few styles. You can change them any time in the DJ tab.'**
  String get setupDjDesc;

  /// No description provided for @setupPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy'**
  String get setupPrivacyTitle;

  /// No description provided for @setupPrivacyDesc.
  ///
  /// In en, this message translates to:
  /// **'No tracking, no ads, no device IDs. Everything below is off unless you turn it on.'**
  String get setupPrivacyDesc;

  /// No description provided for @setupRecognition.
  ///
  /// In en, this message translates to:
  /// **'Song recognition (Echolot)'**
  String get setupRecognition;

  /// No description provided for @setupRecognitionDesc.
  ///
  /// In en, this message translates to:
  /// **'Coming in a later beta. Would send only anonymous audio fingerprints – never recordings – to the Echolot server.'**
  String get setupRecognitionDesc;

  /// No description provided for @setupAgain.
  ///
  /// In en, this message translates to:
  /// **'Run setup again'**
  String get setupAgain;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @syncLast.
  ///
  /// In en, this message translates to:
  /// **'Synced ({count} new events)'**
  String syncLast(int count);

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Device sync'**
  String get syncTitle;

  /// No description provided for @syncBackground.
  ///
  /// In en, this message translates to:
  /// **'Background sync'**
  String get syncBackground;

  /// No description provided for @syncServerActive.
  ///
  /// In en, this message translates to:
  /// **'Server active (port {port}) · peer-to-peer on your local network'**
  String syncServerActive(int port);

  /// No description provided for @syncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get syncDisabled;

  /// No description provided for @syncShowCode.
  ///
  /// In en, this message translates to:
  /// **'Show pairing code'**
  String get syncShowCode;

  /// No description provided for @syncShowCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Code for your other devices'**
  String get syncShowCodeDesc;

  /// No description provided for @syncCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pairing code'**
  String get syncCodeTitle;

  /// No description provided for @syncCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter this code on your other device:'**
  String get syncCodeHint;

  /// No description provided for @syncCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Pairing code copied'**
  String get syncCodeCopied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @syncPair.
  ///
  /// In en, this message translates to:
  /// **'Pair a device'**
  String get syncPair;

  /// No description provided for @syncNoPeers.
  ///
  /// In en, this message translates to:
  /// **'No other device connected'**
  String get syncNoPeers;

  /// No description provided for @syncPeers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 device paired} other{{count} devices paired}}'**
  String syncPeers(int count);

  /// No description provided for @syncPasteCode.
  ///
  /// In en, this message translates to:
  /// **'Paste pairing code'**
  String get syncPasteCode;

  /// No description provided for @syncPairAction.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get syncPairAction;

  /// No description provided for @syncPaired.
  ///
  /// In en, this message translates to:
  /// **'Paired!'**
  String get syncPaired;

  /// No description provided for @syncPairFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing failed'**
  String get syncPairFailed;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncNever.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get syncNever;

  /// No description provided for @syncDone.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncDone;

  /// No description provided for @engineTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio engine & performance'**
  String get engineTitle;

  /// No description provided for @engineRustDesc.
  ///
  /// In en, this message translates to:
  /// **'{label} · beat grid, key (chroma), loudness and AI fingerprint from real audio'**
  String engineRustDesc(String label);

  /// No description provided for @engineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available – estimate from the waveform only'**
  String get engineUnavailable;

  /// No description provided for @djFlowActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatic phrase & key matching'**
  String get djFlowActiveDesc;

  /// No description provided for @djTapToActivate.
  ///
  /// In en, this message translates to:
  /// **'Tap to activate'**
  String get djTapToActivate;

  /// No description provided for @djAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analysing audio…'**
  String get djAnalyzing;

  /// No description provided for @djNoKey.
  ///
  /// In en, this message translates to:
  /// **'No key detected'**
  String get djNoKey;

  /// No description provided for @djKeyUncertain.
  ///
  /// In en, this message translates to:
  /// **'uncertain'**
  String get djKeyUncertain;

  /// No description provided for @djBar.
  ///
  /// In en, this message translates to:
  /// **'Bar {bar}/4'**
  String djBar(int bar);

  /// No description provided for @djPhraseBeat.
  ///
  /// In en, this message translates to:
  /// **'Phrase beat {beat}/16'**
  String djPhraseBeat(int beat);

  /// No description provided for @statGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get statGrid;

  /// No description provided for @statKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get statKey;

  /// No description provided for @statLoudness.
  ///
  /// In en, this message translates to:
  /// **'Loudness'**
  String get statLoudness;

  /// No description provided for @statEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get statEnergy;

  /// No description provided for @statSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get statSource;

  /// No description provided for @srcAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get srcAudio;

  /// No description provided for @srcWaveform.
  ///
  /// In en, this message translates to:
  /// **'Waveform'**
  String get srcWaveform;

  /// No description provided for @srcTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get srcTitle;

  /// No description provided for @djEnergiesLive.
  ///
  /// In en, this message translates to:
  /// **'Audio energies (live)'**
  String get djEnergiesLive;

  /// No description provided for @djTransitionIn.
  ///
  /// In en, this message translates to:
  /// **'Transition in {beats} beats'**
  String djTransitionIn(int beats);

  /// No description provided for @djEnergyMode.
  ///
  /// In en, this message translates to:
  /// **'Harmonic energy mode'**
  String get djEnergyMode;

  /// No description provided for @djModeBuildUp.
  ///
  /// In en, this message translates to:
  /// **'Build up'**
  String get djModeBuildUp;

  /// No description provided for @djModeHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get djModeHold;

  /// No description provided for @djModeWindDown.
  ///
  /// In en, this message translates to:
  /// **'Cool down'**
  String get djModeWindDown;

  /// No description provided for @djHarmonic.
  ///
  /// In en, this message translates to:
  /// **'Harmonic'**
  String get djHarmonic;

  /// No description provided for @djNextBest.
  ///
  /// In en, this message translates to:
  /// **'Next track (best match)'**
  String get djNextBest;

  /// No description provided for @djMatch.
  ///
  /// In en, this message translates to:
  /// **'{pct}% match'**
  String djMatch(String pct);

  /// No description provided for @djMixNow.
  ///
  /// In en, this message translates to:
  /// **'Mix now'**
  String get djMixNow;

  /// No description provided for @bandBass.
  ///
  /// In en, this message translates to:
  /// **'BASS (kick & sub)'**
  String get bandBass;

  /// No description provided for @bandMid.
  ///
  /// In en, this message translates to:
  /// **'MID (vocals & melody)'**
  String get bandMid;

  /// No description provided for @bandHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH (hi-hats & air)'**
  String get bandHigh;

  /// No description provided for @planDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop {time}'**
  String planDrop(String time);

  /// No description provided for @planNoDrop.
  ///
  /// In en, this message translates to:
  /// **'no drop'**
  String get planNoDrop;

  /// No description provided for @planSearching.
  ///
  /// In en, this message translates to:
  /// **'looking for the drop…'**
  String get planSearching;

  /// No description provided for @planText.
  ///
  /// In en, this message translates to:
  /// **'Entry {entry} · {drop} · {fade} s fade'**
  String planText(String entry, String drop, String fade);

  /// No description provided for @modules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get modules;

  /// No description provided for @modulesDesc.
  ///
  /// In en, this message translates to:
  /// **'Sources and designs – switch on, off or add more'**
  String get modulesDesc;

  /// No description provided for @modulesSources.
  ///
  /// In en, this message translates to:
  /// **'Sources in this version'**
  String get modulesSources;

  /// No description provided for @modulesNoSources.
  ///
  /// In en, this message translates to:
  /// **'This version has no source modules – web radio and your library still work.'**
  String get modulesNoSources;

  /// No description provided for @modulesThemes.
  ///
  /// In en, this message translates to:
  /// **'Designs'**
  String get modulesThemes;

  /// No description provided for @themeDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get themeDefault;

  /// No description provided for @themeDefaultDesc.
  ///
  /// In en, this message translates to:
  /// **'Accent colour from the settings'**
  String get themeDefaultDesc;

  /// No description provided for @themeActive.
  ///
  /// In en, this message translates to:
  /// **'Design “{name}” is active – pick a colour to switch back'**
  String themeActive(String name);

  /// No description provided for @modulesCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get modulesCatalog;

  /// No description provided for @modulesBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse modules'**
  String get modulesBrowse;

  /// No description provided for @modulesBrowseDesc.
  ///
  /// In en, this message translates to:
  /// **'Loads the catalog from GitHub – one request, nothing about you is sent'**
  String get modulesBrowseDesc;

  /// No description provided for @moduleInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get moduleInstall;

  /// No description provided for @moduleRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get moduleRemove;

  /// No description provided for @moduleIncluded.
  ///
  /// In en, this message translates to:
  /// **'INCLUDED'**
  String get moduleIncluded;

  /// No description provided for @moduleNotInBuild.
  ///
  /// In en, this message translates to:
  /// **'NOT IN THIS VERSION'**
  String get moduleNotInBuild;

  /// No description provided for @moduleByline.
  ///
  /// In en, this message translates to:
  /// **'v{version} · by {author}'**
  String moduleByline(String version, String author);

  /// No description provided for @modulesDevelop.
  ///
  /// In en, this message translates to:
  /// **'For developers'**
  String get modulesDevelop;

  /// No description provided for @modulesDevelopTitle.
  ///
  /// In en, this message translates to:
  /// **'Build your own module'**
  String get modulesDevelopTitle;

  /// No description provided for @modulesDevelopDesc.
  ///
  /// In en, this message translates to:
  /// **'Designs, music sources and how to get them into the catalog'**
  String get modulesDevelopDesc;

  /// No description provided for @moduleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The module for this content is switched off or not part of this version'**
  String get moduleUnavailable;

  /// No description provided for @homeNoSources.
  ///
  /// In en, this message translates to:
  /// **'Find web radio stations in Search – more sources come as modules (Settings → Modules).'**
  String get homeNoSources;

  /// No description provided for @djNoSources.
  ///
  /// In en, this message translates to:
  /// **'DJ mixes need a music source module that supports them (Settings → Modules).'**
  String get djNoSources;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'de', 'en', 'es', 'fr', 'hu', 'ru', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hu':
      return AppLocalizationsHu();
    case 'ru':
      return AppLocalizationsRu();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
