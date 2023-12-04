// ignore_for_file: avoid_classes_with_only_static_members, camel_case_types
/// This is here just to suppress the missing warning from "web.dart".
class platformViewRegistry {
  /// See https://github.com/flutter/flutter/issues/41563 for more info
  static void registerViewFactory(
    String viewId,
    dynamic Function(int viewId) callback,
  ) =>
      throw UnimplementedError();
}
