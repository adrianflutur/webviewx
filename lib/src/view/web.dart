import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:webviewx/src/utils/constants.dart';

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:webviewx/src/utils/dart_ui_fix.dart' as ui;

import 'package:webviewx/src/controller/web.dart';
import 'package:webviewx/src/utils/utils.dart';
import 'package:webviewx/src/utils/view_content_model.dart';
import 'package:webviewx/src/utils/web_history.dart';

import '../utils/x_frame_options_bypass.dart';

/// Web implementation
class WebViewXWidget extends StatefulWidget {
  /// Initial content
  final String initialContent;

  /// Initial source type. Must match [initialContent]'s type.
  ///
  /// Example:
  /// If you set [initialContent] to '<p>hi</p>', then you should
  /// also set the [initialSourceType] accordingly, that is [SourceType.HTML].
  final SourceType initialSourceType;

  /// User-agent
  /// On web, this is only used when using [SourceType.URL_BYPASS]
  final String userAgent;

  /// Widget width
  final double width;

  /// Widget height
  final double height;

  /// Callback which returns a referrence to the [WebViewXController]
  /// being created.
  final Function(WebViewXController controller) onWebViewCreated;

  /// A set of [EmbeddedJsContent].
  ///
  /// You can define JS functions, which will be embedded into
  /// the HTML source (won't do anything on URL) and you can later call them
  /// using the controller.
  ///
  /// For more info, see [EmbeddedJsContent].
  final Set<EmbeddedJsContent> jsContent;

  /// A set of [DartCallback].
  ///
  /// You can define Dart functions, which can be called from the JS side.
  ///
  /// For more info, see [DartCallback].
  final Set<DartCallback> dartCallBacks;

  /// Boolean value to specify if should ignore all gestures that touch the webview.
  ///
  /// You can change this later from the controller.
  final bool ignoreAllGestures;

  /// Boolean value to specify if Javascript execution should be allowed inside the webview
  final JavascriptMode javascriptMode;

  /// This defines if media content(audio - video) should
  /// auto play when entering the page.
  final AutoMediaPlaybackPolicy initialMediaPlaybackPolicy;

  /// Callback for when the page starts loading.
  final void Function(String src) onPageStarted;

  /// Callback for when the page has finished loading (i.e. is shown on screen).
  final void Function(String src) onPageFinished;

  /// Callback for when something goes wrong in while page or resources load.
  final void Function(WebResourceError error) onWebResourceError;

  /// Parameters specific to the web version.
  /// This may eventually be merged with [mobileSpecificParams],
  /// if all features become cross platform.
  final WebSpecificParams webSpecificParams;

  /// Parameters specific to the web version.
  /// This may eventually be merged with [webSpecificParams],
  /// if all features become cross platform.
  final MobileSpecificParams mobileSpecificParams;

  /// Constructor
  WebViewXWidget({
    Key key,
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
  html.IFrameElement iframe;
  StreamSubscription iframeOnLoadSubscription;
  String iframeViewType;
  js.JsObject jsWindowObject;

  WebViewXController webViewXController;

  // Pseudo state used to find out if the current iframe
  // has started or finished loading.
  bool _pageLoadFinished;
  bool _ignoreAllGestures;

  @override
  void initState() {
    super.initState();
    _addXFrameElement();

    // Initialize to true, because it will start loading once it is created
    _pageLoadFinished = true;
    _ignoreAllGestures = widget.ignoreAllGestures;

    iframeViewType = _createViewType();
    iframe = _createIFrame();

    _createWebViewXController();

    if (widget.initialSourceType == SourceType.HTML ||
        widget.initialSourceType == SourceType.URL_BYPASS ||
        (widget.initialSourceType == SourceType.URL &&
            widget.initialContent == 'about:blank')) {
      _connectJsToFlutter(then: _callOnWebViewCreatedCallback);
    } else {
      _callOnWebViewCreatedCallback();
    }

    _registerIframeOnLoadCallback();

    // Hack to allow the iframe to reach the "begin loading" state.
    // Otherwise it will fail loading the initial content.
    Future.delayed(Duration.zero, () {
      var newContentModel = webViewXController.value;
      _updateSource(newContentModel);
    });
  }

  void _addXFrameElement() {
    var head = html.document.head;

    var script = html.ScriptElement()
      ..text = XFrameOptionsBypass.build(
        cssloader: widget.webSpecificParams.cssLoadingIndicator,
        printDebugInfo: widget.webSpecificParams.printDebugInfo,
      );

    if (!head.contains(script)) {
      head.append(script);
    }

    _printIfDebug('The XFrameBypass custom iframe element has loaded');
  }

  void _createWebViewXController() {
    webViewXController = WebViewXController(
      initialContent: widget.initialContent,
      initialSourceType: widget.initialSourceType,
      ignoreAllGestures: _ignoreAllGestures,
    )
      ..printDebugInfo = widget.webSpecificParams.printDebugInfo
      ..addListener(_handleChange)
      ..ignoreAllGesturesNotifier.addListener(
        _handleIgnoreGesturesChange,
      );
  }

  // Keep js "window" object referrence, so we can call functions on it later.
  // This happens only if we use HTML (because you can't alter the source code
  // of some other webpage that you pass in using the URL param)
  //
  // Iframe viewType is used as a disambiguator.
  // Check function [embedWebIframeJsConnector] from [HtmlUtils] for details.
  void _connectJsToFlutter({VoidCallback then}) {
    js.context['$JS_DART_CONNECTOR_FN$iframeViewType'] = (window) {
      jsWindowObject = window;

      /// Register dart callbacks one by one.
      for (var cb in widget.dartCallBacks) {
        jsWindowObject[cb.name] = cb.callBack;
      }

      // Register history callback
      jsWindowObject[WEB_HISTORY_CALLBACK] = (newHref) {
        if (newHref != null) {
          webViewXController.webAddHistory(
            HistoryEntry(
              source: newHref,
              sourceType: SourceType.URL_BYPASS,
            ),
          );

          _printIfDebug('Got a new history entry');
        }
      };

      webViewXController.connector = jsWindowObject;

      if (then != null) {
        then();
      }
    };
  }

  void _registerIframeOnLoadCallback() {
    iframeOnLoadSubscription = iframe.onLoad.listen((event) {
      _printIfDebug('IFrame $iframeViewType has been (re)loaded.');

      if (_pageLoadFinished) {
        // This means it has loaded twice, so it has finished loading
        if (widget.onPageFinished != null) {
          widget.onPageFinished(iframe.srcdoc);
        }
        _pageLoadFinished = false;
      } else {
        // Hack to inject the connector function and js content inside the new source
        // Only when the source was set from inside itself (load function, on click)

        // NOTE: MAY HAVE UNDESIRED BEHAVIOUR

        if (webViewXController.value.sourceType == SourceType.URL_BYPASS) {
          iframe.srcdoc = HtmlUtils.preprocessSource(
            iframe.srcdoc,
            jsContent: widget.jsContent,
            windowDisambiguator: iframeViewType,
            forWeb: true,
          );
        }

        // This means it is the first time it loads
        if (widget.onPageStarted != null) {
          widget.onPageStarted(iframe.srcdoc);
        }
        _pageLoadFinished = true;
      }
    });
  }

  void _callOnWebViewCreatedCallback() {
    if (widget.onWebViewCreated != null) {
      widget.onWebViewCreated(webViewXController);
    }
  }

  @override
  Widget build(BuildContext context) {
    _registerView(
      viewType: iframeViewType,
    );

    Widget htmlElementView = SizedBox(
      width: widget.width,
      height: widget.height,
      child: _htmlElement(iframeViewType),
    );

    return _iframeIgnorePointer(
      child: htmlElementView,
      ignoring: _ignoreAllGestures,
    );
  }

  Widget _iframeIgnorePointer({@required Widget child, bool ignoring = false}) {
    return Stack(
      children: [
        child,
        ignoring
            ? Positioned.fill(
                child: PointerInterceptor(
                  child: Container(),
                ),
              )
            : SizedBox.shrink(),
      ],
    );
  }

  void _registerView({@required String viewType}) {
    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      return iframe;
    });
  }

  Widget _htmlElement(String iframeViewType) {
    return AbsorbPointer(
      child: RepaintBoundary(
        child: HtmlElementView(
          key: widget?.key,
          viewType: iframeViewType,
        ),
      ),
    );
  }

  // This creates a unique String to be used as the view type of the HtmlElementView
  String _createViewType() {
    return HtmlUtils.buildIframeViewType();
  }

  html.IFrameElement _createIFrame() {
    var xFrameBypassElement = html.Element.html(
      '<iframe is="x-frame-bypass"></iframe>',
      validator: null,
      treeSanitizer: html.NodeTreeSanitizer.trusted,
    ) as html.IFrameElement;

    var iframeElement = xFrameBypassElement
      ..id = 'id_$iframeViewType'
      ..name = 'name_$iframeViewType'
      ..style.border = 'none'
      ..width = widget.width.toInt().toString()
      ..height = widget.height.toInt().toString()
      ..allowFullscreen = widget.webSpecificParams.webAllowFullscreenContent;

    widget.webSpecificParams.additionalSandboxOptions
        .forEach(iframeElement.sandbox.add);

    if (widget.javascriptMode == JavascriptMode.unrestricted) {
      iframeElement.sandbox.add('allow-scripts');
    }

    var allow = widget.webSpecificParams.additionalAllowOptions;

    if (widget.initialMediaPlaybackPolicy ==
        AutoMediaPlaybackPolicy.always_allow) {
      allow.add('autoplay');
    }

    iframeElement.allow = allow.reduce((curr, next) => '$curr; $next');

    return iframeElement;
  }

  /* Maybe can be useful
  html.DivElement _createDivWrapper(html.IFrameElement iframeToAppend) {
    return html.DivElement()
      ..id = 'div_$iframeViewType'
      ..style.width = '100%'
      ..style.height = '100%'
      ..append(iframeToAppend);
  }
  */

  // Called when WebViewXController updates it's value
  //
  // When the content changes from URL to HTML,
  // the connection must be remade in order to
  // add the connector to the controller (connector that
  // allows you to call JS methods)
  void _handleChange() {
    var newContentModel = webViewXController.value;

    switch (newContentModel.sourceType) {
      case SourceType.HTML:
        _connectJsToFlutter();
        _pageLoadFinished = true;
        break;
      case SourceType.URL:
        _pageLoadFinished = true;
        if (newContentModel.content == 'about:blank') {
          _connectJsToFlutter();
        }
        break;
      case SourceType.URL_BYPASS:
        _connectJsToFlutter();
        break;
    }

    _updateSource(newContentModel);
  }

  void _handleIgnoreGesturesChange() {
    setState(() {
      _ignoreAllGestures = webViewXController.ignoringAllGestures;
    });
  }

  // Updates the source depending if it is HTML or URL
  void _updateSource(ViewContentModel newContentModel) {
    var source = newContentModel.content;

    if (source == null || source.isEmpty) {
      _printIfDebug('Error: Cannot set null or empty source on webview');
      return;
    }

    switch (newContentModel.sourceType) {
      case SourceType.HTML:
        iframe.srcdoc = HtmlUtils.preprocessSource(
          source,
          jsContent: widget.jsContent,
          windowDisambiguator: iframeViewType,
          forWeb: true,
        );
        break;
      case SourceType.URL:
      case SourceType.URL_BYPASS:
        if (source == 'about:blank') {
          iframe.srcdoc = HtmlUtils.preprocessSource(
            '<br>',
            jsContent: widget.jsContent,
            windowDisambiguator: iframeViewType,
            forWeb: true,
          );
          break;
        }
        if (source.startsWith(RegExp('http[s]?', caseSensitive: false))) {
          if (newContentModel.sourceType == SourceType.URL_BYPASS) {
            var headers = newContentModel.headers;
            if (widget.userAgent != null) {
              headers[USER_AGENT_HEADERS_KEY] = widget.userAgent;
            }
            var options = jsonEncode(headers);
            var optionsIndicator =
                '/[$BYPASS_URL_ADDITIONAL_OPTIONS_STARTING_POINT]';
            var url =
                source + optionsIndicator + base64Encode(utf8.encode(options));

            //TODO Issue: On web, this only works the first time being used. When the user clicks a link,
            // theese options are lost.
            iframe.src = url;
          } else {
            iframe.contentWindow.location.href = source;
          }
        } else {
          _printIfDebug('Error: Invalid URL supplied for webview.');
        }
        break;
    }
  }

  void _printIfDebug(String text) {
    if (widget.webSpecificParams.printDebugInfo) {
      print(text);
    }
  }

  @override
  void dispose() {
    iframeOnLoadSubscription?.cancel();
    webViewXController?.removeListener(_handleChange);
    webViewXController?.ignoreAllGesturesNotifier?.removeListener(
      _handleIgnoreGesturesChange,
    );
    super.dispose();
  }
}
