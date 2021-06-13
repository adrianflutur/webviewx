import 'package:webview_windows/webview_windows.dart';

import '../../webviewx.dart';

class WindowsWebViewXController extends WebViewXController {
  WebviewController _controller;

  WindowsWebViewXController(
    this._controller, {
    required String initialContent,
    required SourceType initialSourceType,
    required bool ignoreAllGestures,
  }) : super(
          initialContent: initialContent,
          initialSourceType: initialSourceType,
          ignoreAllGestures: ignoreAllGestures,
        );
}
