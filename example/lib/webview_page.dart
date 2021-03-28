import 'package:flutter/material.dart';
import 'package:webviewx/webviewx.dart';

import 'helpers.dart';

class WebViewXPage extends StatefulWidget {
  WebViewXPage({Key key}) : super(key: key);

  @override
  _WebViewXPageState createState() => _WebViewXPageState();
}

class _WebViewXPageState extends State<WebViewXPage> {
  WebViewXController webviewController;
  var initialContent =
      '<h4> This is some hardcoded HTML code embedded inside the webview <h4> <h2> Hello world! <h2>';
  var executeJsErrorMessage =
      'Failed to execute this task because the current content is (probably) URL that allows iframe embedding, on Web.\n\n'
      'A short reason for this is that, when a normal URL is embedded in the iframe, you do not actually own that content so you cant call your custom functions\n'
      '(read the documentation to find out why).';

  void _setUrl() {
    webviewController.loadContent(
      'https://flutter.dev',
      SourceType.URL,
    );
  }

  void _setUrlBypass() {
    webviewController.loadContent(
      'https://news.ycombinator.com/',
      SourceType.URL_BYPASS,
    );
  }

  void _setHtml() {
    webviewController.loadContent(
      initialContent,
      SourceType.HTML,
    );
  }

  void _setHtmlFromAssets() {
    webviewController.loadContent(
      'assets/test.html',
      SourceType.HTML,
      fromAssets: true,
    );
  }

  void _goForward() async {
    if (await webviewController.canGoForward()) {
      await webviewController.goForward();
      showSnackBar('Did go forward', context);
    } else {
      showSnackBar('Cannot go forward', context);
    }
  }

  void _goBack() async {
    if (await webviewController.canGoBack()) {
      await webviewController.goBack();
      showSnackBar('Did go back', context);
    } else {
      showSnackBar('Cannot go back', context);
    }
  }

  void _reload() {
    webviewController.reload();
  }

  void _toggleIgnore() {
    var ignoring = webviewController.ignoringAllGestures;
    webviewController.setIgnoreAllGestures(!ignoring);
    showSnackBar('Ignore events = ${!ignoring}', context);
  }

  void _evalRawJsInGlobalContext() async {
    try {
      var result = await webviewController.evalRawJavascript(
        '2+2',
        inGlobalContext: true,
      );
      showSnackBar('The result is $result', context);
    } catch (e) {
      showAlertDialog(
        executeJsErrorMessage,
        context,
      );
    }
  }

  void _callPlatformIndependentJsMethod() async {
    try {
      await webviewController.callJsMethod('testPlatformIndependentMethod', []);
    } catch (e) {
      showAlertDialog(
        executeJsErrorMessage,
        context,
      );
    }
  }

  void _callPlatformSpecificJsMethod() async {
    try {
      await webviewController
          .callJsMethod('testPlatformSpecificMethod', ['Hi']);
    } catch (e) {
      showAlertDialog(
        executeJsErrorMessage,
        context,
      );
    }
  }

  void _getWebviewContent() async {
    try {
      var content = await webviewController.getContent();
      showAlertDialog(content.source, context);
    } catch (e) {
      showAlertDialog('Failed to execute this task.', context);
    }
  }

  @override
  void dispose() {
    webviewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebViewX Page'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'Play around with the buttons to see how does it work',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 0.2),
                ),
                child: _buildWebViewX(),
              ),
              const SizedBox(height: 20.0),
              Expanded(
                child: Scrollbar(
                  isAlwaysShown: true,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildButtons(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebViewX() {
    return WebViewX(
      key: ValueKey('webviewx'),
      initialContent: initialContent,
      initialSourceType: SourceType.HTML,
      onWebViewCreated: (controller) => webviewController = controller,
      onPageStarted: (url) => print('A new page has started loading...\n'),
      onPageFinished: (url) => print('The page has finished loading.\n'),
      jsContent: {
        EmbeddedJsContent(
          js: "function testPlatformIndependentMethod() { console.log('Hi from JS') }",
        ),
        EmbeddedJsContent(
          webJs:
              "function testPlatformSpecificMethod(msg) { TestDartCallback('Web callback says: ' + msg) }",
          mobileJs:
              "function testPlatformSpecificMethod(msg) { TestDartCallback.postMessage('Mobile callback says: ' + msg) }",
        ),
      },
      dartCallBacks: {
        DartCallback(
          name: 'TestDartCallback',
          callBack: (msg) => showSnackBar(msg, context),
        )
      },
      height: 300.0,
      width: MediaQuery.of(context).size.width * 0.8,
    );
  }

  List<Widget> _buildButtons() {
    return [
      Wrap(
        spacing: 5.0,
        children: [
          createButton(onTap: _goBack, text: 'Back'),
          createButton(onTap: _goForward, text: 'Forward'),
          createButton(onTap: _reload, text: 'Reload'),
        ],
      ),
      createButton(
        text:
            'Change content to URL that allows iframes embedding (https://flutter.dev)',
        onTap: _setUrl,
      ),
      createButton(
        text:
            'Change content to URL that doesnt allow iframes embedding (https://news.ycombinator.com/)',
        onTap: _setUrlBypass,
      ),
      createButton(
        text: 'Change content to HTML (hardcoded)',
        onTap: _setHtml,
      ),
      createButton(
        text: 'Change content to HTML (from assets)',
        onTap: _setHtmlFromAssets,
      ),
      createButton(
        text: 'Toggle on/off ignore any events (click, scroll etc)',
        onTap: _toggleIgnore,
      ),
      createButton(
        text: 'Evaluate 2+2 in the global "window" (javascript side)',
        onTap: _evalRawJsInGlobalContext,
      ),
      createButton(
        text: 'Call platform independent Js method (console.log)',
        onTap: _callPlatformIndependentJsMethod,
      ),
      createButton(
        text:
            'Call platform specific Js method, that calls back a Dart function',
        onTap: _callPlatformSpecificJsMethod,
      ),
      createButton(
        text: 'Show current webview content',
        onTap: _getWebviewContent,
      ),
    ];
  }
}
