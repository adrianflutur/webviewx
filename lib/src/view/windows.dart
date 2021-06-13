import 'package:flutter/widgets.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:webviewx/src/controller/windows.dart';

import 'device.dart';

class WindowsWebViewXWidgetState extends State<WebViewXWidget> {
  late WebviewController _controller;
  late WindowsWebViewXController _windowsWebViewXController;

  @override
  void initState() {
    super.initState();

    initPlatformState();
  }

  Future<void> initPlatformState() async {
    _controller = WebviewController();

    await _controller.initialize();

    _windowsWebViewXController = WindowsWebViewXController(
      _controller,
      initialContent: widget.initialContent,
      initialSourceType: widget.initialSourceType,
      ignoreAllGestures: widget.ignoreAllGestures,
    );

    if (widget.onWebViewCreated != null) {
      widget.onWebViewCreated!(_windowsWebViewXController);
    }

    await _controller.loadUrl('https://flutter.dev');

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget webview = SizedBox(
      width: widget.width,
      height: widget.height,
      child: Webview(_controller)
    );

    return IgnorePointer(
      ignoring: widget.ignoreAllGestures,
      child: webview,
    );
  }
}
