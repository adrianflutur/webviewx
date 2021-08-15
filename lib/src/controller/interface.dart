import 'package:flutter/material.dart';
import 'package:webviewx/src/utils/source_type.dart';
import 'package:webviewx/src/utils/web_history.dart';
import 'package:webviewx/src/utils/webview_content_model.dart';

/// Interface for controller
abstract class WebViewXController<T> {
  /// Cross-platform webview connector
  ///
  /// At runtime, this will be WebViewController, JsObject or other concrete
  /// controller implementation
  late T connector;

  /// Boolean value notifier used to toggle ignoring gestures on the webview
  ValueNotifier<bool> ignoreAllGesturesNotifier;

  /// Constructor
  WebViewXController({
    required String initialContent,
    required SourceType initialSourceType,
    required bool ignoreAllGestures,
    bool printDebugInfo = false,
  }) : ignoreAllGesturesNotifier = ValueNotifier(ignoreAllGestures);

  /// Returns true if the webview's current content is HTML
  bool get isCurrentContentHTML;

  /// Returns true if the webview's current content is URL
  bool get isCurrentContentURL;

  /// Returns true if the webview's current content is URL, and if
  /// [SourceType] is [SourceType.URL_BYPASS], which means it should
  /// use the bypass to fetch the web page content.
  bool get isCurrentContentURLBypass;

  /// Set webview content to the specified URL.
  /// Example URL: https://flutter.dev
  ///
  /// If [fromAssets] param is set to true,
  /// [url] param must be a String path to an asset
  /// Example: 'assets/some_url.txt'
  Future<void> loadContent(
    String content,
    SourceType sourceType, {
    Map<String, String> headers = const {},
    bool fromAssets = false,
  });

  /// Boolean getter which reveals if the gestures are ignored right now
  bool get ignoringAllGestures;

  /// Function to set ignoring gestures
  void setIgnoreAllGestures(bool value);

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
  );

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
  });

  /// WEB-ONLY. YOU SHOULDN'T NEED TO CALL THIS FROM YOUR CODE.
  ///
  /// This is called internally by the web.dart view class, to add a new
  /// iframe navigation history entry.
  ///
  /// This, and all history-related stuff is needed because the history on web
  /// is basically reimplemented by me from scratch using the [HistoryEntry] class.
  /// This had to be done because I couldn't intercept iframe's navigation events and
  /// current url.
  // void webAddHistory(HistoryEntry entry) => throw UnimplementedError();

  /// Returns the current content
  Future<WebViewContent> getContent();

  /// Returns a Future that completes with the value true, if you can go
  /// back in the history stack.
  Future<bool> canGoBack();

  /// Go back in the history stack.
  Future<void> goBack();

  /// Returns a Future that completes with the value true, if you can go
  /// forward in the history stack.
  Future<bool> canGoForward();

  /// Go forward in the history stack.
  Future<void> goForward();

  /// Reload the current content.
  Future<void> reload();

  /// Dispose resources
  void dispose();
}
