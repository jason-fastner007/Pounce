// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Pounce';

  @override
  String get navHome => 'Accueil';

  @override
  String get navSearch => 'Recherche';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get greetingMorning => 'Bonjour';

  @override
  String get greetingAfternoon => 'Bon après-midi';

  @override
  String get greetingEvening => 'Bonsoir';

  @override
  String get homeContinue => 'Reprendre';

  @override
  String homeBecauseYouPlayed(String title) {
    return 'Parce que vous avez écouté $title';
  }

  @override
  String get errorLoading => 'Impossible de charger le contenu';

  @override
  String get retry => 'Réessayer';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get searchHint => 'Titres, artistes, playlists ou liens';

  @override
  String get searchRecent => 'Recherches récentes';

  @override
  String get searchEmptyTitle => 'Trouvez quelque chose à écouter';

  @override
  String get tabTracks => 'Titres';

  @override
  String get tabPlaylists => 'Playlists';

  @override
  String get tabAlbums => 'Albums';

  @override
  String get tabArtists => 'Artistes';

  @override
  String get likedTracks => 'Titres aimés';

  @override
  String get history => 'Historique';

  @override
  String get playlists => 'Playlists';

  @override
  String get newPlaylist => 'Nouvelle playlist';

  @override
  String get playlistName => 'Nom';

  @override
  String get create => 'Créer';

  @override
  String get cancel => 'Annuler';

  @override
  String get rename => 'Renommer';

  @override
  String get delete => 'Supprimer';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get clearHistory => 'Effacer l\'historique';

  @override
  String get emptyLikes => 'Les titres que vous aimez apparaissent ici';

  @override
  String get emptyHistory => 'Rien d\'écouté pour l\'instant';

  @override
  String get emptyPlaylist => 'Cette playlist est vide';

  @override
  String get emptyPlaylists =>
      'Créez des playlists et ajoutez des titres via le menu ⋮.';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '$count titre',
      zero: 'Aucun titre',
    );
    return '$_temp0';
  }

  @override
  String followers(String count) {
    return '$count abonnés';
  }

  @override
  String get playNext => 'Lire ensuite';

  @override
  String get addToQueue => 'Ajouter à la file d\'attente';

  @override
  String get addToPlaylist => 'Ajouter à une playlist';

  @override
  String get removeFromPlaylist => 'Retirer de la playlist';

  @override
  String get like => 'J\'aime';

  @override
  String get unlike => 'Retirer des titres aimés';

  @override
  String get goToArtist => 'Voir l\'artiste';

  @override
  String get copyLink => 'Copier le lien';

  @override
  String get linkCopied => 'Lien copié';

  @override
  String get addedToQueue => 'Ajouté à la file d\'attente';

  @override
  String addedToPlaylist(String name) {
    return 'Ajouté à $name';
  }

  @override
  String alreadyInPlaylist(String name) {
    return 'Déjà dans $name';
  }

  @override
  String get nowPlaying => 'En cours de lecture';

  @override
  String get queue => 'File d\'attente';

  @override
  String get lyrics => 'Paroles';

  @override
  String get noLyrics => 'Aucunes paroles trouvées';

  @override
  String lyricsSource(String source) {
    return 'Paroles : $source';
  }

  @override
  String get sleepTimer => 'Minuteur de veille';

  @override
  String get sleepOff => 'Désactiver le minuteur';

  @override
  String sleepIn(int minutes) {
    return 'Arrêt dans $minutes min';
  }

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get speed => 'Vitesse';

  @override
  String get shuffle => 'Aléatoire';

  @override
  String get repeatOff => 'Répétition désactivée';

  @override
  String get repeatAll => 'Tout répéter';

  @override
  String get repeatOne => 'Répéter un titre';

  @override
  String get play => 'Lire';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Suivant';

  @override
  String get previous => 'Précédent';

  @override
  String get popularTracks => 'Populaires';

  @override
  String get playbackError => 'Impossible de lire ce titre';

  @override
  String get preview => 'Extrait';

  @override
  String get protected => 'Protégé';

  @override
  String get protectedHint =>
      'Ce titre est protégé par DRM et ne peut pas encore être lu dans Pounce, même connecté';

  @override
  String get protectedPlayable =>
      'Protégé par DRM – déchiffré par le module DRM de votre navigateur';

  @override
  String get account => 'Compte';

  @override
  String get login => 'Se connecter avec SoundCloud';

  @override
  String get loginSubtitle =>
      'Synchroniser titres aimés, playlists et votre flux';

  @override
  String get signup => 'Créer un compte';

  @override
  String get loginPrivacy =>
      'La connexion se fait sur la page de SoundCloud. Pounce ne voit jamais votre mot de passe.';

  @override
  String get loginWaiting => 'Terminez la connexion dans le navigateur…';

  @override
  String get loginReopen => 'Rouvrir';

  @override
  String get loginPasteLabel => 'Coller le lien de redirection';

  @override
  String get loginPasteHint =>
      'Après la connexion, SoundCloud redirige vers un lien sc://auth?code=… Si l’app ne le reçoit pas automatiquement, collez-le ici.';

  @override
  String get loginPasteHintWeb =>
      'Un nouvel onglet s’ouvre. Après la connexion, il affiche une adresse du type soundcloud.com/signin/callback?code=… Copiez cette adresse et collez-la ici.';

  @override
  String get loginConfirm => 'Continuer';

  @override
  String get loginFailed => 'Échec de la connexion';

  @override
  String loggedInAs(String name) {
    return 'Connecté en tant que $name';
  }

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutConfirm =>
      'Se déconnecter ? Vos titres aimés restent sur cet appareil.';

  @override
  String get homeStream => 'Votre flux';

  @override
  String get scPlaylists => 'Vos playlists SoundCloud';

  @override
  String transferLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Transférer $count titres aimés locaux vers votre compte ?',
      one: 'Transférer $count titre aimé local vers votre compte ?',
    );
    return '$_temp0';
  }

  @override
  String get transfer => 'Transférer';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get loudTitle => 'Mode volume';

  @override
  String get loudDesc =>
      'Égalise les titres forts et faibles (ITU-R BS.1770) avec un limiteur intégré contre la saturation.';

  @override
  String get loudOff => 'Désactivé';

  @override
  String get loudQuiet => 'Faible';

  @override
  String get loudNormal => 'Normal';

  @override
  String get loudLoud => 'Fort';

  @override
  String get loudUnsupported => 'Pas encore disponible sur cette plateforme';

  @override
  String get signal => 'Signal';

  @override
  String get sigSource => 'Source';

  @override
  String get sigLoudness => 'Sonie source';

  @override
  String get sigMomentary => 'Instantanée';

  @override
  String get sigGain => 'Gain';

  @override
  String get sigLimiter => 'Limiteur';

  @override
  String get sigOutput => 'Sortie';

  @override
  String get sigAnalysis => 'Analyse';

  @override
  String get sigLive => 'FFT en direct';

  @override
  String get sigEnvelope => 'Enveloppe de la forme d’onde';

  @override
  String get sigClip => 'Saturation';

  @override
  String get sigClean => 'Propre';

  @override
  String get volume => 'Volume';

  @override
  String get mute => 'Muet';

  @override
  String get inspector => 'Inspecteur';

  @override
  String get expandPlayer => 'Vue concentrée';

  @override
  String get expandRail => 'Déplier la barre';

  @override
  String get collapseRail => 'Replier la barre';

  @override
  String get accentAmber => 'Ambre électrique';

  @override
  String get accentCyan => 'Cyan cryo';

  @override
  String get accentCover => 'Selon la pochette';

  @override
  String get beatBg => 'Arrière-plan en rythme';

  @override
  String get beatBgDesc =>
      'Les couleurs pulsent et changent à chaque temps détecté';

  @override
  String get beatLight => 'Léger';

  @override
  String get beatMedium => 'Moyen';

  @override
  String get beatStrong => 'Fort';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get pureBlack => 'Noir pur';

  @override
  String get pureBlackDesc => 'Fond noir en mode sombre (OLED)';

  @override
  String get dynamicColor => 'Couleurs du système';

  @override
  String get dynamicColorDesc =>
      'Utiliser la couleur d\'accentuation du système';

  @override
  String get artworkColors => 'Couleurs de la pochette';

  @override
  String get artworkColorsDesc =>
      'Le lecteur adapte ses couleurs à la pochette';

  @override
  String get accentColor => 'Couleur d\'accentuation';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get playback => 'Lecture';

  @override
  String get quality => 'Qualité du streaming';

  @override
  String get qualityHigh => 'Élevée';

  @override
  String get qualitySaver => 'Économie de données';

  @override
  String get autoplay => 'Lecture automatique';

  @override
  String get autoplayDesc =>
      'Continuer avec des titres similaires à la fin de la file';

  @override
  String get network => 'Réseau';

  @override
  String get proxy => 'Proxy CORS';

  @override
  String get proxyDesc =>
      'Nécessaire dans le navigateur, car SoundCloud n\'autorise que son propre site.';

  @override
  String get about => 'À propos';

  @override
  String get aboutText =>
      'Inspiré de KittyTune (alan7383), entièrement réécrit en Flutter. Logiciel libre sous GPL-3.0.';

  @override
  String get licenses => 'Licences open source';

  @override
  String get previewBadge => 'Extrait (30 s)';

  @override
  String get previewHint =>
      'SoundCloud ne propose qu’un extrait de 30 secondes de ce titre.';

  @override
  String get openInYtMusic => 'Ouvrir dans YouTube Music';

  @override
  String get skipPreviews => 'Ignorer les extraits';

  @override
  String get skipPreviewsDesc =>
      'Ignorer les extraits de 30 secondes lors du passage au titre suivant';

  @override
  String get fastStart => 'Démarrage rapide';

  @override
  String get fastStartDesc =>
      'Les titres touchés démarrent en MP3 128 kbit/s – plus rapide, qualité un peu moindre. Les titres préchargés gardent la qualité choisie.';

  @override
  String get navDj => 'DJ';

  @override
  String get djHeadline => 'Ton DJ';

  @override
  String get djIntro =>
      'Choisis ce que tu veux écouter – Pounce mixe tes favoris et des titres similaires, avec des transitions calées sur la tonalité, le tempo et le drop.';

  @override
  String get djCategories => 'Catégories';

  @override
  String get djBlend => 'Mélange';

  @override
  String get djFavorites => 'Favoris';

  @override
  String get djDiscover => 'Découvrir';

  @override
  String get djLookahead => 'Analyse anticipée';

  @override
  String djLookaheadDesc(int count, int mb) {
    return '$count titres à l’avance (~$mb Mo)';
  }

  @override
  String get djStart => 'Lancer le mix';

  @override
  String get djBuilding => 'Création du mix…';

  @override
  String get djNothing => 'Rien trouvé – essaie une autre catégorie.';

  @override
  String get djPickCategory => 'Choisis au moins une catégorie';

  @override
  String djAnalyzed(int done, int total) {
    return '$done titres sur $total analysés';
  }

  @override
  String djMixStarted(int count) {
    return 'Mix de $count titres lancé';
  }

  @override
  String get djStop => 'Arrêter le DJ';

  @override
  String get djSkip => 'Passer (mixe et apprend)';

  @override
  String get srcAll => 'Tout';

  @override
  String get srcRadio => 'Webradio';

  @override
  String get radioSection => 'Radio en direct · Stations';

  @override
  String get radioFavorites => 'Stations favorites';

  @override
  String get radioTop => 'Les plus écoutées';

  @override
  String get radioAll => 'Toutes les stations';

  @override
  String get radioSource => 'Webradio';

  @override
  String get radioSourceDesc =>
      'Des dizaines de milliers de stations de radio-browser.info. Désactivé : aucune requête.';

  @override
  String get live => 'DIRECT';

  @override
  String get updates => 'Mises à jour';

  @override
  String get updatesAuto => 'Rechercher les mises à jour automatiquement';

  @override
  String get updatesAutoDesc =>
      'Au plus une fois par jour, une requête à GitHub sans identifiant d’appareil. Ne télécharge jamais seul.';

  @override
  String get updatesCheck => 'Vérifier';

  @override
  String get updatesNone => 'Pounce est à jour';

  @override
  String get updatesUnavailable => 'Pas de mises à jour dans cette version';

  @override
  String updateTitle(String version) {
    return 'Mise à jour vers $version';
  }

  @override
  String updateDownload(String mb) {
    return 'Télécharger et installer ($mb Mo)';
  }

  @override
  String get updateViaPlay => 'Mettre à jour via Google Play';

  @override
  String get updateLater => 'Plus tard';

  @override
  String get updateReleasePage => 'Page de la version';

  @override
  String get updateChecksumFailed =>
      'Somme de contrôle incorrecte – le téléchargement a été supprimé.';

  @override
  String get updateNeedsPermission =>
      'Autorise Pounce à installer des applis, puis réessaie.';

  @override
  String get updateFailed => 'Échec de la mise à jour – réessaie plus tard.';

  @override
  String get beta => 'Bêta';

  @override
  String get betaNote =>
      'Pounce est en bêta. Certaines choses peuvent changer ou casser – vos retours sur GitHub sont les bienvenus.';

  @override
  String get setupWelcome => 'Bienvenue dans Pounce';

  @override
  String get setupTagline =>
      'De la musique rapide depuis SoundCloud et la radio web – avec un DJ qui mixe pour vous.';

  @override
  String get setupStart => 'C\'est parti';

  @override
  String get setupNext => 'Suivant';

  @override
  String get setupBack => 'Retour';

  @override
  String get setupSkip => 'Passer la configuration';

  @override
  String get setupDone => 'Commencer à écouter';

  @override
  String get setupSourcesTitle => 'D\'où doit venir la musique ?';

  @override
  String get setupSoundcloudDesc =>
      'Des millions de titres, mixes et remixes. Toujours actif.';

  @override
  String get setupRadioDesc =>
      'Plus de 30 000 stations via radio-browser.info. Désactivé = aucune requête.';

  @override
  String get setupAccountTitle => 'Importer vos titres aimés ?';

  @override
  String get setupAccountDesc =>
      'Facultatif : connectez-vous à SoundCloud pour importer titres aimés et playlists. Pounce fonctionne aussi sans compte.';

  @override
  String get setupSignIn => 'Se connecter à SoundCloud';

  @override
  String get setupDjTitle => 'Que doit jouer votre DJ ?';

  @override
  String get setupDjDesc =>
      'Choisissez quelques styles. Modifiables à tout moment dans l\'onglet DJ.';

  @override
  String get setupPrivacyTitle => 'Votre vie privée';

  @override
  String get setupPrivacyDesc =>
      'Pas de pistage, pas de pub, pas d\'identifiant d\'appareil. Tout est désactivé tant que vous ne l\'activez pas.';

  @override
  String get setupRecognition => 'Reconnaissance musicale (Echolot)';

  @override
  String get setupRecognitionDesc =>
      'Arrive dans une prochaine bêta. N\'enverrait que des empreintes audio anonymes – jamais d\'enregistrements – au serveur Echolot.';

  @override
  String get setupAgain => 'Relancer la configuration';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String syncLast(int count) {
    return 'Synchronisé ($count nouveaux événements)';
  }

  @override
  String get syncTitle => 'Synchronisation des appareils';

  @override
  String get syncBackground => 'Synchronisation en arrière-plan';

  @override
  String syncServerActive(int port) {
    return 'Serveur actif (port $port) · pair-à-pair sur votre réseau local';
  }

  @override
  String get syncDisabled => 'Désactivé';

  @override
  String get syncShowCode => 'Afficher le code d\'appairage';

  @override
  String get syncShowCodeDesc => 'Code pour vos autres appareils';

  @override
  String get syncCodeTitle => 'Code d\'appairage';

  @override
  String get syncCodeHint => 'Saisissez ce code sur votre autre appareil :';

  @override
  String get syncCodeCopied => 'Code d\'appairage copié';

  @override
  String get copy => 'Copier';

  @override
  String get done => 'Terminé';

  @override
  String get syncPair => 'Associer un appareil';

  @override
  String get syncNoPeers => 'Aucun autre appareil connecté';

  @override
  String syncPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appareils associés',
      one: '1 appareil associé',
    );
    return '$_temp0';
  }

  @override
  String get syncPasteCode => 'Collez le code d\'appairage';

  @override
  String get syncPairAction => 'Associer';

  @override
  String get syncPaired => 'Appairé !';

  @override
  String get syncPairFailed => 'Échec de l\'appairage';

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get syncNever => 'Pas encore synchronisé';

  @override
  String get syncDone => 'Synchronisé';

  @override
  String get engineTitle => 'Moteur audio et performances';

  @override
  String engineRustDesc(String label) {
    return '$label · grille rythmique, tonalité (chroma), loudness et empreinte IA à partir de l\'audio réel';
  }

  @override
  String get engineUnavailable =>
      'Indisponible – estimation à partir de la forme d\'onde uniquement';

  @override
  String get djFlowActiveDesc => 'Calage automatique des phrases et tonalités';

  @override
  String get djFlowAutomix => 'DJ Flow & Automix';

  @override
  String get djBpm => 'BPM';

  @override
  String get djTapToActivate => 'Touchez pour activer';

  @override
  String get djAnalyzing => 'Analyse de l\'audio…';

  @override
  String get djNoKey => 'Aucune tonalité détectée';

  @override
  String get djKeyUncertain => 'incertain';

  @override
  String djBar(int bar) {
    return 'Mesure $bar/4';
  }

  @override
  String djPhraseBeat(int beat) {
    return 'Temps de phrase $beat/16';
  }

  @override
  String get statGrid => 'Grille';

  @override
  String get statKey => 'Tonalité';

  @override
  String get statLoudness => 'Loudness';

  @override
  String get statEnergy => 'Énergie';

  @override
  String get statSource => 'Source';

  @override
  String get srcAudio => 'Audio';

  @override
  String get srcWaveform => 'Forme d\'onde';

  @override
  String get srcTitle => 'Titre';

  @override
  String get djEnergiesLive => 'Énergies audio (direct)';

  @override
  String djTransitionIn(int beats) {
    return 'Transition dans $beats temps';
  }

  @override
  String get djEnergyMode => 'Mode d\'énergie harmonique';

  @override
  String get djModeBuildUp => 'Monter';

  @override
  String get djModeHold => 'Maintenir';

  @override
  String get djModeWindDown => 'Redescendre';

  @override
  String get djHarmonic => 'Harmonique';

  @override
  String get djNextBest => 'Titre suivant (meilleur accord)';

  @override
  String djMatch(String pct) {
    return '$pct % d\'accord';
  }

  @override
  String get djMixNow => 'Mixer maintenant';

  @override
  String get bandBass => 'BASSES (kick & sub)';

  @override
  String get bandMid => 'MÉDIUMS (voix & mélodie)';

  @override
  String get bandHigh => 'AIGUS (charleston & air)';

  @override
  String planDrop(String time) {
    return 'Drop $time';
  }

  @override
  String get planNoDrop => 'pas de drop';

  @override
  String get planSearching => 'recherche du drop…';

  @override
  String planText(String entry, String drop, String fade) {
    return 'Entrée $entry · $drop · fondu $fade s';
  }
}
