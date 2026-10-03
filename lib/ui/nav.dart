import 'package:material_ui/material_ui.dart';

/// Opens a page in the current tab's navigator.
Future<T?> pushPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));
