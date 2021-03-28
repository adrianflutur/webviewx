import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
// import 'package:pointer_interceptor/src/web.dart';

class WebViewAware extends StatelessWidget {
  final Widget child;
  final bool debug;

  WebViewAware({
    Key key,
    @required this.child,
    this.debug = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      key: key,
      debug: debug,
      child: child,
    );
  }
}
