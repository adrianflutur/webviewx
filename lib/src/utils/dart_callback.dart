import 'package:meta/meta.dart';

/// Registers a Dart callback, which can be called from the Javascript side.
/// This will be turned into a platform-specific dart callback, on runtime.
///
/// Usage:
///
/// ```dart
/// WebViewX(
///   ...
///   dartCallbacks: {
///     DartCallback(
///       name: 'Unique_Name_Here',
///       callBack: (message) => print(message),
///     ),
///   },
///   ...
/// ),
/// ```
///
/// And then, from the Javascript side, when some action happens:
/// (for more about the Web and Mobile different call types see [EmbeddedJsContent])
///
/// ```javascript
/// ...
/// From Web:
///
/// Unique_Name_Here('test');
///
/// From Mobile:
///
/// Unique_Name_Here.postMessage('test');
/// ...
/// ```
class DartCallback {
  /// Callback's name
  ///
  /// Note: Must be UNIQUE
  final String name;

  /// Callback function
  final Function(dynamic message) callBack;

  /// Constructor
  const DartCallback({
    @required this.name,
    this.callBack,
  }) : assert(
          name != null,
          'Javascript callback channel name must not be null.',
        );

  @override
  bool operator ==(Object other) => other is DartCallback && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
