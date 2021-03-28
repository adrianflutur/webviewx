import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webviewx/src/controller/controller.dart';
import 'package:webviewx/src/utils/dart_callback.dart';
import 'package:webviewx/src/utils/embedded_js_content.dart';
import 'package:webviewx/src/utils/mobile_specific_params.dart';
import 'package:webviewx/src/utils/source_type.dart';
import 'package:webviewx/src/utils/web_specific_params.dart';

/// Facade widget
///
/// Trying to use this will throw UnimplementedError.
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
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError(
        'This is the unimplemented version of this widget. Please import "webviewx.dart" instead.');
  }
}
