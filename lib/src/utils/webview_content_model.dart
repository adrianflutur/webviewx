import 'package:webviewx/src/utils/source_type.dart';

/// Model class for webview's content
///
/// This is the result of calling [await webViewXController.getContent()]
class WebViewContent {
  /// The current source
  final String source;

  /// The current source type
  final SourceType sourceType;

  /// Constructor
  WebViewContent({
    required this.source,
    required this.sourceType,
  });

  @override
  String toString() {
    return 'Source type: ${sourceType.toString()}\n'
        'Content: $source\n';
  }
}
