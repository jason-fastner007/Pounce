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
  String get homeContinue => 'Continuar a ouvir';

  @override
  String homeBecauseYouPlayed(String title) {
    return 'Porque ouviste $title';
  }

  @override
  String get errorLoading => 'Não foi possível carregar o conteúdo';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get noResults => 'Sem resultados';

  @override
  String get searchHint => 'Faixas, artistas, listas de reprodução ou ligações';

  @override
  String get searchRecent => 'Pesquisas recentes';

  @override
  String get searchEmptyTitle => 'Encontra algo para ouvir';

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
  String get emptyLikes => 'As faixas que gostares aparecerão aqui';

  @override
  String get emptyHistory => 'Ainda não ouviste nada';

  @override
  String get emptyPlaylist => 'Esta lista de reprodução está vazia';

  @override
  String get emptyPlaylists => 'Cria listas de reprodução e adiciona faixas através do menu ⋮.';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas',
      one: '1 faixa',
      zero: 'Sem faixas',
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
  String get unlike => 'Remover dos favoritos';

  @override
  String get goToArtist => 'Ir para o artista';

  @override
  String get copyLink => 'Copiar ligação';

  @override
  String get linkCopied => 'Ligação copiada';

  @override
  String get addedToQueue => 'Adicionado à fila';

  @override
  String addedToPlaylist(String name) {
    return 'Adicionado a $name';
  }

  @override
  String alreadyInPlaylist(String name) {
    return 'Já se encontra em $name';
  }

  @override
  String get nowPlaying => 'A reproduzir';

  @override
  String get queue => 'Fila de reprodução';

  @override
  String get lyrics => 'Letra';

  @override
  String get noLyrics => 'Nenhuma letra disponível';

  @override
  String lyricsSource(String source) {
    return 'Letra: $source';
  }

  @override
  String get sleepTimer => 'Temporizador de suspensão';

  @override
  String get sleepOff => 'Desligado';

  @override
  String sleepIn(int minutes) {
    return 'Pára em $minutes min';
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
  String get repeatOff => 'Não repetir';

  @override
  String get repeatAll => 'Repetir tudo';

  @override
  String get repeatOne => 'Repetir faixa atual';

  @override
  String get play => 'Reproduzir';

  @override
  String get pause => 'Pausa';

  @override
  String get next => 'Seguinte';

  @override
  String get previous => 'Anterior';

  @override
  String get popularTracks => 'Faixas populares';

  @override
  String get playbackError => 'Erro na reprodução';

  @override
  String get preview => 'Pré-visualização (não oficial)';

  @override
  String get protected => 'Faixa protegida (Go+)';

  @override
  String get protectedHint => 'Inicia sessão para reproduzir a versão completa se tiveres uma conta Go+.';

  @override
  String get protectedPlayable => 'Faixa protegida (reproduzível com a tua conta Go+)';

  @override
  String get account => 'Conta';

  @override
  String get login => 'Iniciar sessão';

  @override
  String get loginSubtitle =>
      'Inicia sessão com o SoundCloud para sincronizar os teus gostos e aceder à tua biblioteca completa.';

  @override
  String get signup => 'Criar conta no SoundCloud';

  @override
  String get loginPrivacy =>
      'O Pounce liga-se diretamente ao SoundCloud. Os teus dados de acesso nunca saem do teu dispositivo.';

  @override
  String get loginWaiting => 'A aguardar autenticação no navegador...';

  @override
  String get loginReopen => 'Abrir navegador novamente';

  @override
  String get loginPasteLabel => 'Não foste redirecionado?';

  @override
  String get loginPasteHint => 'Cola o URL da página em branco para onde o navegador te redirecionou:';

  @override
  String get loginPasteHintWeb => 'Cola o URL final da página de sucesso após iniciar sessão:';

  @override
  String get loginConfirm => 'Confirmar início de sessão';

  @override
  String get loginFailed => 'Falha ao iniciar sessão. Tenta novamente.';

  @override
  String loggedInAs(String name) {
    return 'Com sessão iniciada como $name';
  }

  @override
  String get logout => 'Terminar sessão';

  @override
  String get logoutConfirm => 'Tens a certeza de que queres terminar a sessão?';

  @override
  String get homeStream => 'Fluxo recente';

  @override
  String get scPlaylists => 'Listas do SoundCloud';

  @override
  String transferLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Transferir $count gostos locais para a tua conta?',
      one: 'Transferir 1 gosto local para a tua conta?',
    );
    return '$_temp0';
  }

  @override
  String get transfer => 'Transferir';

  @override
  String get notNow => 'Agora não';

  @override
  String get loudTitle => 'Normalização de volume';

  @override
  String get loudDesc => 'Ajusta faixas para um nível de volume uniforme (EBU R128). Requer análise de áudio.';

  @override
  String get loudOff => 'Desativado';

  @override
  String get loudQuiet => 'Suave (-18 LUFS)';

  @override
  String get loudNormal => 'Normal (-14 LUFS)';

  @override
  String get loudLoud => 'Alto (-11 LUFS)';

  @override
  String get loudUnsupported => 'O teu motor de áudio atual não suporta normalização de volume.';

  @override
  String get signal => 'Monitor de sinal';

  @override
  String get sigSource => 'Fonte';

  @override
  String get sigLoudness => 'Volume';

  @override
  String get sigMomentary => 'Mom.';

  @override
  String get sigGain => 'Ganho';

  @override
  String get sigLimiter => 'Limitador';

  @override
  String get sigOutput => 'Saída';

  @override
  String get sigAnalysis => 'Análise';

  @override
  String get sigLive => 'Em direto';

  @override
  String get sigEnvelope => 'Envelope';

  @override
  String get sigClip => 'Clip';

  @override
  String get sigClean => 'Limpo';

  @override
  String get volume => 'Volume';

  @override
  String get mute => 'Silenciar';

  @override
  String get inspector => 'Inspetor de áudio';

  @override
  String get expandPlayer => 'Expandir reprodutor';

  @override
  String get expandRail => 'Expandir barra lateral';

  @override
  String get collapseRail => 'Recolher barra lateral';

  @override
  String get accentAmber => 'Âmbar quente';

  @override
  String get accentCyan => 'Ciano elétrico';

  @override
  String get accentCover => 'Dinâmico (capa da faixa)';

  @override
  String get beatBg => 'Fundo pulsante';

  @override
  String get beatBgDesc => 'Pulsação visual subtil no fundo ao ritmo da batida';

  @override
  String get beatLight => 'Suave';

  @override
  String get beatMedium => 'Médio';

  @override
  String get beatStrong => 'Forte';

  @override
  String get appearance => 'Aparência';

  @override
  String get themeSystem => 'Seguir o sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get pureBlack => 'Preto puro';

  @override
  String get pureBlackDesc => 'Preto verdadeiro para ecrãs OLED';

  @override
  String get dynamicColor => 'Cor dinâmica';

  @override
  String get dynamicColorDesc => 'Extrair cor de destaque da faixa atual';

  @override
  String get artworkColors => 'Cores da capa animadas';

  @override
  String get artworkColorsDesc => 'Gradiente dinâmico com base na capa do álbum';

  @override
  String get accentColor => 'Cor de destaque';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Idioma do sistema';

  @override
  String get playback => 'Reprodução';

  @override
  String get quality => 'Qualidade de transmissão';

  @override
  String get qualityHigh => 'Alta (HQ)';

  @override
  String get qualitySaver => 'Poupança de dados';

  @override
  String get autoplay => 'Reprodução automática';

  @override
  String get autoplayDesc => 'Continuar a reproduzir faixas semelhantes quando a fila terminar';

  @override
  String get network => 'Rede';

  @override
  String get proxy => 'Servidor proxy';

  @override
  String get proxyDesc => 'Configurar proxy HTTP/SOCKS para ligações de rede';

  @override
  String get about => 'Acerca';

  @override
  String get aboutText =>
      'Pounce é um cliente de música rápido e de código aberto focado em simplicidade, desempenho e mistura DJ.';

  @override
  String get licenses => 'Licenças de código aberto';

  @override
  String get previewBadge => 'PRÉ-VISUALIZAÇÃO';

  @override
  String get previewHint => 'Esta faixa é apenas uma pré-visualização curta de 30 segundos.';

  @override
  String get openInYtMusic => 'Abrir no YouTube Music';

  @override
  String get skipPreviews => 'Ignorar pré-visualizações';

  @override
  String get skipPreviewsDesc => 'Passar automaticamente à frente faixas que sejam apenas pré-visualizações';

  @override
  String get fastStart => 'Início rápido';

  @override
  String get fastStartDesc => 'Começar a reprodução imediatamente antes de analisar o ficheiro completo';

  @override
  String get navDj => 'DJ Flow';

  @override
  String get djHeadline => 'Mistura inteligente com transições perfeitas em tempo real.';

  @override
  String get djIntro =>
      'O DJ Flow alinha automaticamente o tempo e a batida entre músicas para uma experiência de mistura contínua.';

  @override
  String get djCategories => 'Categorias de mistura';

  @override
  String get djBlend => 'Transição suave';

  @override
  String get djFavorites => 'Favoritos';

  @override
  String get djDiscover => 'Descobrir';

  @override
  String get djLookahead => 'Faixas em buffer antecipado';

  @override
  String djLookaheadDesc(int count, int mb) {
    return '$count músicas adiantadas (~$mb MB)';
  }

  @override
  String get djStart => 'Iniciar DJ Flow';

  @override
  String get djBuilding => 'A preparar a mistura...';

  @override
  String get djNothing => 'Nenhuma faixa disponível para misturar.';

  @override
  String get djPickCategory => 'Escolhe uma categoria ou adiciona mais faixas para começar.';

  @override
  String djAnalyzed(int done, int total) {
    return '$done de $total músicas analisadas';
  }

  @override
  String djMixStarted(int count) {
    return 'Mistura iniciada com $count músicas';
  }

  @override
  String get djStop => 'Parar DJ Flow';

  @override
  String get djSkip => 'Saltar transição';

  @override
  String get srcAll => 'Todas as fontes';

  @override
  String get srcRadio => 'Rádio na Internet';

  @override
  String get radioSection => 'Estações de rádio';

  @override
  String get radioFavorites => 'Rádios favoritas';

  @override
  String get radioTop => 'Mais ouvidas';

  @override
  String get radioAll => 'Todas as estações';

  @override
  String get radioSource => 'Diretório de rádios';

  @override
  String get radioSourceDesc => 'Fonte para pesquisa de estações de rádio na Internet';

  @override
  String get live => 'EM DIRETO';

  @override
  String get updates => 'Atualizações';

  @override
  String get updatesAuto => 'Verificar atualizações automaticamente';

  @override
  String get updatesAutoDesc => 'Procurar novas versões ao iniciar a aplicação';

  @override
  String get updatesCheck => 'Procurar atualizações agora';

  @override
  String get updatesNone => 'Já tens a versão mais recente instalada.';

  @override
  String get updatesUnavailable => 'Não foi possível verificar atualizações de momento.';

  @override
  String updateTitle(String version) {
    return 'Atualizar para $version';
  }

  @override
  String updateDownload(String mb) {
    return 'Transferir e instalar ($mb MB)';
  }

  @override
  String get updateViaPlay => 'Atualizar via Google Play Store';

  @override
  String get updateLater => 'Mais tarde';

  @override
  String get updateReleasePage => 'Abrir página de lançamento';

  @override
  String get updateChecksumFailed => 'A verificação da integridade do ficheiro falhou.';

  @override
  String get updateNeedsPermission => 'É necessária permissão para instalar pacotes externos.';

  @override
  String get updateFailed => 'Falha ao descarregar a atualização.';

  @override
  String get beta => 'Versão Beta';

  @override
  String get betaNote => 'Estás a utilizar uma versão beta com funcionalidades experimentais.';

  @override
  String get setupWelcome => 'Bem-vindo ao Pounce';

  @override
  String get setupTagline => 'A tua música, reinventada.';

  @override
  String get setupStart => 'Começar';

  @override
  String get setupNext => 'Seguinte';

  @override
  String get setupBack => 'Voltar';

  @override
  String get setupSkip => 'Ignorar';

  @override
  String get setupDone => 'Concluir';

  @override
  String get setupSourcesTitle => 'Fontes de música';

  @override
  String get setupSoundcloudDesc => 'Acede a milhões de faixas, remixes e produções independentes.';

  @override
  String get setupRadioDesc => 'Milhares de estações de rádio online de todo o mundo.';

  @override
  String get setupAccountTitle => 'A tua conta';

  @override
  String get setupAccountDesc => 'Inicia sessão para sincronizar a tua biblioteca e os teus favoritos.';

  @override
  String get setupSignIn => 'Iniciar sessão com SoundCloud';

  @override
  String get setupDjTitle => 'Motor DJ inteligente';

  @override
  String get setupDjDesc => 'Transições suaves ao ritmo da batida calculadas em tempo real.';

  @override
  String get setupPrivacyTitle => 'Privacidade em primeiro lugar';

  @override
  String get setupPrivacyDesc => 'Sem rastreadores externos. As tuas credenciais permanecem seguras no dispositivo.';

  @override
  String get setupRecognition => 'Reconhecimento musical';

  @override
  String get setupRecognitionDesc => 'Identifica e analisa tonalidades e batidas para transições perfeitas.';

  @override
  String get setupAgain => 'Repetir introdução';

  @override
  String version(String version) {
    return 'Versão $version';
  }

  @override
  String syncLast(int count) {
    return 'Sincronizado ($count novos eventos)';
  }

  @override
  String get syncTitle => 'Sincronização local';

  @override
  String get syncBackground => 'Sincronização em segundo plano';

  @override
  String syncServerActive(int port) {
    return 'Servidor ativo (porta $port) · peer-to-peer na tua rede local';
  }

  @override
  String get syncDisabled => 'Sincronização desativada';

  @override
  String get syncShowCode => 'Mostrar código de emparelhamento';

  @override
  String get syncShowCodeDesc => 'Apresenta o código QR e a chave para emparelhar novos dispositivos';

  @override
  String get syncCodeTitle => 'Código de emparelhamento';

  @override
  String get syncCodeHint => 'Lê o código QR noutro dispositivo para o sincronizar.';

  @override
  String get syncCodeCopied => 'Código de emparelhamento copiado';

  @override
  String get copy => 'Copiar';

  @override
  String get done => 'Concluído';

  @override
  String get syncPair => 'Emparelhar novo dispositivo';

  @override
  String get syncNoPeers => 'Nenhum dispositivo emparelhado';

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
  String get syncPairAction => 'Emparelhar dispositivo';

  @override
  String get syncPaired => 'Dispositivo emparelhado com sucesso!';

  @override
  String get syncPairFailed => 'Falha ao emparelhar o dispositivo. Verifica o código.';

  @override
  String get syncNow => 'Sincronizar agora';

  @override
  String get syncNever => 'Nunca sincronizado';

  @override
  String get syncDone => 'Sincronização concluída com sucesso';

  @override
  String get engineTitle => 'Motor de áudio';

  @override
  String engineRustDesc(String label) {
    return '$label · grelha de batidas, tom (croma), volume e impressão digital de IA a partir de áudio real';
  }

  @override
  String get engineUnavailable => 'Motor nativo não disponível';

  @override
  String get djFlowActiveDesc => 'O DJ Flow está ativo e a controlar as transições automáticas';

  @override
  String get djTapToActivate => 'Toca para ativar o modo DJ';

  @override
  String get djAnalyzing => 'A analisar o áudio...';

  @override
  String get djNoKey => 'Tom desconhecido';

  @override
  String get djKeyUncertain => 'Tom incerto';

  @override
  String djBar(int bar) {
    return 'Compasso $bar/4';
  }

  @override
  String djPhraseBeat(int beat) {
    return 'Batida da frase $beat/16';
  }

  @override
  String get statGrid => 'Grelha de batidas';

  @override
  String get statKey => 'Tonalidade';

  @override
  String get statLoudness => 'Nível de volume';

  @override
  String get statEnergy => 'Energia';

  @override
  String get statSource => 'Fonte de dados';

  @override
  String get srcAudio => 'Áudio decodificado';

  @override
  String get srcWaveform => 'Forma de onda';

  @override
  String get srcTitle => 'Título da faixa';

  @override
  String get djEnergiesLive => 'Energia em tempo real';

  @override
  String djTransitionIn(int beats) {
    return 'Transição em $beats batidas';
  }

  @override
  String get djEnergyMode => 'Modo de energia';

  @override
  String get djModeBuildUp => 'Aumentar energia';

  @override
  String get djModeHold => 'Manter energia';

  @override
  String get djModeWindDown => 'Reduzir energia';

  @override
  String get djHarmonic => 'Mistura harmónica';

  @override
  String get djNextBest => 'Melhor correspondência';

  @override
  String djMatch(String pct) {
    return '$pct% de compatibilidade';
  }

  @override
  String get djMixNow => 'Misturar já';

  @override
  String get bandBass => 'Graves';

  @override
  String get bandMid => 'Médios';

  @override
  String get bandHigh => 'Agudos';

  @override
  String planDrop(String time) {
    return 'Drop em $time';
  }

  @override
  String get planNoDrop => 'Sem drop detetado';

  @override
  String get planSearching => 'A procurar ponto de mistura...';

  @override
  String planText(String entry, String drop, String fade) {
    return 'Entrada $entry · $drop · fade de $fade s';
  }
}
