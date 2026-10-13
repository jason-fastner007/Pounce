// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Pounce';

  @override
  String get navHome => 'Inicio';

  @override
  String get navSearch => 'Buscar';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get greetingMorning => 'Buenos días';

  @override
  String get greetingAfternoon => 'Buenas tardes';

  @override
  String get greetingEvening => 'Buenas noches';

  @override
  String get homeContinue => 'Volver a escuchar';

  @override
  String homeBecauseYouPlayed(String title) {
    return 'Porque escuchaste $title';
  }

  @override
  String get errorLoading => 'No se pudo cargar el contenido';

  @override
  String get retry => 'Reintentar';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get searchHint => 'Canciones, artistas, listas o enlaces';

  @override
  String get searchRecent => 'Búsquedas recientes';

  @override
  String get searchEmptyTitle => 'Encuentra algo para escuchar';

  @override
  String get tabTracks => 'Pistas';

  @override
  String get tabPlaylists => 'Listas';

  @override
  String get tabAlbums => 'Álbumes';

  @override
  String get tabArtists => 'Artistas';

  @override
  String get likedTracks => 'Pistas favoritas';

  @override
  String get history => 'Historial';

  @override
  String get playlists => 'Listas de reproducción';

  @override
  String get newPlaylist => 'Nueva lista';

  @override
  String get playlistName => 'Nombre';

  @override
  String get create => 'Crear';

  @override
  String get cancel => 'Cancelar';

  @override
  String get rename => 'Renombrar';

  @override
  String get delete => 'Eliminar';

  @override
  String deletePlaylistConfirm(String name) {
    return '¿Eliminar «$name»?';
  }

  @override
  String get clearHistory => 'Borrar historial';

  @override
  String get emptyLikes => 'Las pistas que te gusten aparecerán aquí';

  @override
  String get emptyHistory => 'Aún no has escuchado nada';

  @override
  String get emptyPlaylist => 'Esta lista está vacía';

  @override
  String get emptyPlaylists => 'Crea listas y añade pistas mediante el menú ⋮.';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pistas',
      one: '1 pista',
      zero: 'Sin pistas',
    );
    return '$_temp0';
  }

  @override
  String followers(String count) {
    return '$count seguidores';
  }

  @override
  String get playNext => 'Reproducir a continuación';

  @override
  String get addToQueue => 'Añadir a la cola';

  @override
  String get addToPlaylist => 'Añadir a la lista';

  @override
  String get removeFromPlaylist => 'Eliminar de la lista';

  @override
  String get like => 'Me gusta';

  @override
  String get unlike => 'Eliminar de me gusta';

  @override
  String get goToArtist => 'Ir al artista';

  @override
  String get copyLink => 'Copiar enlace';

  @override
  String get linkCopied => 'Enlace copiado';

  @override
  String get addedToQueue => 'Añadido a la cola';

  @override
  String addedToPlaylist(String name) {
    return 'Añadido a $name';
  }

  @override
  String alreadyInPlaylist(String name) {
    return 'Ya está en $name';
  }

  @override
  String get nowPlaying => 'Sonando ahora';

  @override
  String get queue => 'Cola';

  @override
  String get lyrics => 'Letra';

  @override
  String get noLyrics => 'No se encontró la letra';

  @override
  String lyricsSource(String source) {
    return 'Letra: $source';
  }

  @override
  String get sleepTimer => 'Temporizador';

  @override
  String get sleepOff => 'Desactivar temporizador';

  @override
  String sleepIn(int minutes) {
    return 'Se detiene en $minutes min';
  }

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get speed => 'Velocidad';

  @override
  String get shuffle => 'Aleatorio';

  @override
  String get repeatOff => 'Repetición desactivada';

  @override
  String get repeatAll => 'Repetir todo';

  @override
  String get repeatOne => 'Repetir una';

  @override
  String get play => 'Reproducir';

  @override
  String get pause => 'Pausa';

  @override
  String get next => 'Siguiente';

  @override
  String get previous => 'Anterior';

  @override
  String get popularTracks => 'Populares';

  @override
  String get playbackError => 'No se puede reproducir esta pista';

  @override
  String get preview => 'Muestra';

  @override
  String get protected => 'Protegido';

  @override
  String get protectedHint =>
      'Esta pista tiene protección DRM y aún no se puede reproducir en Pounce, ni siquiera con la sesión iniciada';

  @override
  String get protectedPlayable => 'Protegido por DRM: descifrado por el módulo DRM de tu navegador';

  @override
  String get account => 'Cuenta';

  @override
  String get login => 'Iniciar sesión con SoundCloud';

  @override
  String get loginSubtitle => 'Sincroniza tus me gusta, listas y tu feed';

  @override
  String get signup => 'Crear cuenta';

  @override
  String get loginPrivacy => 'Inicias sesión en la propia página de SoundCloud. Pounce nunca ve tu contraseña.';

  @override
  String get loginWaiting => 'Completa el inicio de sesión en el navegador…';

  @override
  String get loginReopen => 'Abrir de nuevo';

  @override
  String get loginPasteLabel => 'Pegar enlace de redirección';

  @override
  String get loginPasteHint =>
      'Tras iniciar sesión, SoundCloud redirige a un enlace que empieza por sc://auth?code=… Si la aplicación no lo detecta automáticamente, cópialo aquí.';

  @override
  String get loginPasteHintWeb =>
      'Se abrirá una nueva pestaña. Tras iniciar sesión, mostrará una dirección como soundcloud.com/signin/callback?code=… Copia esa dirección y pégala aquí.';

  @override
  String get loginConfirm => 'Continuar';

  @override
  String get loginFailed => 'Error al iniciar sesión';

  @override
  String loggedInAs(String name) {
    return 'Sesión iniciada como $name';
  }

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get logoutConfirm => '¿Cerrar sesión? Tus me gusta se mantendrán en este dispositivo.';

  @override
  String get homeStream => 'Tu feed';

  @override
  String get scPlaylists => 'Tus listas de SoundCloud';

  @override
  String transferLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Transferir $count me gusta locales a tu cuenta?',
      one: '¿Transferir 1 me gusta local a tu cuenta?',
    );
    return '$_temp0';
  }

  @override
  String get transfer => 'Transferir';

  @override
  String get notNow => 'Ahora no';

  @override
  String get loudTitle => 'Modo de volumen';

  @override
  String get loudDesc =>
      'Equilibra pistas altas y bajas (ITU-R BS.1770) con un limitador integrado contra la distorsión.';

  @override
  String get loudOff => 'Desactivado';

  @override
  String get loudQuiet => 'Bajo';

  @override
  String get loudNormal => 'Normal';

  @override
  String get loudLoud => 'Alto';

  @override
  String get loudUnsupported => 'Aún no disponible en esta plataforma';

  @override
  String get signal => 'Señal';

  @override
  String get sigSource => 'Fuente';

  @override
  String get sigLoudness => 'Volumen de la fuente';

  @override
  String get sigMomentary => 'Momentáneo';

  @override
  String get sigGain => 'Ganancia';

  @override
  String get sigLimiter => 'Limitador';

  @override
  String get sigOutput => 'Salida';

  @override
  String get sigAnalysis => 'Análisis';

  @override
  String get sigLive => 'FFT en vivo';

  @override
  String get sigEnvelope => 'Envolvente de forma de onda';

  @override
  String get sigClip => 'Saturación';

  @override
  String get sigClean => 'Limpia';

  @override
  String get volume => 'Volumen';

  @override
  String get mute => 'Silenciar';

  @override
  String get inspector => 'Inspector';

  @override
  String get expandPlayer => 'Vista enfocada';

  @override
  String get expandRail => 'Expandir barra lateral';

  @override
  String get collapseRail => 'Contraer barra lateral';

  @override
  String get accentAmber => 'Ámbar eléctrico';

  @override
  String get accentCyan => 'Cian crio';

  @override
  String get accentCover => 'De la carátula';

  @override
  String get beatBg => 'Fondo al ritmo del compás';

  @override
  String get beatBgDesc => 'Los colores palpitan y cambian con cada ritmo detectado';

  @override
  String get beatLight => 'Suave';

  @override
  String get beatMedium => 'Medio';

  @override
  String get beatStrong => 'Fuerte';

  @override
  String get appearance => 'Apariencia';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get pureBlack => 'Negro puro';

  @override
  String get pureBlackDesc => 'Fondo negro en modo oscuro (OLED)';

  @override
  String get dynamicColor => 'Colores del sistema';

  @override
  String get dynamicColorDesc => 'Usar el color de acento del sistema';

  @override
  String get artworkColors => 'Colores de la carátula';

  @override
  String get artworkColorsDesc => 'El reproductor adapta sus colores a la carátula';

  @override
  String get accentColor => 'Color de acento';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get playback => 'Reproducción';

  @override
  String get quality => 'Calidad de transmisión';

  @override
  String get qualityHigh => 'Alta';

  @override
  String get qualitySaver => 'Ahorro de datos';

  @override
  String get autoplay => 'Reproducción automática';

  @override
  String get autoplayDesc => 'Sigue reproduciendo pistas similares al terminar la cola';

  @override
  String get network => 'Red';

  @override
  String get proxy => 'Proxy CORS';

  @override
  String get proxyDesc => 'Necesario en el navegador, porque SoundCloud solo permite su propio sitio web.';

  @override
  String get about => 'Acerca de';

  @override
  String get aboutText =>
      'Inspirado en KittyTune por alan7383 y escrito desde cero en Flutter. Software libre bajo GPL-3.0.';

  @override
  String get licenses => 'Licencias de código abierto';

  @override
  String get previewBadge => 'Muestra (30 s)';

  @override
  String get previewHint => 'SoundCloud solo ofrece una muestra de 30 segundos de esta pista.';

  @override
  String get openInYtMusic => 'Abrir en YouTube Music';

  @override
  String get skipPreviews => 'Omitir muestras';

  @override
  String get skipPreviewsDesc => 'Omitir muestras de 30 segundos al avanzar en la cola';

  @override
  String get fastStart => 'Inicio rápido';

  @override
  String get fastStartDesc =>
      'Las pistas seleccionadas empiezan como MP3 a 128 kbit/s: más rápido, calidad ligeramente menor. Las pistas prealmacenadas mantienen la calidad elegida.';

  @override
  String get navDj => 'DJ';

  @override
  String get djHeadline => 'Tu DJ';

  @override
  String get djIntro =>
      'Elige lo que quieres escuchar: Pounce mezcla tus me gusta y pistas similares con transiciones ajustadas por tono, tempo y drop.';

  @override
  String get djCategories => 'Categorías';

  @override
  String get djBlend => 'Mezcla';

  @override
  String get djFavorites => 'Favoritos';

  @override
  String get djDiscover => 'Descubrir';

  @override
  String get djLookahead => 'Análisis anticipado';

  @override
  String djLookaheadDesc(int count, int mb) {
    return '$count canciones por adelantado (~$mb MB)';
  }

  @override
  String get djStart => 'Iniciar mezcla';

  @override
  String get djBuilding => 'Creando tu mezcla…';

  @override
  String get djNothing => 'No se encontró nada adecuado: prueba otra categoría.';

  @override
  String get djPickCategory => 'Elige al menos una categoría';

  @override
  String djAnalyzed(int done, int total) {
    return '$done de $total canciones analizadas';
  }

  @override
  String djMixStarted(int count) {
    return 'Mezcla con $count canciones iniciada';
  }

  @override
  String get djStop => 'Detener DJ';

  @override
  String get djSkip => 'Omitir (mezcla y aprende)';

  @override
  String get srcAll => 'Todo';

  @override
  String get srcRadio => 'Radio web';

  @override
  String get radioSection => 'Radio en vivo · Emisoras';

  @override
  String get radioFavorites => 'Emisoras favoritas';

  @override
  String get radioTop => 'Más escuchadas';

  @override
  String get radioAll => 'Todas las emisoras';

  @override
  String get radioSource => 'Radio web';

  @override
  String get radioSourceDesc => 'Decenas de miles de emisoras desde radio-browser.info. Desactivado: sin peticiones.';

  @override
  String get live => 'EN VIVO';

  @override
  String get updates => 'Actualizaciones';

  @override
  String get updatesAuto => 'Buscar actualizaciones automáticamente';

  @override
  String get updatesAutoDesc =>
      'Como máximo una vez al día, una petición a GitHub sin ID de dispositivo. Nunca descarga por sí solo.';

  @override
  String get updatesCheck => 'Comprobar ahora';

  @override
  String get updatesNone => 'Pounce está actualizado';

  @override
  String get updatesUnavailable => 'Las actualizaciones no están disponibles en esta versión';

  @override
  String updateTitle(String version) {
    return 'Actualizar a $version';
  }

  @override
  String updateDownload(String mb) {
    return 'Descargar e instalar ($mb MB)';
  }

  @override
  String get updateViaPlay => 'Actualizar vía Google Play';

  @override
  String get updateLater => 'Más tarde';

  @override
  String get updateReleasePage => 'Página de la versión';

  @override
  String get updateChecksumFailed => 'La suma de comprobación no coincide: se descartó la descarga.';

  @override
  String get updateNeedsPermission => 'Permite a Pounce instalar aplicaciones y vuelve a pulsar.';

  @override
  String get updateFailed => 'Error en la actualización: inténtalo de nuevo más tarde.';

  @override
  String get beta => 'Beta';

  @override
  String get betaNote =>
      'Pounce está en fase beta. Las cosas pueden cambiar o fallar; los comentarios en GitHub son muy bienvenidos.';

  @override
  String get setupWelcome => 'Te damos la bienvenida a Pounce';

  @override
  String get setupTagline => 'Música rápida de SoundCloud y radio web, con un DJ que mezcla para ti.';

  @override
  String get setupStart => 'Empezar';

  @override
  String get setupNext => 'Siguiente';

  @override
  String get setupBack => 'Atrás';

  @override
  String get setupSkip => 'Omitir configuración';

  @override
  String get setupDone => 'Empezar a escuchar';

  @override
  String get setupSourcesTitle => '¿De dónde debe venir la música?';

  @override
  String get setupSoundcloudDesc => 'Millones de pistas, mezclas y remixes. Siempre activo.';

  @override
  String get setupRadioDesc => 'Más de 30 000 emisoras a través de radio-browser.info. Desactivado = sin peticiones.';

  @override
  String get setupAccountTitle => '¿Quieres traer tus me gusta?';

  @override
  String get setupAccountDesc =>
      'Opcional: inicia sesión en SoundCloud para importar tus me gusta y listas. Pounce funciona perfectamente sin cuenta.';

  @override
  String get setupSignIn => 'Iniciar sesión en SoundCloud';

  @override
  String get setupDjTitle => '¿Qué debe poner tu DJ?';

  @override
  String get setupDjDesc => 'Elige algunos estilos. Puedes cambiarlos en cualquier momento en la pestaña DJ.';

  @override
  String get setupPrivacyTitle => 'Tu privacidad';

  @override
  String get setupPrivacyDesc =>
      'Sin rastreo, sin anuncios, sin ID de dispositivo. Todo lo siguiente está desactivado a menos que lo active.';

  @override
  String get setupRecognition => 'Reconocimiento de canciones (Echolot)';

  @override
  String get setupRecognitionDesc =>
      'Disponible en una beta posterior. Enviaría únicamente huellas de audio anónimas —nunca grabaciones— al servidor Echolot.';

  @override
  String get setupAgain => 'Ejecutar configuración de nuevo';

  @override
  String version(String version) {
    return 'Versión $version';
  }

  @override
  String syncLast(int count) {
    return 'Sincronizado ($count nuevos eventos)';
  }

  @override
  String get syncTitle => 'Sincronización de dispositivos';

  @override
  String get syncBackground => 'Sincronización en segundo plano';

  @override
  String syncServerActive(int port) {
    return 'Servidor activo (puerto $port) · peer-to-peer en tu red local';
  }

  @override
  String get syncDisabled => 'Desactivado';

  @override
  String get syncShowCode => 'Mostrar código de emparejamiento';

  @override
  String get syncShowCodeDesc => 'Código para tus otros dispositivos';

  @override
  String get syncCodeTitle => 'Código de emparejamiento';

  @override
  String get syncCodeHint => 'Introduce este código en tu otro dispositivo:';

  @override
  String get syncCodeCopied => 'Código de emparejamiento copiado';

  @override
  String get copy => 'Copiar';

  @override
  String get done => 'Hecho';

  @override
  String get syncPair => 'Emparejar un dispositivo';

  @override
  String get syncNoPeers => 'Ningún otro dispositivo conectado';

  @override
  String syncPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivos emparejados',
      one: '1 dispositivo emparejado',
    );
    return '$_temp0';
  }

  @override
  String get syncPasteCode => 'Pegar código de emparejamiento';

  @override
  String get syncPairAction => 'Emparejar';

  @override
  String get syncPaired => '¡Emparejado!';

  @override
  String get syncPairFailed => 'Error de emparejamiento';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get syncNever => 'Aún no sincronizado';

  @override
  String get syncDone => 'Sincronizado';

  @override
  String get engineTitle => 'Motor de audio y rendimiento';

  @override
  String engineRustDesc(String label) {
    return '$label · cuadrícula de compás, tono (chroma), volumen y huella de IA desde audio real';
  }

  @override
  String get engineUnavailable => 'No disponible: estimación solo a partir de la forma de onda';

  @override
  String get djFlowActiveDesc => 'Ajuste automático de frases y tonos';

  @override
  String get djTapToActivate => 'Toca para activar';

  @override
  String get djAnalyzing => 'Analizando audio…';

  @override
  String get djNoKey => 'No se detectó tono';

  @override
  String get djKeyUncertain => 'incierto';

  @override
  String djBar(int bar) {
    return 'Compás $bar/4';
  }

  @override
  String djPhraseBeat(int beat) {
    return 'Tiempo de frase $beat/16';
  }

  @override
  String get statGrid => 'Cuadrícula';

  @override
  String get statKey => 'Tono';

  @override
  String get statLoudness => 'Volumen';

  @override
  String get statEnergy => 'Energía';

  @override
  String get statSource => 'Fuente';

  @override
  String get srcAudio => 'Audio';

  @override
  String get srcWaveform => 'Forma de onda';

  @override
  String get srcTitle => 'Título';

  @override
  String get djEnergiesLive => 'Energías de audio (en vivo)';

  @override
  String djTransitionIn(int beats) {
    return 'Transición en $beats tiempos';
  }

  @override
  String get djEnergyMode => 'Modo de energía armónica';

  @override
  String get djModeBuildUp => 'Subida';

  @override
  String get djModeHold => 'Mantenimiento';

  @override
  String get djModeWindDown => 'Bajada';

  @override
  String get djHarmonic => 'Armónico';

  @override
  String get djNextBest => 'Siguiente pista (mejor combinación)';

  @override
  String djMatch(String pct) {
    return '$pct% de coincidencia';
  }

  @override
  String get djMixNow => 'Mezclar ahora';

  @override
  String get bandBass => 'GRAVES (kick & sub)';

  @override
  String get bandMid => 'MEDIOS (voces & melodía)';

  @override
  String get bandHigh => 'AGUDOS (hi-hats & aire)';

  @override
  String planDrop(String time) {
    return 'Drop $time';
  }

  @override
  String get planNoDrop => 'sin drop';

  @override
  String get planSearching => 'buscando el drop…';

  @override
  String planText(String entry, String drop, String fade) {
    return 'Entrada $entry · $drop · fundido de $fade s';
  }
}
