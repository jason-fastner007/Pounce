import 'platform.dart';
import 'settings.dart';

/// Web: route a request through the configured CORS proxy; elsewhere the URI stays as is.
Uri Function(Uri) corsProxy(Settings settings) => (uri) {
  final proxy = settings.proxy;
  if (!Platform.isWeb || proxy.isEmpty) return uri;
  // Relative proxy (e.g. /proxy?url=) = same server as the app.
  return Uri.base.resolve('$proxy${Uri.encodeComponent(uri.toString())}');
};
