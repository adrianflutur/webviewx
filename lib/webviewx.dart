library webviewx;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'src/view/view.dart';
import 'src/controller/controller.dart';
import 'src/utils/utils.dart';

export 'src/controller/controller.dart';
export 'src/utils/utils.dart';

/// Top-level wrapper for WebViewX.
/// Basically it's a layout builder that makes sure the webview can still render
/// even if you don't provide a width and/or a height.
class WebViewX extends StatelessWidget {
  final String initialContent;

  final SourceType initialSourceType;

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
  final void Function(String? src)? onPageStarted;

  /// Callback for when the page has finished loading (i.e. is shown on screen).
  final void Function(String? src)? onPageFinished;

  /// Callback for when something goes wrong in while page or resources load.
  final void Function(WebResourceError error)? onWebResourceError;

  /// Parameters specific to the web version.
  /// This may eventually be merged with [mobileSpecificParams],
  /// if all features become cross platform.
  final WebSpecificParams webSpecificParams;

  /// Parameters specific to the web version.
  /// This may eventually be merged with [webSpecificParams],
  /// if all features become cross platform.
  final MobileSpecificParams mobileSpecificParams;

  /// Constructor
  WebViewX({
    Key? key,
    this.initialContent = 'about:blank',
    this.initialSourceType = SourceType.URL,
    this.userAgent,
    this.width,
    this.height,
    this.onWebViewCreated,
    this.jsContent = const {},
    this.dartCallBacks = const {},
    this.ignoreAllGestures = false,
    this.javascriptMode = JavascriptMode.unrestricted,
    this.initialMediaPlaybackPolicy =
        AutoMediaPlaybackPolicy.require_user_action_for_all_media_types,
    this.onPageStarted,
    this.onPageFinished,
    this.onWebResourceError,
    this.webSpecificParams = const WebSpecificParams(),
    this.mobileSpecificParams = const MobileSpecificParams(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => WebViewXWidget(
        key: key,
        initialContent: initialContent,
        initialSourceType: initialSourceType,
        userAgent: userAgent,
        width: width ?? constraints.maxWidth,
        height: height ?? constraints.maxHeight,
        dartCallBacks: dartCallBacks,
        jsContent: jsContent,
        onWebViewCreated: onWebViewCreated,
        ignoreAllGestures: ignoreAllGestures,
        javascriptMode: javascriptMode,
        initialMediaPlaybackPolicy: initialMediaPlaybackPolicy,
        onPageStarted: onPageStarted,
        onPageFinished: onPageFinished,
        onWebResourceError: onWebResourceError,
        webSpecificParams: webSpecificParams,
        mobileSpecificParams: mobileSpecificParams,
      ),
    );
  }
}
