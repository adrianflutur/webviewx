import 'package:flutter/material.dart';
import 'dart:js' as js;

import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'package:webviewx/src/utils/source_type.dart';
import 'package:webviewx/src/utils/utils.dart';
import 'package:webviewx/src/utils/view_content_model.dart';
import 'package:webviewx/src/utils/web_history.dart';

/// Web implementation
class WebViewXController extends ValueNotifier<ViewContentModel> {
  /// JsObject connector
  js.JsObject? connector;

  /// Boolean value notifier used to toggle ignoring gestures on the webview
  ValueNotifier<bool?> ignoreAllGesturesNotifier;

  // Stack-based custom history
  // First entry is the current url, last entry is the initial url
  final HistoryStack _history;

  bool printDebugInfo = false;

  /// Constructor
  WebViewXController({
    String? initialContent,
    SourceType? initialSourceType,
    bool? ignoreAllGestures,
  })  : ignoreAllGesturesNotifier = ValueNotifier(ignoreAllGestures),
        _history = HistoryStack(
          initialEntry: HistoryEntry(
            source: initialContent,
            sourceType: initialSourceType,
          ),
        ),
        super(
          ViewContentModel(
            content: initialContent,
            sourceType: initialSourceType,
          ),
        );

  void _setContent(ViewContentModel model) {
    value = model;
  }

  /// Returns true if the webview's current content is HTML
  bool get isCurrentContentHTML => value.sourceType == SourceType.HTML;

  /// Returns true if the webview's current content is URL
  bool get isCurrentContentURL => value.sourceType == SourceType.URL;

  /// Returns true if the webview's current content is URL, and if
  /// [SourceType] is [SourceType.URL_BYPASS], which means it should
  /// use the bypass to fetch the web page content.
  bool get isCurrentContentURLBypass =>
      value.sourceType == SourceType.URL_BYPASS;

  /// Set webview content to the specified URL.
  /// Example URL: https://flutter.dev
  ///
  /// If [fromAssets] param is set to true,
  /// [url] param must be a String path to an asset
  /// Example: 'assets/some_url.txt'
  void loadContent(
    String content,
    SourceType sourceType, {
    Map<String, String> headers = const {},
    bool fromAssets = false,
  }) async {
    if (fromAssets) {
      var _content = await rootBundle.loadString(content);
      _setContent(ViewContentModel(
        content: _content,
        headers: headers,
        sourceType: sourceType,
      ));
      webAddHistory(HistoryEntry(source: _content, sourceType: sourceType));
    } else {
      _setContent(ViewContentModel(
        content: content,
        headers: headers,
        sourceType: sourceType,
      ));
      webAddHistory(HistoryEntry(source: content, sourceType: sourceType));
    }
  }

  /// Boolean getter which reveals if the gestures are ignored right now
  bool? get ignoringAllGestures => ignoreAllGesturesNotifier.value;

  /// Function to set ignoring gestures
  void setIgnoreAllGestures(bool value) {
    ignoreAllGesturesNotifier.value = value;
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
  Future<dynamic> callJsMethod(
    String name,
    List<dynamic> params,
  ) {
    var result = connector!.callMethod(name, params);
    return Future<dynamic>.value(result);
  }

  /// This function allows you to evaluate 'raw' javascript (e.g: 2+2)
  /// If you need to call a function you should use the method above ([callJsMethod])
  ///
  /// The [inGlobalContext] param should be set to true if you wish to eval your code
  /// in the 'window' context, instead of doing it inside the corresponding iframe's 'window'
  ///
  /// For more info, check Mozilla documentation on 'window'
  Future<dynamic> evalRawJavascript(
    String rawJavascript, {
    bool inGlobalContext = false,
  }) {
    var result = (inGlobalContext ? js.context : connector)!.callMethod(
      'eval',
      [rawJavascript],
    );
    return Future<dynamic>.value(result);
  }

  /// WEB-ONLY. YOU SHOULDN'T NEED TO CALL THIS FROM YOUR CODE.
  ///
  /// This is called internally by the web.dart view class, to add a new
  /// iframe navigation history entry.
  ///
  /// This, and all history-related stuff is needed because the history on web
  /// is basically reimplemented by me from scratch using the [HistoryEntry] class.
  /// This had to be done because I couldn't intercept iframe's navigation events and
  /// current url.
  void webAddHistory(HistoryEntry entry) {
    _history.addEntry(entry);
    _printIfDebug(_history.toString());
  }

  /// Returns the current content
  Future<WebViewContent> getContent() {
    return Future.value(
      WebViewContent(
        source: _history.currentEntry!.source,
        sourceType: _history.currentEntry!.sourceType,
      ),
    );
  }

  /// Returns a Future that completes with the value true, if you can go
  /// back in the history stack.
  Future<bool> canGoBack() {
    return Future.value(_history.canGoBack);
  }

  /// Go back in the history stack.
  void goBack() {
    var entry = _history.moveBack()!;
    _setContent(ViewContentModel(
      content: entry.source,
      sourceType: entry.sourceType,
    ));
    _printIfDebug(_history.toString());
  }

  /// Returns a Future that completes with the value true, if you can go
  /// forward in the history stack.
  Future<bool> canGoForward() {
    return Future.value(_history.canGoForward);
  }

  /// Go forward in the history stack.
  void goForward() {
    var entry = _history.moveForward()!;
    _setContent(ViewContentModel(
      content: entry.source,
      sourceType: entry.sourceType,
    ));
    _printIfDebug(_history.toString());
  }

  /// Reload the current content.
  void reload() {
    _setContent(ViewContentModel(
      content: _history.currentEntry!.source,
      sourceType: _history.currentEntry!.sourceType,
    ));
  }

  void _printIfDebug(String text) {
    if (printDebugInfo) {
      print(text);
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    ignoreAllGesturesNotifier.dispose();
    super.dispose();
  }
}
