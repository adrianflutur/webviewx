/// A copy of the original NavigationRequest from webview_flutter.
///
/// This was needed because I couldn't extract the information I needed from inside the webview package.
class NavigationRequest {
  /// Constructor
  NavigationRequest({this.content, this.isForMainFrame});

  /// The URL that will be loaded if the navigation is executed.
  final String content;

  /// Whether the navigation request is to be loaded as the main frame.
  final bool isForMainFrame;

  @override
  String toString() {
    return '$runtimeType(content: $content, isForMainFrame: $isForMainFrame)';
  }
}
