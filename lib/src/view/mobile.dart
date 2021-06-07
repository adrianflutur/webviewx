import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webviewx/src/utils/utils.dart';
import 'package:webviewx/src/utils/view_content_model.dart';
import 'package:webviewx/src/controller/controller.dart';
import 'package:webview_flutter/platform_interface.dart' as wf_pi;
import 'package:webview_flutter/webview_flutter.dart' as wf;

/// Mobile implementation
class WebViewXWidget extends StatefulWidget {
  /// Initial content
  final String? initialContent;

  /// Initial source type. Must match [initialContent]'s type.
  ///
  /// Example:
  /// If you set [initialContent] to '<p>hi</p>', then you should
  /// also set the [initialSourceType] accordingly, that is [SourceType.HTML].
  final SourceType? initialSourceType;

  /// User-agent
  /// On web, this is only used when using [SourceType.URL_BYPASS]
  final String? userAgent;

  /// Widget width
  final double? width;

  /// Widget height
  final double? height;

  /// Callback which returns a referrence to the [WebViewXController]
  /// being created.
  final Function(WebViewXController? controller)? onWebViewCreated;

  /// A set of [EmbeddedJsContent].
  ///
  /// You can define JS functions, which will be embedded into
  /// the HTML source (won't do anything on URL) and you can later call them
  /// using the controller.
  ///
  /// For more info, see [EmbeddedJsContent].
  final Set<EmbeddedJsContent>? jsContent;

  /// A set of [DartCallback].
  ///
  /// You can define Dart functions, which can be called from the JS side.
  ///
  /// For more info, see [DartCallback].
  final Set<DartCallback>? dartCallBacks;

  /// Boolean value to specify if should ignore all gestures that touch the webview.
  ///
  /// You can change this later from the controller.
  final bool? ignoreAllGestures;

  /// Boolean value to specify if Javascript execution should be allowed inside the webview
  final JavascriptMode? javascriptMode;

  /// This defines if media content(audio - video) should
  /// auto play when entering the page.
  final AutoMediaPlaybackPolicy? initialMediaPlaybackPolicy;

  /// Callback for when the page starts loading.
  final void Function(String src)? onPageStarted;

  /// Callback for when the page has finished loading (i.e. is shown on screen).
  final void Function(String src)? onPageFinished;

  /// Callback for when something goes wrong in while page or resources load.
  final void Function(WebResourceError error)? onWebResourceError;

  /// Parameters specific to the web version.
  /// This may eventually be merged with [mobileSpecificParams],
  /// if all features become cross platform.
  final WebSpecificParams? webSpecificParams;

  /// Parameters specific to the web version.
  /// This may eventually be merged with [webSpecificParams],
  /// if all features become cross platform.
  final MobileSpecificParams? mobileSpecificParams;

  /// Constructor
  WebViewXWidget({
    Key? key,
    this.initialContent,
    this.initialSourceType,
    this.userAgent,
    this.width,
    this.height,
    this.onWebViewCreated,
    this.jsContent,
    this.dartCallBacks,
    this.ignoreAllGestures,
    this.javascriptMode,
    this.initialMediaPlaybackPolicy,
    this.onPageStarted,
    this.onPageFinished,
    this.onWebResourceError,
    this.webSpecificParams,
    this.mobileSpecificParams,
  }) : super(key: key);

  @override
  _WebViewXWidgetState createState() => _WebViewXWidgetState();
}

class _WebViewXWidgetState extends State<WebViewXWidget> {
  wf.WebViewController? originalWebViewController;
  WebViewXController? webViewXController;

  bool? _ignoreAllGestures;

  @override
  void initState() {
    super.initState();

    _ignoreAllGestures = widget.ignoreAllGestures;
    _createWebViewXController();
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
      var delegate = await widget.mobileSpecificParams!.navigationDelegate!(
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
      originalWebViewController = webViewController;

      webViewXController!.connector = originalWebViewController!;
      // Calls onWebViewCreated to pass the refference upstream
      if (widget.onWebViewCreated != null) {
        widget.onWebViewCreated!(webViewXController);
      }
    };
    final javascriptChannels = widget.dartCallBacks!
        .map(
          (cb) => wf.JavascriptChannel(
            name: cb.name,
            onMessageReceived: (msg) => cb.callBack!(msg.message),
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
            widget.mobileSpecificParams!.mobileGestureRecognizers,
        onPageStarted: widget.onPageStarted,
        onPageFinished: widget.onPageFinished,
        initialMediaPlaybackPolicy: initialMediaPlaybackPolicy,
        onWebResourceError: onWebResourceError,
        gestureNavigationEnabled:
            widget.mobileSpecificParams!.gestureNavigationEnabled,
        debuggingEnabled: widget.mobileSpecificParams!.debuggingEnabled,
        navigationDelegate: navigationDelegate,
        userAgent: widget.userAgent,
      ),
    );

    return IgnorePointer(
      ignoring: _ignoreAllGestures!,
      child: webview,
    );
  }

  // Returns initial data
  String? _initialContent() {
    if (widget.initialSourceType == SourceType.HTML) {
      return HtmlUtils.preprocessSource(
        widget.initialContent!,
        jsContent: widget.jsContent!,
        encodeHtml: true,
      );
    }
    return widget.initialContent;
  }

  // Creates a WebViewXController and adds the listener
  void _createWebViewXController() {
    webViewXController = WebViewXController(
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
  String? _prepareContent(ViewContentModel model) {
    if (model.sourceType == SourceType.HTML) {
      return HtmlUtils.preprocessSource(
        model.content!,
        jsContent: widget.jsContent!,

        // Needed for mobile webview in order to URI-encode the HTML
        encodeHtml: true,
      );
    }
    return model.content;
  }

  // Called when WebViewXController updates it's value
  void _handleChange() {
    final newContentModel = webViewXController!.value;

    originalWebViewController!.loadUrl(
      _prepareContent(newContentModel)!,
      headers: newContentModel.headers as Map<String, String>?,
    );
  }

  // Called when the ValueNotifier inside WebViewXController updates it's value
  void _handleIgnoreGesturesChange() {
    setState(() {
      _ignoreAllGestures = webViewXController!.ignoringAllGestures;
    });
  }

  @override
  void dispose() {
    webViewXController?.removeListener(_handleChange);
    webViewXController?.ignoreAllGesturesNotifier.removeListener(
      _handleIgnoreGesturesChange,
    );
    super.dispose();
  }
}
