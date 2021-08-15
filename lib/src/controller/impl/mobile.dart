import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webviewx/src/utils/html_utils.dart';

import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'package:webviewx/src/utils/source_type.dart';
import 'package:webviewx/src/utils/utils.dart';
import '../interface.dart' as i;

/// Mobile implementation
class WebViewXController extends ChangeNotifier
    implements i.WebViewXController<WebViewController> {
  /// Webview controller connector
  @override
  late WebViewController connector;

  @override
  final bool printDebugInfo;

  /// Boolean value notifier used to toggle ignoring gestures on the webview
  final ValueNotifier<bool> _ignoreAllGesturesNotifier;

  late WebViewContent value;

  /// Constructor
  WebViewXController({
    required String initialContent,
    required SourceType initialSourceType,
    required bool ignoreAllGestures,
    this.printDebugInfo = false,
  })  : _ignoreAllGesturesNotifier = ValueNotifier(ignoreAllGestures),
        value = WebViewContent(
          source: initialContent,
          sourceType: initialSourceType,
        );

  void updateCurrentValue(WebViewContent newModel) => value = newModel;

  /// Boolean getter which reveals if the gestures are ignored right now
  @override
  bool get ignoresAllGestures => _ignoreAllGesturesNotifier.value;

  /// Function to set ignoring gestures
  @override
  void setIgnoreAllGestures(bool value) {
    _ignoreAllGesturesNotifier.value = value;
  }

  /// Returns true if the webview's current content is HTML
  @override
  bool get isCurrentContentHTML => value.sourceType == SourceType.HTML;

  /// Returns true if the webview's current content is URL
  @override
  bool get isCurrentContentURL => value.sourceType == SourceType.URL;

  /// Returns true if the webview's current content is URL, and if
  /// [SourceType] is [SourceType.URL_BYPASS], which means it should
  /// use the bypass to fetch the web page content.
  @override
  bool get isCurrentContentURLBypass => value.sourceType == SourceType.URL_BYPASS;

  /// Set webview content to the specified URL.
  /// Example URL: https://flutter.dev
  ///
  /// If [fromAssets] param is set to true,
  /// [url] param must be a String path to an asset
  /// Example: 'assets/some_url.txt'
  @override
  Future<void> loadContent(
    String content,
    SourceType sourceType, {
    Map<String, String>? headers,
    Object? body,
    bool fromAssets = false,
  }) async {
    if (fromAssets) {
      final _content = await rootBundle.loadString(content);

      value = WebViewContent(
        source: _content,
        sourceType: sourceType,
        headers: headers,
        webPostRequestBody: body,
      );
    } else {
      value = WebViewContent(
        source: content,
        sourceType: sourceType,
        headers: headers,
        webPostRequestBody: body,
      );
    }

    _notifyWidget();
  }

  /// This function allows you to call Javascript functions defined inside the webview.
  ///
  /// Suppose we have a defined a function (using [EmbeddedJsContent]) as follows:
  ///
  /// ```javascript
  /// function someFunction(param) {
  ///   return 'This is a ' + param;
  /// }
  /// ```
  /// Example call:
  ///
  /// ```dart
  /// var resultFromJs = await callJsMethod('someFunction', ['test'])
  /// print(resultFromJs); // prints "This is a test"
  /// ```
  //TODO This should return an error if the operation failed, but it doesn't
  @override
  Future<dynamic> callJsMethod(
    String name,
    List<dynamic> params,
  ) async {
    // This basically will transform a "raw" call (evaluateJavascript)
    // into a little bit more "typed" call, that is - calling a method.
    var result = await connector.evaluateJavascript(
      HtmlUtils.buildJsFunction(name, params),
    );

    // (MOBILE ONLY) Unquotes response if necessary
    //
    // In the mobile version responses from Js to Dart come wrapped in single quotes (')
    // The web works fine because it is already into it's native environment
    return HtmlUtils.unQuoteJsResponseIfNeeded(result);
  }

  /// This function allows you to evaluate 'raw' javascript (e.g: 2+2)
  /// If you need to call a function you should use the method above ([callJsMethod])
  ///
  /// The [inGlobalContext] param should be set to true if you wish to eval your code
  /// in the 'window' context, instead of doing it inside the corresponding iframe's 'window'
  ///
  /// For more info, check Mozilla documentation on 'window'
  @override
  Future<dynamic> evalRawJavascript(
    String rawJavascript, {
    bool inGlobalContext = false, // NO-OP HERE
  }) {
    return connector.evaluateJavascript(rawJavascript);
  }

  /// Returns the current content
  @override
  Future<WebViewContent> getContent() async {
    var currentContent = await connector.currentUrl();
    var currentSourceType = value.sourceType;

    if (currentContent!.substring(0, 5) == 'data:') {
      currentContent = HtmlUtils.dataUriToHtml(currentContent);
      currentSourceType = SourceType.HTML;
    }

    return value.copyWith(
      source: currentContent,
      sourceType: currentSourceType,
    );
  }

  /// Returns a Future that completes with the value true, if you can go
  /// back in the history stack.
  @override
  Future<bool> canGoBack() {
    return connector.canGoBack();
  }

  /// Go back in the history stack.
  @override
  Future<void> goBack() async {
    if (await canGoBack()) {
      await connector.goBack();
      final liveContent = await getContent();
      value = liveContent;
    }
  }

  /// Returns a Future that completes with the value true, if you can go
  /// forward in the history stack.
  @override
  Future<bool> canGoForward() {
    return connector.canGoForward();
  }

  /// Go forward in the history stack.
  @override
  Future<void> goForward() async {
    if (await canGoForward()) {
      await connector.goForward();
      final liveContent = await connector.currentUrl();
      value = value.copyWith(source: liveContent);
    }
  }

  /// Reload the current content.
  @override
  Future<void> reload() {
    return connector.reload();
  }

  void addIgnoreGesturesListener(void Function() cb) {
    _ignoreAllGesturesNotifier.addListener(cb);
  }

  void removeIgnoreGesturesListener(void Function() cb) {
    _ignoreAllGesturesNotifier.removeListener(cb);
  }

  void _notifyWidget() {
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    _ignoreAllGesturesNotifier.dispose();
    super.dispose();
  }
}
