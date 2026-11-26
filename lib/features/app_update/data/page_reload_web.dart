import 'package:web/web.dart' as web;

/// Reloads the web app so the browser picks up the newly deployed build.
void reloadPage() => web.window.location.reload();
