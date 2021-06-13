import 'package:flutter/widgets.dart';
import 'package:webview_flutter/platform_interface.dart' as wf_pi;
import 'package:webview_flutter/webview_flutter.dart' as wf;
import 'package:webviewx/src/utils/view_content_model.dart';
import 'package:webviewx/src/view/device.dart';

import '../../webviewx.dart';

class MobileWebViewXWidgetState extends State<WebViewXWidget> {
  late wf.WebViewController originalWebViewController;
  late WebViewXController webViewXController;

  late bool _ignoreAllGestures;

  @override
  void initState() {
    super.initState();

    _ignoreAllGestures = widget.ignoreAllGestures;
    webViewXController = _createWebViewXController();
  }

  @override
  Widget build(BuildContext context) {
     final javascriptMode = wf.JavascriptMode.values.singleWhere(
      (value) => value.toString() == widget.javascriptMode.toString(),
    );
    final initialMediaPlaybackPolicy =
        wf.AutoMediaPlaybackPolicy.values.singleWhere(
      (value) =>
          value.toString() == widget.initialMediaPlaybackPolicy.toString(),
    );
    final onWebResourceError =
        (wf_pi.WebResourceError err) => widget.onWebResourceError!(
              WebResourceError(
                description: err.description,
                errorCode: err.errorCode,
                domain: err.domain,
                errorType: WebResourceErrorType.values.singleWhere(
                  (value) => value.toString() == err.errorType.toString(),
                ),
                failingUrl: err.failingUrl,
              ),
            );
    final navigationDelegate = (wf.NavigationRequest request) async {
      var delegate = await widget.mobileSpecificParams.navigationDelegate!(
        NavigationRequest(
          content: request.url,
          isForMainFrame: request.isForMainFrame,
        ),
      );
      return wf.NavigationDecision.values.singleWhere(
        (value) => value.toString() == delegate.toString(),
      );
    };
    final onWebViewCreated = (wf.WebViewController webViewController) {
      webViewXController.connector = webViewController;
      // Calls onWebViewCreated to pass the refference upstream
      if (widget.onWebViewCreated != null) {
        widget.onWebViewCreated!(webViewXController);
      }
    };
    final javascriptChannels = widget.dartCallBacks
        .map(
          (cb) => wf.JavascriptChannel(
            name: cb.name,
            onMessageReceived: (msg) => cb.callBack(msg.message),
          ),
        )
        .toSet();

    Widget webview = SizedBox(
      width: widget.width,
      height: widget.height,
      child: wf.WebView(
        key: widget.key,
        initialUrl: _initialContent(),
        javascriptMode: javascriptMode,
        onWebViewCreated: onWebViewCreated,
        javascriptChannels: javascriptChannels,
        gestureRecognizers:
            widget.mobileSpecificParams.mobileGestureRecognizers,
        onPageStarted: widget.onPageStarted,
        onPageFinished: widget.onPageFinished,
        initialMediaPlaybackPolicy: initialMediaPlaybackPolicy,
        onWebResourceError: onWebResourceError,
        gestureNavigationEnabled:
            widget.mobileSpecificParams.gestureNavigationEnabled,
        debuggingEnabled: widget.mobileSpecificParams.debuggingEnabled,
        navigationDelegate: navigationDelegate,
        userAgent: widget.userAgent,
      ),
    );

    return IgnorePointer(
      ignoring: _ignoreAllGestures,
      child: webview,
    );
  }

  // Returns initial data
  String? _initialContent() {
    if (widget.initialSourceType == SourceType.HTML) {
      return HtmlUtils.preprocessSource(
        widget.initialContent,
        jsContent: widget.jsContent,
        encodeHtml: true,
      );
    }
    return widget.initialContent;
  }

  // Creates a WebViewXController and adds the listener
  WebViewXController _createWebViewXController() {
    return WebViewXController(
      initialContent: widget.initialContent,
      initialSourceType: widget.initialSourceType,
      ignoreAllGestures: _ignoreAllGestures,
    )
      ..addListener(_handleChange)
      ..ignoreAllGesturesNotifier.addListener(
        _handleIgnoreGesturesChange,
      );
  }

  // Prepares the source depending if it is HTML or URL
  String _prepareContent(ViewContentModel model) {
    if (model.sourceType == SourceType.HTML) {
      return HtmlUtils.preprocessSource(
        model.content,
        jsContent: widget.jsContent,

        // Needed for mobile webview in order to URI-encode the HTML
        encodeHtml: true,
      );
    }
    return model.content;
  }

  // Called when WebViewXController updates it's value
  void _handleChange() {
    final newContentModel = webViewXController.value;

    originalWebViewController.loadUrl(
      _prepareContent(newContentModel),
      headers: newContentModel.headers,
    );
  }

  // Called when the ValueNotifier inside WebViewXController updates it's value
  void _handleIgnoreGesturesChange() {
    setState(() {
      _ignoreAllGestures = webViewXController.ignoringAllGestures;
    });
  }

  @override
  void dispose() {
    webViewXController.removeListener(_handleChange);
    webViewXController.ignoreAllGesturesNotifier.removeListener(
      _handleIgnoreGesturesChange,
    );
    super.dispose();
  }
}