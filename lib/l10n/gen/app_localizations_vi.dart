// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Pounce';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navSearch => 'Tìm kiếm';

  @override
  String get navLibrary => 'Thư viện';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get greetingMorning => 'Chào buổi sáng';

  @override
  String get greetingAfternoon => 'Chào buổi chiều';

  @override
  String get greetingEvening => 'Chào buổi tối';

  @override
  String get homeContinue => 'Nghe tiếp';

  @override
  String homeBecauseYouPlayed(String title) {
    return 'Vì bạn đã nghe $title';
  }

  @override
  String get errorLoading => 'Không thể tải nội dung';

  @override
  String get retry => 'Thử lại';

  @override
  String get noResults => 'Không có kết quả';

  @override
  String get searchHint => 'Bài hát, nghệ sĩ, danh sách phát hoặc liên kết';

  @override
  String get searchRecent => 'Tìm kiếm gần đây';

  @override
  String get searchEmptyTitle => 'Tìm thứ gì đó để nghe';

  @override
  String get tabTracks => 'Bài hát';

  @override
  String get tabPlaylists => 'Danh sách phát';

  @override
  String get tabAlbums => 'Album';

  @override
  String get tabArtists => 'Nghệ sĩ';

  @override
  String get likedTracks => 'Bài hát đã thích';

  @override
  String get history => 'Lịch sử';

  @override
  String get playlists => 'Danh sách phát';

  @override
  String get newPlaylist => 'Danh sách phát mới';

  @override
  String get playlistName => 'Tên';

  @override
  String get create => 'Tạo';

  @override
  String get cancel => 'Hủy';

  @override
  String get rename => 'Đổi tên';

  @override
  String get delete => 'Xóa';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Xóa \"$name\"?';
  }

  @override
  String get clearHistory => 'Xóa lịch sử';

  @override
  String get emptyLikes => 'Bài hát bạn thích sẽ xuất hiện ở đây';

  @override
  String get emptyHistory => 'Chưa phát gì';

  @override
  String get emptyPlaylist => 'Danh sách phát này trống';

  @override
  String get emptyPlaylists => 'Tạo danh sách phát và thêm bài hát qua menu ⋮.';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài hát',
      zero: 'Không có bài hát',
    );
    return '$_temp0';
  }

  @override
  String followers(String count) {
    return '$count người theo dõi';
  }

  @override
  String get playNext => 'Phát tiếp theo';

  @override
  String get addToQueue => 'Thêm vào hàng đợi';

  @override
  String get addToPlaylist => 'Thêm vào danh sách phát';

  @override
  String get removeFromPlaylist => 'Xóa khỏi danh sách phát';

  @override
  String get like => 'Thích';

  @override
  String get unlike => 'Bỏ thích';

  @override
  String get goToArtist => 'Đến trang nghệ sĩ';

  @override
  String get copyLink => 'Sao chép liên kết';

  @override
  String get linkCopied => 'Đã sao chép liên kết';

  @override
  String get addedToQueue => 'Đã thêm vào hàng đợi';

  @override
  String addedToPlaylist(String name) {
    return 'Đã thêm vào $name';
  }

  @override
  String alreadyInPlaylist(String name) {
    return 'Đã có trong $name';
  }

  @override
  String get nowPlaying => 'Đang phát';

  @override
  String get queue => 'Hàng đợi';

  @override
  String get lyrics => 'Lời bài hát';

  @override
  String get noLyrics => 'Không tìm thấy lời bài hát';

  @override
  String lyricsSource(String source) {
    return 'Lời bài hát: $source';
  }

  @override
  String get sleepTimer => 'Hẹn giờ ngủ';

  @override
  String get sleepOff => 'Tắt hẹn giờ';

  @override
  String sleepIn(int minutes) {
    return 'Dừng sau $minutes phút';
  }

  @override
  String minutes(int count) {
    return '$count phút';
  }

  @override
  String get speed => 'Tốc độ';

  @override
  String get shuffle => 'Trộn bài';

  @override
  String get repeatOff => 'Tắt lặp lại';

  @override
  String get repeatAll => 'Lặp lại tất cả';

  @override
  String get repeatOne => 'Lặp lại một bài';

  @override
  String get play => 'Phát';

  @override
  String get pause => 'Tạm dừng';

  @override
  String get next => 'Tiếp theo';

  @override
  String get previous => 'Trước';

  @override
  String get popularTracks => 'Phổ biến';

  @override
  String get playbackError => 'Không thể phát bài hát này';

  @override
  String get preview => 'Bản xem trước';

  @override
  String get protected => 'Được bảo vệ';

  @override
  String get protectedHint =>
      'Bài hát này được bảo vệ DRM và Pounce chưa thể phát – kể cả khi đã đăng nhập';

  @override
  String get protectedPlayable =>
      'Được bảo vệ DRM – do mô-đun DRM của trình duyệt giải mã';

  @override
  String get account => 'Tài khoản';

  @override
  String get login => 'Đăng nhập bằng SoundCloud';

  @override
  String get loginSubtitle =>
      'Đồng bộ lượt thích, danh sách phát và luồng của bạn';

  @override
  String get signup => 'Tạo tài khoản';

  @override
  String get loginPrivacy =>
      'Bạn đăng nhập trên trang của SoundCloud. Pounce không bao giờ thấy mật khẩu của bạn.';

  @override
  String get loginWaiting => 'Hoàn tất đăng nhập trong trình duyệt…';

  @override
  String get loginReopen => 'Mở lại';

  @override
  String get loginPasteLabel => 'Dán liên kết chuyển hướng';

  @override
  String get loginPasteHint =>
      'Sau khi đăng nhập, SoundCloud chuyển hướng tới liên kết sc://auth?code=… Nếu ứng dụng không tự nhận được, hãy dán vào đây.';

  @override
  String get loginPasteHintWeb =>
      'Một thẻ mới sẽ mở. Sau khi đăng nhập, thẻ hiển thị địa chỉ dạng soundcloud.com/signin/callback?code=… Hãy sao chép địa chỉ đó và dán vào đây.';

  @override
  String get loginConfirm => 'Tiếp tục';

  @override
  String get loginFailed => 'Đăng nhập thất bại';

  @override
  String loggedInAs(String name) {
    return 'Đã đăng nhập: $name';
  }

  @override
  String get logout => 'Đăng xuất';

  @override
  String get logoutConfirm =>
      'Đăng xuất? Lượt thích vẫn được giữ trên thiết bị này.';

  @override
  String get homeStream => 'Luồng của bạn';

  @override
  String get scPlaylists => 'Danh sách phát SoundCloud của bạn';

  @override
  String transferLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chuyển $count lượt thích cục bộ vào tài khoản?',
    );
    return '$_temp0';
  }

  @override
  String get transfer => 'Chuyển';

  @override
  String get notNow => 'Để sau';

  @override
  String get loudTitle => 'Chế độ âm lượng';

  @override
  String get loudDesc =>
      'Cân bằng bài lớn và nhỏ (ITU-R BS.1770), có bộ giới hạn tích hợp chống méo tiếng.';

  @override
  String get loudOff => 'Tắt';

  @override
  String get loudQuiet => 'Nhỏ';

  @override
  String get loudNormal => 'Bình thường';

  @override
  String get loudLoud => 'Lớn';

  @override
  String get loudUnsupported => 'Chưa khả dụng trên nền tảng này';

  @override
  String get signal => 'Tín hiệu';

  @override
  String get sigSource => 'Nguồn';

  @override
  String get sigLoudness => 'Độ to nguồn';

  @override
  String get sigMomentary => 'Tức thời';

  @override
  String get sigGain => 'Độ lợi';

  @override
  String get sigLimiter => 'Bộ giới hạn';

  @override
  String get sigOutput => 'Đầu ra';

  @override
  String get sigAnalysis => 'Phân tích';

  @override
  String get sigLive => 'FFT trực tiếp';

  @override
  String get sigEnvelope => 'Đường bao dạng sóng';

  @override
  String get sigClip => 'Quá tải';

  @override
  String get sigClean => 'Sạch';

  @override
  String get volume => 'Âm lượng';

  @override
  String get mute => 'Tắt tiếng';

  @override
  String get inspector => 'Bảng chi tiết';

  @override
  String get expandPlayer => 'Chế độ tập trung';

  @override
  String get expandRail => 'Mở rộng thanh bên';

  @override
  String get collapseRail => 'Thu gọn thanh bên';

  @override
  String get accentAmber => 'Hổ phách điện';

  @override
  String get accentCyan => 'Lam băng';

  @override
  String get accentCover => 'Theo ảnh bìa';

  @override
  String get beatBg => 'Nền theo nhịp';

  @override
  String get beatBgDesc => 'Màu sắc nhấp nháy và đổi theo mỗi nhịp';

  @override
  String get beatLight => 'Nhẹ';

  @override
  String get beatMedium => 'Vừa';

  @override
  String get beatStrong => 'Mạnh';

  @override
  String get appearance => 'Giao diện';

  @override
  String get themeSystem => 'Hệ thống';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get pureBlack => 'Đen tuyệt đối';

  @override
  String get pureBlackDesc => 'Nền đen ở chế độ tối (OLED)';

  @override
  String get dynamicColor => 'Màu hệ thống';

  @override
  String get dynamicColorDesc => 'Dùng màu nhấn của hệ thống';

  @override
  String get artworkColors => 'Màu theo ảnh bìa';

  @override
  String get artworkColorsDesc => 'Trình phát điều chỉnh màu theo ảnh bìa';

  @override
  String get accentColor => 'Màu nhấn';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageSystem => 'Mặc định hệ thống';

  @override
  String get playback => 'Phát lại';

  @override
  String get quality => 'Chất lượng phát';

  @override
  String get qualityHigh => 'Cao';

  @override
  String get qualitySaver => 'Tiết kiệm dữ liệu';

  @override
  String get autoplay => 'Tự động phát';

  @override
  String get autoplayDesc => 'Tiếp tục phát bài tương tự khi hết hàng đợi';

  @override
  String get network => 'Mạng';

  @override
  String get proxy => 'Proxy CORS';

  @override
  String get proxyDesc =>
      'Cần thiết trên trình duyệt vì SoundCloud chỉ cho phép trang web của họ.';

  @override
  String get about => 'Giới thiệu';

  @override
  String get aboutText =>
      'Lấy cảm hứng từ KittyTune (alan7383), viết mới hoàn toàn bằng Flutter. Phần mềm tự do theo GPL-3.0.';

  @override
  String get licenses => 'Giấy phép mã nguồn mở';

  @override
  String get previewBadge => 'Bản nghe thử (30 giây)';

  @override
  String get previewHint =>
      'SoundCloud chỉ cung cấp bản nghe thử 30 giây của bài này.';

  @override
  String get openInYtMusic => 'Mở trong YouTube Music';

  @override
  String get skipPreviews => 'Bỏ qua bản nghe thử';

  @override
  String get skipPreviewsDesc =>
      'Bỏ qua bản nghe thử 30 giây khi hàng đợi chuyển bài';

  @override
  String get fastStart => 'Khởi động nhanh';

  @override
  String get fastStartDesc =>
      'Bài được chạm sẽ phát dạng MP3 128 kbit/s – nhanh hơn, chất lượng hơi thấp hơn. Bài đã tải trước giữ chất lượng đã chọn.';

  @override
  String get navDj => 'DJ';

  @override
  String get djHeadline => 'DJ của bạn';

  @override
  String get djIntro =>
      'Chọn thứ bạn muốn nghe – Pounce trộn các bài bạn thích và bài tương tự, chuyển bài khớp tông, nhịp và drop.';

  @override
  String get djCategories => 'Thể loại';

  @override
  String get djBlend => 'Tỉ lệ';

  @override
  String get djFavorites => 'Yêu thích';

  @override
  String get djDiscover => 'Khám phá';

  @override
  String get djLookahead => 'Phân tích trước';

  @override
  String djLookaheadDesc(int count, int mb) {
    return '$count bài trước (~$mb MB)';
  }

  @override
  String get djStart => 'Bắt đầu mix';

  @override
  String get djBuilding => 'Đang tạo mix…';

  @override
  String get djNothing => 'Không tìm thấy bài phù hợp – thử thể loại khác.';

  @override
  String get djPickCategory => 'Chọn ít nhất một thể loại';

  @override
  String djAnalyzed(int done, int total) {
    return 'Đã phân tích $done/$total bài';
  }

  @override
  String djMixStarted(int count) {
    return 'Đã bắt đầu mix $count bài';
  }

  @override
  String get djStop => 'Dừng DJ';

  @override
  String get djSkip => 'Bỏ qua (chuyển mượt và học)';

  @override
  String get srcAll => 'Tất cả';

  @override
  String get srcRadio => 'Radio';

  @override
  String get radioSection => 'Radio trực tiếp · Đài';

  @override
  String get radioFavorites => 'Đài yêu thích';

  @override
  String get radioTop => 'Nghe nhiều nhất';

  @override
  String get radioAll => 'Tất cả đài';

  @override
  String get radioSource => 'Radio trực tuyến';

  @override
  String get radioSourceDesc =>
      'Hàng chục nghìn đài từ radio-browser.info. Tắt: không gửi yêu cầu nào.';

  @override
  String get live => 'TRỰC TIẾP';

  @override
  String get updates => 'Cập nhật';

  @override
  String get updatesAuto => 'Tự động kiểm tra cập nhật';

  @override
  String get updatesAutoDesc =>
      'Tối đa mỗi ngày một lần, một yêu cầu tới GitHub không kèm ID thiết bị. Không bao giờ tự tải xuống.';

  @override
  String get updatesCheck => 'Kiểm tra ngay';

  @override
  String get updatesNone => 'Pounce đã là bản mới nhất';

  @override
  String get updatesUnavailable => 'Bản dựng này không hỗ trợ cập nhật';

  @override
  String updateTitle(String version) {
    return 'Cập nhật lên $version';
  }

  @override
  String updateDownload(String mb) {
    return 'Tải và cài đặt ($mb MB)';
  }

  @override
  String get updateViaPlay => 'Cập nhật qua Google Play';

  @override
  String get updateLater => 'Để sau';

  @override
  String get updateReleasePage => 'Trang phát hành';

  @override
  String get updateChecksumFailed => 'Sai mã kiểm tra – bản tải đã bị huỷ.';

  @override
  String get updateNeedsPermission =>
      'Cho phép Pounce cài đặt ứng dụng rồi chạm lại.';

  @override
  String get updateFailed => 'Cập nhật thất bại – thử lại sau.';

  @override
  String get beta => 'Beta';

  @override
  String get betaNote =>
      'Pounce đang ở giai đoạn beta. Một số thứ có thể thay đổi hoặc lỗi – rất hoan nghênh góp ý trên GitHub.';

  @override
  String get setupWelcome => 'Chào mừng đến với Pounce';

  @override
  String get setupTagline =>
      'Nhạc nhanh từ SoundCloud và radio web – cùng một DJ trộn nhạc cho bạn.';

  @override
  String get setupStart => 'Bắt đầu';

  @override
  String get setupNext => 'Tiếp';

  @override
  String get setupBack => 'Quay lại';

  @override
  String get setupSkip => 'Bỏ qua thiết lập';

  @override
  String get setupDone => 'Bắt đầu nghe';

  @override
  String get setupSourcesTitle => 'Nhạc lấy từ đâu?';

  @override
  String get setupSoundcloudDesc =>
      'Hàng triệu bài hát, mix và remix. Luôn bật.';

  @override
  String get setupRadioDesc =>
      'Hơn 30.000 đài qua radio-browser.info. Tắt = không gửi yêu cầu nào.';

  @override
  String get setupAccountTitle => 'Mang theo lượt thích của bạn?';

  @override
  String get setupAccountDesc =>
      'Tùy chọn: đăng nhập SoundCloud để nhập lượt thích và danh sách phát. Pounce vẫn hoạt động mà không cần tài khoản.';

  @override
  String get setupSignIn => 'Đăng nhập SoundCloud';

  @override
  String get setupDjTitle => 'DJ của bạn sẽ phát gì?';

  @override
  String get setupDjDesc =>
      'Chọn vài phong cách. Bạn có thể đổi bất cứ lúc nào trong tab DJ.';

  @override
  String get setupPrivacyTitle => 'Quyền riêng tư của bạn';

  @override
  String get setupPrivacyDesc =>
      'Không theo dõi, không quảng cáo, không ID thiết bị. Mọi thứ dưới đây đều tắt cho đến khi bạn bật.';

  @override
  String get setupRecognition => 'Nhận diện bài hát (Echolot)';

  @override
  String get setupRecognitionDesc =>
      'Sẽ có trong bản beta sau. Chỉ gửi dấu vân tay âm thanh ẩn danh – không bao giờ gửi bản ghi âm – tới máy chủ Echolot.';

  @override
  String get setupAgain => 'Chạy lại thiết lập';

  @override
  String version(String version) {
    return 'Phiên bản $version';
  }

  @override
  String syncLast(int count) {
    return 'Đã đồng bộ ($count sự kiện mới)';
  }

  @override
  String get syncTitle => 'Đồng bộ thiết bị';

  @override
  String get syncBackground => 'Đồng bộ nền';

  @override
  String syncServerActive(int port) {
    return 'Máy chủ đang chạy (cổng $port) · P2P trong mạng nội bộ';
  }

  @override
  String get syncDisabled => 'Tắt';

  @override
  String get syncShowCode => 'Hiện mã ghép nối';

  @override
  String get syncShowCodeDesc => 'Mã cho các thiết bị khác của bạn';

  @override
  String get syncCodeTitle => 'Mã ghép nối';

  @override
  String get syncCodeHint => 'Nhập mã này trên thiết bị kia của bạn:';

  @override
  String get syncCodeCopied => 'Đã sao chép mã ghép nối';

  @override
  String get copy => 'Sao chép';

  @override
  String get done => 'Xong';

  @override
  String get syncPair => 'Ghép nối thiết bị';

  @override
  String get syncNoPeers => 'Chưa kết nối thiết bị nào khác';

  @override
  String syncPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã ghép $count thiết bị',
    );
    return '$_temp0';
  }

  @override
  String get syncPasteCode => 'Dán mã ghép nối';

  @override
  String get syncPairAction => 'Ghép nối';

  @override
  String get syncPaired => 'Đã ghép nối!';

  @override
  String get syncPairFailed => 'Ghép nối thất bại';

  @override
  String get syncNow => 'Đồng bộ ngay';

  @override
  String get syncNever => 'Chưa đồng bộ';

  @override
  String get syncDone => 'Đã đồng bộ';

  @override
  String get engineTitle => 'Engine âm thanh & hiệu năng';

  @override
  String engineRustDesc(String label) {
    return '$label · lưới nhịp, tông (chroma), độ lớn và dấu vân tay AI từ âm thanh thật';
  }

  @override
  String get engineUnavailable => 'Không khả dụng – chỉ ước tính từ dạng sóng';

  @override
  String get djFlowActiveDesc => 'Tự động khớp câu nhạc & tông';

  @override
  String get djTapToActivate => 'Chạm để bật';

  @override
  String get djAnalyzing => 'Đang phân tích âm thanh…';

  @override
  String get djNoKey => 'Không nhận ra tông';

  @override
  String get djKeyUncertain => 'không chắc';

  @override
  String djBar(int bar) {
    return 'Ô nhịp $bar/4';
  }

  @override
  String djPhraseBeat(int beat) {
    return 'Phách câu $beat/16';
  }

  @override
  String get statGrid => 'Lưới';

  @override
  String get statKey => 'Tông';

  @override
  String get statLoudness => 'Độ lớn';

  @override
  String get statEnergy => 'Năng lượng';

  @override
  String get statSource => 'Nguồn';

  @override
  String get srcAudio => 'Âm thanh';

  @override
  String get srcWaveform => 'Dạng sóng';

  @override
  String get srcTitle => 'Tiêu đề';

  @override
  String get djEnergiesLive => 'Năng lượng âm thanh (trực tiếp)';

  @override
  String djTransitionIn(int beats) {
    return 'Chuyển sau $beats phách';
  }

  @override
  String get djEnergyMode => 'Chế độ năng lượng hài hòa';

  @override
  String get djModeBuildUp => 'Tăng dần';

  @override
  String get djModeHold => 'Giữ';

  @override
  String get djModeWindDown => 'Hạ nhiệt';

  @override
  String get djHarmonic => 'Hài hòa';

  @override
  String get djNextBest => 'Bài tiếp theo (khớp nhất)';

  @override
  String djMatch(String pct) {
    return 'Khớp $pct%';
  }

  @override
  String get djMixNow => 'Trộn ngay';

  @override
  String get bandBass => 'BASS (kick & sub)';

  @override
  String get bandMid => 'TRUNG (giọng & giai điệu)';

  @override
  String get bandHigh => 'CAO (hi-hat & air)';

  @override
  String planDrop(String time) {
    return 'Drop $time';
  }

  @override
  String get planNoDrop => 'không có drop';

  @override
  String get planSearching => 'đang tìm drop…';

  @override
  String planText(String entry, String drop, String fade) {
    return 'Vào $entry · $drop · chuyển $fade giây';
  }
}
