import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

import 'webview_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebViewX Example App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Default example not shows webview until resize the window
      home: WebViewXPage(),
      // webview_windows sample works without resize
      //home: WebViewXPageWorkingSample(),
    );
  }
}


class WebViewXPageWorkingSample extends StatefulWidget {
  @override
  _WebViewXPageWorkingSample createState() => _WebViewXPageWorkingSample();
}

class _WebViewXPageWorkingSample extends State<WebViewXPageWorkingSample> {
  late WebviewController _controller;

  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    initPlatformState();
  }

  Future<void> initPlatformState() async {
    _controller = WebviewController();

    await _controller.initialize();
    _controller.url.listen((url) {
      textController.text = url;
    });
    await _controller.loadUrl('https://flutter.dev');

    if (!mounted) return;

    setState(() {});
  }

  Widget compositeView() {
    if (!_controller.value.isInitialized) {
      return const Text(
        'Not Initialized',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: TextField(
                decoration: InputDecoration(
                    hintText: 'URL',
                    contentPadding: EdgeInsets.all(10.0),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () {
                        _controller.reload();
                      },
                    )),
                textAlignVertical: TextAlignVertical.center,
                controller: textController,
                onSubmitted: (val) {
                  _controller.loadUrl(val);
                },
              ),
            ),
            Expanded(
                child: Card(
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Stack(
                      children: [
                        Webview(_controller),
                        StreamBuilder<LoadingState>(
                            stream: _controller.loadingState,
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data == LoadingState.Loading) {
                                return LinearProgressIndicator();
                              } else {
                                return Container();
                              }
                            }),
                      ],
                    ))),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            title: StreamBuilder<String>(
              stream: _controller.title,
              builder: (context, snapshot) {
                return Text(snapshot.hasData
                    ? snapshot.data!
                    : 'WebView (Windows) Example');
              },
            )),
        body: Center(
          child: compositeView(),
        ),
      ),
    );
  }
}