import 'package:webviewx/src/utils/css_loader.dart';
import 'package:webviewx/src/utils/source_type.dart';
import 'package:webviewx/src/utils/utils.dart';

/// Parameters specific to the web version.
///
/// This may merge with [MobileSpecificParams] in the future.
class WebSpecificParams {
  /// Proxies are used to bypass a website's iframe embedding restrictions
  final List<BypassProxy> proxyList;

  /// Set this to true if you want to see in the console information about the current actions.
  /// It will print things such as current histroy stack every time you
  /// navigate, what iframes have started or finished loading etc.
  final bool printDebugInfo;

  /// Controls video behaviour. If true, videos will have the fullscreen button active.
  final bool webAllowFullscreenContent;

  /// Iframe sandboxing options. You shouldn't modify theese unless something doesn't work
  final List<String> additionalSandboxOptions;

  /// IFrame "allow" options. You shouldn't modify theese unless something doesn't work
  final List<String> additionalAllowOptions;

  /// The loading indicator that shows up when the iframe content is loading (only when using [SourceType.URL_BYPASS])
  final CssLoader cssLoadingIndicator;

  /// Constructor
  const WebSpecificParams({
    this.proxyList = BypassProxy.publicProxies,
    this.printDebugInfo = false,
    this.webAllowFullscreenContent = true,
    this.additionalSandboxOptions = const [
      'allow-downloads',
      'allow-forms',
      'allow-modals',
      'allow-orientation-lock',
      'allow-pointer-lock',
      'allow-popups',
      'allow-popups-to-escape-sandbox',
      'allow-presentation',
      'allow-same-origin',
      // 'allow-top-navigation',
      // 'allow-top-navigation-by-user-activation',
    ],
    this.additionalAllowOptions = const [
      'accelerometer',
      'clipboard-write',
      'encrypted-media',
      'gyroscope',
      'picture-in-picture',
    ],
    this.cssLoadingIndicator = const CssLoader(),
  });
}
