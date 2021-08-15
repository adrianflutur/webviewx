import 'package:flutter/material.dart';
import 'dart:js' as js;

import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'package:webviewx/src/utils/source_type.dart';
import 'package:webviewx/src/utils/utils.dart';
import 'package:webviewx/src/utils/web_history.dart';

import '../interface.dart' as i;

/// Web implementation
class WebViewXController extends ChangeNotifier
    implements i.WebViewXController<js.JsObject> {
  /// JsObject connector
  @override
  late js.JsObject connector;

  @override
  final bool printDebugInfo;

  // Boolean value notifier used to toggle ignoring gestures on the webview
  final ValueNotifier<bool> _ignoreAllGesturesNotifier;

  // Stack-based custom history
  // First entry is the current url, last entry is the initial url
  final HistoryStack<WebViewContent> _history;

  WebViewContent get value => _history.currentEntry;

  /// Constructor
  WebViewXController({
    required String initialContent,
    required SourceType initialSourceType,
    required bool ignoreAllGestures,
    this.printDebugInfo = false,
  })  : _ignoreAllGesturesNotifier = ValueNotifier(ignoreAllGestures),
        _history = HistoryStack<WebViewContent>(
          initialEntry: WebViewContent(
            source: initialContent,
            sourceType: initialSourceType,
          ),
        );

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
  /// use the proxy bypass to fetch the web page content.
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
      var _content = await rootBundle.loadString(content);

      webAddNewHistoryEntry(
        WebViewContent(
          source: _content,
          sourceType: sourceType,
          headers: headers,
          webPostRequestBody: body,
        ),
      );
    } else {
      webAddNewHistoryEntry(
        WebViewContent(
          source: content,
          sourceType: sourceType,
          headers: headers,
          webPostRequestBody: body,
        ),
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
  @override
  Future<dynamic> callJsMethod(
    String name,
    List<dynamic> params,
  ) {
    var result = connector.callMethod(name, params);
    return Future<dynamic>.value(result);
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
    bool inGlobalContext = false,
  }) {
    var result = (inGlobalContext ? js.context : connector).callMethod(
      'eval',
      [rawJavascript],
    );
    return Future<dynamic>.value(result);
  }

  /// Returns the current content
  @override
  Future<WebViewContent> getContent() {
    return Future.value(value);
  }

  /// Returns a Future that completes with the value true, if you can go
  /// back in the history stack.
  @override
  Future<bool> canGoBack() {
    return Future.value(_history.canGoBack);
  }

  /// Go back in the history stack.
  @override
  Future<void> goBack() async {
    _history.moveBack();
    _printIfDebug(_history.toString());

    _notifyWidget();
  }

  /// Returns a Future that completes with the value true, if you can go
  /// forward in the history stack.
  @override
  Future<bool> canGoForward() {
    return Future.value(_history.canGoForward);
  }

  /// Go forward in the history stack.
  @override
  Future<void> goForward() async {
    _history.moveForward();
    _printIfDebug(_history.toString());

    _notifyWidget();
  }

  /// Reload the current content.
  @override
  Future<void> reload() async {
    _notifyWidget();
  }

  // WEB-ONLY.
  // YOU SHOULDN'T NEED TO CALL THIS FROM YOUR CODE.
  //
  // This is called internally by the web.dart view class, to add a new
  // iframe navigation history entry.
  //
  // This, and all history-related stuff is needed because the history on web
  // is basically reimplemented by me from scratch using the [HistoryEntry] class.
  // This had to be done because I couldn't intercept iframe's navigation events and
  // current url.
  void webAddNewHistoryEntry(WebViewContent content) {
    _history.addEntry(content);
    _printIfDebug('Got a new history entry: ${content.source}\n');
    _printIfDebug('History: ${_history.toString()}\n');
  }

  void _notifyWidget() {
    notifyListeners();
  }

  void addIgnoreGesturesListener(void Function() cb) {
    _ignoreAllGesturesNotifier.addListener(cb);
  }

  void removeIgnoreGesturesListener(void Function() cb) {
    _ignoreAllGesturesNotifier.removeListener(cb);
  }

  void _printIfDebug(String text) {
    if (printDebugInfo) {
      print(text);
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _ignoreAllGesturesNotifier.dispose();
    super.dispose();
  }
}
