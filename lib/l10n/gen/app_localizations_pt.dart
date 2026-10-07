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
  String get navSearch => 'Buscar';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navSettings => 'Configurações';

  @override
  String get greetingMorning => 'Bom dia';

  @override
  String get greetingAfternoon => 'Boa tarde';

  @override
  String get greetingEvening => 'Boa noite';

  @override
  String get homeContinue => 'Continuar ouvindo';

  @override
  String homeBecauseYouPlayed(String title) {
    return 'Porque você ouviu $title';
  }

  @override
  String get errorLoading => 'Não foi possível carregar o conteúdo';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get noResults => 'Nenhum resultado';

  @override
  String get searchHint => 'Músicas, artistas, playlists ou links';

  @override
  String get searchRecent => 'Pesquisas recentes';

  @override
  String get searchEmptyTitle => 'Encontre algo para ouvir';

  @override
  String get tabTracks => 'Faixas';

  @override
  String get tabPlaylists => 'Playlists';

  @override
  String get tabAlbums => 'Álbuns';

  @override
  String get tabArtists => 'Artistas';

  @override
  String get likedTracks => 'Músicas curtidas';

  @override
  String get history => 'Histórico';

  @override
  String get playlists => 'Playlists';

  @override
  String get newPlaylist => 'Nova playlist';

  @override
  String get playlistName => 'Nome';

  @override
  String get create => 'Criar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get rename => 'Renomear';

  @override
  String get delete => 'Excluir';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Excluir \"$name\"?';
  }

  @override
  String get clearHistory => 'Limpar histórico';

  @override
  String get emptyLikes => 'As músicas que você curtir aparecerão aqui';

  @override
  String get emptyHistory => 'Nada tocado ainda';

  @override
  String get emptyPlaylist => 'Esta playlist está vazia';

  @override
  String get emptyPlaylists => 'Crie playlists e adicione faixas pelo menu ⋮.';

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
  String get playNext => 'Tocar a seguir';

  @override
  String get addToQueue => 'Adicionar à fila';

  @override
  String get addToPlaylist => 'Adicionar à playlist';

  @override
  String get removeFromPlaylist => 'Remover da playlist';

  @override
  String get like => 'Curtir';

  @override
  String get unlike => 'Remover das curtidas';

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
  String get nowPlaying => 'Tocando agora';

  @override
  String get queue => 'Fila';

  @override
  String get lyrics => 'Letra';

  @override
  String get noLyrics => 'Nenhuma letra encontrada';

  @override
  String lyricsSource(String source) {
    return 'Letra: $source';
  }

  @override
  String get sleepTimer => 'Timer de sono';

  @override
  String get sleepOff => 'Desativar timer';

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
  String get shuffle => 'Ordem aleatória';

  @override
  String get repeatOff => 'Repetição desativada';

  @override
  String get repeatAll => 'Repetir tudo';

  @override
  String get repeatOne => 'Repetir uma';

  @override
  String get play => 'Tocar';

  @override
  String get pause => 'Pausar';

  @override
  String get next => 'Próxima';

  @override
  String get previous => 'Anterior';

  @override
  String get popularTracks => 'Populares';

  @override
  String get playbackError => 'Não é possível tocar esta faixa';

  @override
  String get preview => 'Prévia';

  @override
  String get protected => 'Protegida';

  @override
  String get protectedHint =>
      'Esta faixa possui proteção DRM e ainda não pode ser tocada no Pounce – mesmo com login feito';

  @override
  String get protectedPlayable => 'Protegida por DRM – descriptografada pelo módulo DRM do seu navegador';

  @override
  String get account => 'Conta';

  @override
  String get login => 'Entrar com o SoundCloud';

  @override
  String get loginSubtitle => 'Sincronize curtidas, playlists e seu feed';

  @override
  String get signup => 'Criar conta';

  @override
  String get loginPrivacy => 'Você entra na própria página do SoundCloud. O Pounce nunca vê sua senha.';

  @override
  String get loginWaiting => 'Conclua o login no navegador…';

  @override
  String get loginReopen => 'Abrir novamente';

  @override
  String get loginPasteLabel => 'Colar link de redirecionamento';

  @override
  String get loginPasteHint =>
      'Após entrar, o SoundCloud redireciona para um link iniciando com sc://auth?code=… Se o app não capturar automaticamente, copie aqui.';

  @override
  String get loginPasteHintWeb =>
      'Uma nova aba será aberta. Após entrar, ela mostrará um endereço como soundcloud.com/signin/callback?code=… Copie esse endereço e cole aqui.';

  @override
  String get loginConfirm => 'Continuar';

  @override
  String get loginFailed => 'Falha no login';

  @override
  String loggedInAs(String name) {
    return 'Conectado como $name';
  }

  @override
  String get logout => 'Sair';

  @override
  String get logoutConfirm => 'Sair? Suas curtidas permanecerão neste dispositivo.';

  @override
  String get homeStream => 'Seu feed';

  @override
  String get scPlaylists => 'Suas playlists do SoundCloud';

  @override
  String transferLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Transferir $count curtidas locais para sua conta?',
      one: 'Transferir 1 curtida local para sua conta?',
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
  String get loudDesc => 'Equilibra faixas altas e baixas (ITU-R BS.1770) com um limitador integrado contra distorção.';

  @override
  String get loudOff => 'Desligado';

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
  String get sigLive => 'FFT ao vivo';

  @override
  String get sigEnvelope => 'Envelope da forma de onda';

  @override
  String get sigClip => 'Distorção';

  @override
  String get sigClean => 'Limpo';

  @override
  String get volume => 'Volume';

  @override
  String get mute => 'Mudo';

  @override
  String get inspector => 'Inspetor';

  @override
  String get expandPlayer => 'Modo foco';

  @override
  String get expandRail => 'Expandir barra lateral';

  @override
  String get collapseRail => 'Recolher barra lateral';

  @override
  String get accentAmber => 'Âmbar Elétrico';

  @override
  String get accentCyan => 'Ciano Crio';

  @override
  String get accentCover => 'Da capa';

  @override
  String get beatBg => 'Fundo no ritmo da batida';

  @override
  String get beatBgDesc => 'As cores pulsam e mudam a cada batida detectada';

  @override
  String get beatLight => 'Leve';

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
  String get artworkColorsDesc => 'O reprodutor adapta suas cores à capa';

  @override
  String get accentColor => 'Cor de destaque';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get playback => 'Reprodução';

  @override
  String get quality => 'Qualidade da transmissão';

  @override
  String get qualityHigh => 'Alta';

  @override
  String get qualitySaver => 'Economia de dados';

  @override
  String get autoplay => 'Reprodução automática';

  @override
  String get autoplayDesc => 'Continuar tocando faixas semelhantes quando a fila terminar';

  @override
  String get network => 'Rede';

  @override
  String get proxy => 'Proxy CORS';

  @override
  String get proxyDesc => 'Necessário no navegador, pois o SoundCloud permite apenas seu próprio site.';

  @override
  String get about => 'Sobre';

  @override
  String get aboutText =>
      'Inspirado no KittyTune por alan7383 e escrito do zero em Flutter. Software livre sob GPL-3.0.';

  @override
  String get licenses => 'Licenças de código aberto';

  @override
  String get previewBadge => 'Prévia (30s)';

  @override
  String get previewHint => 'O SoundCloud oferece apenas uma prévia de 30 segundos desta faixa.';

  @override
  String get openInYtMusic => 'Abrir no YouTube Music';

  @override
  String get skipPreviews => 'Pular prévias';

  @override
  String get skipPreviewsDesc => 'Pular prévias de 30 segundos quando a fila avançar';

  @override
  String get fastStart => 'Início rápido';

  @override
  String get fastStartDesc =>
      'Faixas tocadas começam em MP3 128 kbit/s – mais rápido, qualidade ligeiramente menor. Faixas pré-carregadas mantêm a qualidade escolhida.';

  @override
  String get navDj => 'DJ';

  @override
  String get djHeadline => 'Seu DJ';

  @override
  String get djIntro =>
      'Escolha o que deseja ouvir – o Pounce mistura suas curtidas e faixas semelhantes, com transições ajustadas por tom, tempo e drop.';

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
    return '$count músicas de antecedência (~$mb MB)';
  }

  @override
  String get djStart => 'Iniciar mix';

  @override
  String get djBuilding => 'Criando seu mix…';

  @override
  String get djNothing => 'Nada adequado encontrado – tente outra categoria.';

  @override
  String get djPickCategory => 'Escolha pelo menos uma categoria';

  @override
  String djAnalyzed(int done, int total) {
    return '$done de $total músicas analisadas';
  }

  @override
  String djMixStarted(int count) {
    return 'Mix com $count músicas iniciado';
  }

  @override
  String get djStop => 'Parar DJ';

  @override
  String get djSkip => 'Pular (faz transição e aprende)';

  @override
  String get srcAll => 'Tudo';

  @override
  String get srcRadio => 'Rádio web';

  @override
  String get radioSection => 'Rádio ao vivo · Estações';

  @override
  String get radioFavorites => 'Estações favoritas';

  @override
  String get radioTop => 'Mais ouvidas';

  @override
  String get radioAll => 'Todas as estações';

  @override
  String get radioSource => 'Rádio web';

  @override
  String get radioSourceDesc => 'Dezenas de milhares de estações do radio-browser.info. Desligado: nenhuma requisição.';

  @override
  String get live => 'AO VIVO';

  @override
  String get updates => 'Atualizações';

  @override
  String get updatesAuto => 'Verificar atualizações automaticamente';

  @override
  String get updatesAutoDesc =>
      'No máximo uma vez por dia, uma requisição ao GitHub sem ID de dispositivo. Nunca baixa sozinho.';

  @override
  String get updatesCheck => 'Verificar agora';

  @override
  String get updatesNone => 'O Pounce está atualizado';

  @override
  String get updatesUnavailable => 'Atualizações não estão disponíveis nesta versão';

  @override
  String updateTitle(String version) {
    return 'Atualizar para $version';
  }

  @override
  String updateDownload(String mb) {
    return 'Baixar e instalar ($mb MB)';
  }

  @override
  String get updateViaPlay => 'Atualizar pelo Google Play';

  @override
  String get updateLater => 'Mais tarde';

  @override
  String get updateReleasePage => 'Página da versão';

  @override
  String get updateChecksumFailed => 'Soma de verificação incorreta – o download foi descartado.';

  @override
  String get updateNeedsPermission => 'Permita que o Pounce instale aplicativos e toque novamente.';

  @override
  String get updateFailed => 'Falha na atualização – tente novamente mais tarde.';

  @override
  String get beta => 'Beta';

  @override
  String get betaNote =>
      'O Pounce está em versão beta. As coisas podem mudar ou falhar – comentários no GitHub são muito bem-vindos.';

  @override
  String get setupWelcome => 'Bem-vindo ao Pounce';

  @override
  String get setupTagline => 'Música rápida do SoundCloud e rádio web – com um DJ que mistura para você.';

  @override
  String get setupStart => 'Vamos lá';

  @override
  String get setupNext => 'Avançar';

  @override
  String get setupBack => 'Voltar';

  @override
  String get setupSkip => 'Pular configuração';

  @override
  String get setupDone => 'Começar a ouvir';

  @override
  String get setupSourcesTitle => 'De onde deve vir a música?';

  @override
  String get setupSoundcloudDesc => 'Milhões de faixas, mixes e remixes. Sempre ativo.';

  @override
  String get setupRadioDesc => 'Mais de 30.000 estações via radio-browser.info. Desligado = nenhuma requisição.';

  @override
  String get setupAccountTitle => 'Trazer suas curtidas?';

  @override
  String get setupAccountDesc =>
      'Opcional: entre no SoundCloud para importar curtidas e playlists. O Pounce funciona perfeitamente sem uma conta.';

  @override
  String get setupSignIn => 'Entrar no SoundCloud';

  @override
  String get setupDjTitle => 'O que seu DJ toca?';

  @override
  String get setupDjDesc => 'Escolha alguns estilos. Você pode alterá-los a qualquer momento na aba DJ.';

  @override
  String get setupPrivacyTitle => 'Sua privacidade';

  @override
  String get setupPrivacyDesc =>
      'Sem rastreamento, sem anúncios, sem IDs de dispositivo. Tudo abaixo está desligado a menos que você ative.';

  @override
  String get setupRecognition => 'Reconhecimento de músicas (Echolot)';

  @override
  String get setupRecognitionDesc =>
      'Em uma versão beta futura. Enviaria apenas impressões digitais de áudio anônimas – nunca gravações – para o servidor Echolot.';

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
    return 'Servidor ativo (porta $port) · P2P na sua rede local';
  }

  @override
  String get syncDisabled => 'Desativado';

  @override
  String get syncShowCode => 'Mostrar código de pareamento';

  @override
  String get syncShowCodeDesc => 'Código para seus outros dispositivos';

  @override
  String get syncCodeTitle => 'Código de pareamento';

  @override
  String get syncCodeHint => 'Digite este código no seu outro dispositivo:';

  @override
  String get syncCodeCopied => 'Código de pareamento copiado';

  @override
  String get copy => 'Copiar';

  @override
  String get done => 'Concluído';

  @override
  String get syncPair => 'Parear um dispositivo';

  @override
  String get syncNoPeers => 'Nenhum outro dispositivo conectado';

  @override
  String syncPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivos pareados',
      one: '1 dispositivo pareado',
    );
    return '$_temp0';
  }

  @override
  String get syncPasteCode => 'Colar código de pareamento';

  @override
  String get syncPairAction => 'Parear';

  @override
  String get syncPaired => 'Pareado!';

  @override
  String get syncPairFailed => 'Falha no pareamento';

  @override
  String get syncNow => 'Sincronizar agora';

  @override
  String get syncNever => 'Ainda não sincronizado';

  @override
  String get syncDone => 'Sincronizado';

  @override
  String get engineTitle => 'Mecanismo de áudio e desempenho';

  @override
  String engineRustDesc(String label) {
    return '$label · grade de batidas, tom (chroma), volume e impressão digital de IA de áudio real';
  }

  @override
  String get engineUnavailable => 'Não disponível – estimativa apenas pela forma de onda';

  @override
  String get djFlowActiveDesc => 'Ajuste automático de frases e tons';

  @override
  String get djTapToActivate => 'Toque para ativar';

  @override
  String get djAnalyzing => 'Analisando áudio…';

  @override
  String get djNoKey => 'Nenhum tom detectado';

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
  String get statGrid => 'Grade';

  @override
  String get statKey => 'Tom';

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
  String get djEnergiesLive => 'Energias de áudio (ao vivo)';

  @override
  String djTransitionIn(int beats) {
    return 'Transição em $beats batidas';
  }

  @override
  String get djEnergyMode => 'Modo de energia harmônica';

  @override
  String get djModeBuildUp => 'Construção';

  @override
  String get djModeHold => 'Manter';

  @override
  String get djModeWindDown => 'Desacelerar';

  @override
  String get djHarmonic => 'Harmônico';

  @override
  String get djNextBest => 'Próxima faixa (melhor combinação)';

  @override
  String djMatch(String pct) {
    return '$pct% de combinação';
  }

  @override
  String get djMixNow => 'Misturar agora';

  @override
  String get bandBass => 'GRAVES (kick & sub)';

  @override
  String get bandMid => 'MÉDIOS (vocais & melodia)';

  @override
  String get bandHigh => 'AGUDOS (hi-hats & ar)';

  @override
  String planDrop(String time) {
    return 'Drop $time';
  }

  @override
  String get planNoDrop => 'sem drop';

  @override
  String get planSearching => 'procurando o drop…';

  @override
  String planText(String entry, String drop, String fade) {
    return 'Entrada $entry · $drop · transição de $fade s';
  }
}
