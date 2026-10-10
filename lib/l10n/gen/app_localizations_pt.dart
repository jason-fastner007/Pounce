// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Pounce';

  @override
  String get navHome => 'Início';

  @override
  String get navSearch => 'Pesquisar';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navSettings => 'Definições';

  @override
  String get greetingMorning => 'Bom dia';

  @override
  String get greetingAfternoon => 'Boa tarde';

  @override
  String get greetingEvening => 'Boa noite';

  @override
  String get homeContinue => 'Voltar a ouvir';

  @override
  String homeBecauseYouPlayed(String title) {
    return 'Porque ouviu $title';
  }

  @override
  String get errorLoading => 'Não foi possível carregar o conteúdo';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get noResults => 'Sem resultados';

  @override
  String get searchHint => 'Músicas, artistas, listas de reprodução ou links';

  @override
  String get searchRecent => 'Pesquisas recentes';

  @override
  String get searchEmptyTitle => 'Encontre algo para ouvir';

  @override
  String get tabTracks => 'Faixas';

  @override
  String get tabPlaylists => 'Listas de reprodução';

  @override
  String get tabAlbums => 'Álbuns';

  @override
  String get tabArtists => 'Artistas';

  @override
  String get likedTracks => 'Faixas favoritas';

  @override
  String get history => 'Histórico';

  @override
  String get playlists => 'Listas de reprodução';

  @override
  String get newPlaylist => 'Nova lista de reprodução';

  @override
  String get playlistName => 'Nome';

  @override
  String get create => 'Criar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get rename => 'Mudar o nome';

  @override
  String get delete => 'Eliminar';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Eliminar «$name»?';
  }

  @override
  String get clearHistory => 'Limpar histórico';

  @override
  String get emptyLikes => 'As faixas de que gosta aparecem aqui';

  @override
  String get emptyHistory => 'Ainda não ouviu nada';

  @override
  String get emptyPlaylist => 'Esta lista de reprodução está vazia';

  @override
  String get emptyPlaylists => 'Crie listas de reprodução e adicione faixas através do menu ⋮.';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas',
      one: '1 faixa',
      zero: 'Nenhuma faixa',
    );
    return '$_temp0';
  }

  @override
  String followers(String count) {
    return '$count seguidores';
  }

  @override
  String get playNext => 'Reproduzir a seguir';

  @override
  String get addToQueue => 'Adicionar à fila';

  @override
  String get addToPlaylist => 'Adicionar à lista de reprodução';

  @override
  String get removeFromPlaylist => 'Remover da lista de reprodução';

  @override
  String get like => 'Gostar';

  @override
  String get unlike => 'Remover dos gostos';

  @override
  String get goToArtist => 'Ir para o artista';

  @override
  String get copyLink => 'Copiar link';

  @override
  String get linkCopied => 'Link copiado';

  @override
  String get addedToQueue => 'Adicionado à fila';

  @override
  String addedToPlaylist(String name) {
    return 'Adicionado a $name';
  }

  @override
  String alreadyInPlaylist(String name) {
    return 'Já está em $name';
  }

  @override
  String get nowPlaying => 'A reproduzir agora';

  @override
  String get queue => 'Fila de reprodução';

  @override
  String get lyrics => 'Letra';

  @override
  String get noLyrics => 'Nenhuma letra encontrada';

  @override
  String lyricsSource(String source) {
    return 'Letra: $source';
  }

  @override
  String get sleepTimer => 'Temporizador';

  @override
  String get sleepOff => 'Desativar temporizador';

  @override
  String sleepIn(int minutes) {
    return 'Para em $minutes min';
  }

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get speed => 'Velocidade';

  @override
  String get shuffle => 'Aleatório';

  @override
  String get repeatOff => 'Repetição desativada';

  @override
  String get repeatAll => 'Repetir tudo';

  @override
  String get repeatOne => 'Repetir uma';

  @override
  String get play => 'Reproduzir';

  @override
  String get pause => 'Pausa';

  @override
  String get next => 'Seguinte';

  @override
  String get previous => 'Anterior';

  @override
  String get popularTracks => 'Populares';

  @override
  String get playbackError => 'Não é possível reproduzir esta faixa';

  @override
  String get preview => 'Amostra';

  @override
  String get protected => 'Protegido';

  @override
  String get protectedHint =>
      'Esta faixa está protegida por DRM e ainda não pode ser reproduzida no Pounce – mesmo com a sessão iniciada';

  @override
  String get protectedPlayable => 'Protegido por DRM – desencriptado pelo módulo DRM do seu navegador';

  @override
  String get account => 'Conta';

  @override
  String get login => 'Iniciar sessão com o SoundCloud';

  @override
  String get loginSubtitle => 'Sincronize gostos, listas de reprodução e o seu feed';

  @override
  String get signup => 'Criar conta';

  @override
  String get loginPrivacy =>
      'O início de sessão é feito na própria página do SoundCloud. O Pounce nunca vê a sua palavra-passe.';

  @override
  String get loginWaiting => 'Conclua o início de sessão no navegador…';

  @override
  String get loginReopen => 'Abrir novamente';

  @override
  String get loginPasteLabel => 'Colar link de redirecionamento';

  @override
  String get loginPasteHint =>
      'Após iniciar sessão, o SoundCloud redireciona para um link que começa por sc://auth?code=… Se a aplicação não o detetar automaticamente, copie-o para aqui.';

  @override
  String get loginPasteHintWeb =>
      'Abre-se um novo separador. Após iniciar sessão, é mostrado um endereço como soundcloud.com/signin/callback?code=… Copie esse endereço e cole-o aqui.';

  @override
  String get loginConfirm => 'Continuar';

  @override
  String get loginFailed => 'Falha no início de sessão';

  @override
  String loggedInAs(String name) {
    return 'Sessão iniciada como $name';
  }

  @override
  String get logout => 'Terminar sessão';

  @override
  String get logoutConfirm => 'Terminar sessão? Os seus gostos permanecem neste dispositivo.';

  @override
  String get homeStream => 'O seu feed';

  @override
  String get scPlaylists => 'As suas listas do SoundCloud';

  @override
  String transferLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Transferir $count gostos locais para a sua conta?',
      one: 'Transferir 1 gosto local para a sua conta?',
    );
    return '$_temp0';
  }

  @override
  String get transfer => 'Transferir';

  @override
  String get notNow => 'Agora não';

  @override
  String get loudTitle => 'Modo de volume';

  @override
  String get loudDesc => 'Equaliza faixas altas e baixas (ITU-R BS.1770) com um limitador integrado contra distorção.';

  @override
  String get loudOff => 'Desativado';

  @override
  String get loudQuiet => 'Baixo';

  @override
  String get loudNormal => 'Normal';

  @override
  String get loudLoud => 'Alto';

  @override
  String get loudUnsupported => 'Ainda não disponível nesta plataforma';

  @override
  String get signal => 'Sinal';

  @override
  String get sigSource => 'Fonte';

  @override
  String get sigLoudness => 'Volume da fonte';

  @override
  String get sigMomentary => 'Momentâneo';

  @override
  String get sigGain => 'Ganho';

  @override
  String get sigLimiter => 'Limitador';

  @override
  String get sigOutput => 'Saída';

  @override
  String get sigAnalysis => 'Análise';

  @override
  String get sigLive => 'FFT em direto';

  @override
  String get sigEnvelope => 'Envelope da forma de onda';

  @override
  String get sigClip => 'Distorção';

  @override
  String get sigClean => 'Limpo';

  @override
  String get volume => 'Volume';

  @override
  String get mute => 'Silenciar';

  @override
  String get inspector => 'Inspetor';

  @override
  String get expandPlayer => 'Vista focada';

  @override
  String get expandRail => 'Expandir barra lateral';

  @override
  String get collapseRail => 'Recolher barra lateral';

  @override
  String get accentAmber => 'Âmbar elétrico';

  @override
  String get accentCyan => 'Ciano crio';

  @override
  String get accentCover => 'Da capa';

  @override
  String get beatBg => 'Fundo ao ritmo da música';

  @override
  String get beatBgDesc => 'As cores pulsam e mudam com cada batida detetada';

  @override
  String get beatLight => 'Suave';

  @override
  String get beatMedium => 'Médio';

  @override
  String get beatStrong => 'Forte';

  @override
  String get appearance => 'Aparência';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get pureBlack => 'Preto puro';

  @override
  String get pureBlackDesc => 'Fundo preto no modo escuro (OLED)';

  @override
  String get dynamicColor => 'Cores do sistema';

  @override
  String get dynamicColorDesc => 'Usar a cor de destaque do sistema';

  @override
  String get artworkColors => 'Cores da capa';

  @override
  String get artworkColorsDesc => 'O reprodutor adapta as suas cores à capa';

  @override
  String get accentColor => 'Cor de destaque';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get playback => 'Reprodução';

  @override
  String get quality => 'Qualidade de transmissão';

  @override
  String get qualityHigh => 'Alta';

  @override
  String get qualitySaver => 'Poupança de dados';

  @override
  String get autoplay => 'Reprodução automática';

  @override
  String get autoplayDesc => 'Continuar a reproduzir faixas semelhantes no fim da fila';

  @override
  String get network => 'Rede';

  @override
  String get proxy => 'Proxy CORS';

  @override
  String get proxyDesc => 'Necessário no navegador, porque o SoundCloud apenas permite o seu próprio site.';

  @override
  String get about => 'Sobre';

  @override
  String get aboutText =>
      'Inspirado no KittyTune por alan7383 e escrito de raiz em Flutter. Software livre sob GPL-3.0.';

  @override
  String get licenses => 'Licenças de código aberto';

  @override
  String get previewBadge => 'Amostra (30s)';

  @override
  String get previewHint => 'O SoundCloud apenas oferece uma amostra de 30 segundos desta faixa.';

  @override
  String get openInYtMusic => 'Abrir no YouTube Music';

  @override
  String get skipPreviews => 'Saltar amostras';

  @override
  String get skipPreviewsDesc => 'Saltar amostras de 30 segundos ao avançar na fila de reprodução';

  @override
  String get fastStart => 'Início rápido';

  @override
  String get fastStartDesc =>
      'As faixas selecionadas começam em MP3 a 128 kbit/s – mais rápido, qualidade ligeiramente inferior. Faixas pré-carregadas mantêm a qualidade escolhida.';

  @override
  String get navDj => 'DJ';

  @override
  String get djHeadline => 'O seu DJ';

  @override
  String get djIntro =>
      'Escolha o que quer ouvir – o Pounce mistura os seus gostos e faixas semelhantes, com transições ajustadas à tonalidade, tempo e drop.';

  @override
  String get djCategories => 'Categorias';

  @override
  String get djBlend => 'Mistura';

  @override
  String get djFavorites => 'Favoritos';

  @override
  String get djDiscover => 'Descobrir';

  @override
  String get djLookahead => 'Análise antecipada';

  @override
  String djLookaheadDesc(int count, int mb) {
    return '$count músicas de avanço (~$mb MB)';
  }

  @override
  String get djStart => 'Iniciar mistura';

  @override
  String get djBuilding => 'A criar a sua mistura…';

  @override
  String get djNothing => 'Nenhum resultado adequado encontrado – tente outra categoria.';

  @override
  String get djPickCategory => 'Escolha pelo menos uma categoria';

  @override
  String djAnalyzed(int done, int total) {
    return '$done de $total músicas analisadas';
  }

  @override
  String djMixStarted(int count) {
    return 'Mistura com $count músicas iniciada';
  }

  @override
  String get djStop => 'Parar DJ';

  @override
  String get djSkip => 'Saltar (mistura e aprende)';

  @override
  String get srcAll => 'Tudo';

  @override
  String get srcRadio => 'Rádio web';

  @override
  String get radioSection => 'Rádio em direto · Estações';

  @override
  String get radioFavorites => 'Estações favoritas';

  @override
  String get radioTop => 'Mais ouvidas';

  @override
  String get radioAll => 'Todas as estações';

  @override
  String get radioSource => 'Rádio web';

  @override
  String get radioSourceDesc =>
      'Dezenas de milhares de estações via radio-browser.info. Desativado: nenhuma ligação efetuada.';

  @override
  String get live => 'DIRETO';

  @override
  String get updates => 'Atualizaciones';

  @override
  String get updatesAuto => 'Procurar atualizações automaticamente';

  @override
  String get updatesAutoDesc =>
      'No máximo uma vez por dia, um pedido ao GitHub sem ID do dispositivo. Nunca transfere autonomamente.';

  @override
  String get updatesCheck => 'Procurar agora';

  @override
  String get updatesNone => 'O Pounce está atualizado';

  @override
  String get updatesUnavailable => 'As atualizações não estão disponíveis nesta versão';

  @override
  String updateTitle(String version) {
    return 'Atualizar para $version';
  }

  @override
  String updateDownload(String mb) {
    return 'Transferir e instalar ($mb MB)';
  }

  @override
  String get updateViaPlay => 'Atualizar via Google Play';

  @override
  String get updateLater => 'Mais tarde';

  @override
  String get updateReleasePage => 'Página de lançamento';

  @override
  String get updateChecksumFailed => 'A soma de verificação não coincide – a transferência foi descartada.';

  @override
  String get updateNeedsPermission => 'Permita que o Pounce instale aplicações e toque novamente.';

  @override
  String get updateFailed => 'Falha na atualização – tente novamente mais tarde.';

  @override
  String get beta => 'Beta';

  @override
  String get betaNote =>
      'O Pounce está em versão beta. Algumas funcionalidades podem mudar ou falhar – comentários no GitHub são muito bem-vindos.';

  @override
  String get setupWelcome => 'Bem-vindo ao Pounce';

  @override
  String get setupTagline => 'Música rápida do SoundCloud e rádio web – com um DJ que mistura para si.';

  @override
  String get setupStart => 'Vamos a isso';

  @override
  String get setupNext => 'Seguinte';

  @override
  String get setupBack => 'Voltar';

  @override
  String get setupSkip => 'Saltar configuração';

  @override
  String get setupDone => 'Começar a ouvir';

  @override
  String get setupSourcesTitle => 'De onde deve vir a música?';

  @override
  String get setupSoundcloudDesc => 'Milhões de faixas, misturas e remisturas. Sempre ativo.';

  @override
  String get setupRadioDesc => 'Mais de 30.000 estações via radio-browser.info. Desativado = nenhum pedido.';

  @override
  String get setupAccountTitle => 'Trazer os seus gostos?';

  @override
  String get setupAccountDesc =>
      'Opcional: inicie sessão no SoundCloud para importar gostos e listas de reprodução. O Pounce funciona perfeitamente sem conta.';

  @override
  String get setupSignIn => 'Iniciar sessão no SoundCloud';

  @override
  String get setupDjTitle => 'O que deve tocar o seu DJ?';

  @override
  String get setupDjDesc => 'Escolha alguns estilos. Pode alterá-los a qualquer momento no separador DJ.';

  @override
  String get setupPrivacyTitle => 'A sua privacidade';

  @override
  String get setupPrivacyDesc =>
      'Sem rastreio, sem anúncios, sem IDs de dispositivo. Tudo abaixo está desativado a menos que o ative.';

  @override
  String get setupRecognition => 'Reconhecimento de música (Echolot)';

  @override
  String get setupRecognitionDesc =>
      'Disponível numa versão beta futura. Enviará apenas impressões digitais de áudio anónimas – nunca gravações – para o servidor Echolot.';

  @override
  String get setupAgain => 'Executar configuração novamente';

  @override
  String version(String version) {
    return 'Versão $version';
  }

  @override
  String syncLast(int count) {
    return 'Sincronizado ($count novos eventos)';
  }

  @override
  String get syncTitle => 'Sincronização de dispositivos';

  @override
  String get syncBackground => 'Sincronização em segundo plano';

  @override
  String syncServerActive(int port) {
    return 'Servidor ativo (porta $port) · peer-to-peer na sua rede local';
  }

  @override
  String get syncDisabled => 'Desativado';

  @override
  String get syncShowCode => 'Mostrar código de emparelhamento';

  @override
  String get syncShowCodeDesc => 'Código para os seus outros dispositivos';

  @override
  String get syncCodeTitle => 'Código de emparelhamento';

  @override
  String get syncCodeHint => 'Introduza este código no seu outro dispositivo:';

  @override
  String get syncCodeCopied => 'Código de emparelhamento copiado';

  @override
  String get copy => 'Copiar';

  @override
  String get done => 'Concluído';

  @override
  String get syncPair => 'Emparelhar um dispositivo';

  @override
  String get syncNoPeers => 'Nenhum outro dispositivo ligado';

  @override
  String syncPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivos emparelhados',
      one: '1 dispositivo emparelhado',
    );
    return '$_temp0';
  }

  @override
  String get syncPasteCode => 'Colar código de emparelhamento';

  @override
  String get syncPairAction => 'Emparelhar';

  @override
  String get syncPaired => 'Emparelhado!';

  @override
  String get syncPairFailed => 'Falha no emparelhamento';

  @override
  String get syncNow => 'Sincronizar agora';

  @override
  String get syncNever => 'Ainda não sincronizado';

  @override
  String get syncDone => 'Sincronizado';

  @override
  String get engineTitle => 'Motor de áudio e desempenho';

  @override
  String engineRustDesc(String label) {
    return '$label · grelha de batidas, tonalidade (chroma), volume e impressão digital IA a partir de áudio real';
  }

  @override
  String get engineUnavailable => 'Não disponível – estimativa apenas a partir da forma de onda';

  @override
  String get djFlowActiveDesc => 'Ajuste automático de frases e tonalidade';

  @override
  String get djTapToActivate => 'Toque para ativar';

  @override
  String get djAnalyzing => 'A analisar áudio…';

  @override
  String get djNoKey => 'Nenhuma tonalidade detetada';

  @override
  String get djKeyUncertain => 'incerto';

  @override
  String djBar(int bar) {
    return 'Compasso $bar/4';
  }

  @override
  String djPhraseBeat(int beat) {
    return 'Batida da frase $beat/16';
  }

  @override
  String get statGrid => 'Grelha';

  @override
  String get statKey => 'Tonalidade';

  @override
  String get statLoudness => 'Volume';

  @override
  String get statEnergy => 'Energia';

  @override
  String get statSource => 'Fonte';

  @override
  String get srcAudio => 'Áudio';

  @override
  String get srcWaveform => 'Forma de onda';

  @override
  String get srcTitle => 'Título';

  @override
  String get djEnergiesLive => 'Energias de áudio (em direto)';

  @override
  String djTransitionIn(int beats) {
    return 'Transição em $beats batidas';
  }

  @override
  String get djEnergyMode => 'Modo de energia harmónica';

  @override
  String get djModeBuildUp => 'Aumento';

  @override
  String get djModeHold => 'Manter';

  @override
  String get djModeWindDown => 'Redução';

  @override
  String get djHarmonic => 'Harmónico';

  @override
  String get djNextBest => 'Próxima faixa (melhor correspondência)';

  @override
  String djMatch(String pct) {
    return '$pct% de correspondência';
  }

  @override
  String get djMixNow => 'Misturar agora';

  @override
  String get bandBass => 'GRAVES (kick & sub)';

  @override
  String get bandMid => 'MÉDIOS (voz & melodia)';

  @override
  String get bandHigh => 'AGUDOS (hi-hats & ar)';

  @override
  String planDrop(String time) {
    return 'Drop $time';
  }

  @override
  String get planNoDrop => 'sem drop';

  @override
  String get planSearching => 'à procura do drop…';

  @override
  String planText(String entry, String drop, String fade) {
    return 'Entrada $entry · $drop · transição de $fade s';
  }
}
