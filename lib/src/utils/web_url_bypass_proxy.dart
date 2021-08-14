abstract class BypassProxy {
  String buildProxyUrl(String pageUrl);
  String extractPageSource(String responseBody);

  static const publicProxies = <BypassProxy>[
    BridgedBypassProxy(),
    CodeTabsBypassProxy(),
  ];
}

class BridgedBypassProxy implements BypassProxy {
  const BridgedBypassProxy();

  @override
  String buildProxyUrl(String pageUrl) {
    return 'https://cors.bridged.cc/$pageUrl';
  }

  @override
  String extractPageSource(String responseBody) {
    return responseBody;
  }
}

class CodeTabsBypassProxy implements BypassProxy {
  const CodeTabsBypassProxy();

  @override
  String buildProxyUrl(String pageUrl) {
    return 'https://api.codetabs.com/v1/proxy/?quest=$pageUrl';
  }

  @override
  String extractPageSource(String responseBody) {
    return responseBody;
  }
}

/* 
Example for when the proxy's response is not the page source directly,
but it's a JSON object.

Such as this: {"response": "<html><head>......."}



class ExampleExtractPageSourceBypassProxy implements BypassProxy {
  @override
  String buildRequestUrl(String pageUrl) {
    return 'https://example-extract-page-source/$pageUrl';
  }

  @override
  String extractPageSource(String responseBody) {
    final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
    return jsonResponse['response'] as String;
  }
}
*/
