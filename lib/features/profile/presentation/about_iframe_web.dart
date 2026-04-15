import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

final _debugLoad = () { print('DEBUG: WEB iframe file loaded'); return true; }();

bool get isIframeAvailable => true;

bool _registered = false;

void registerLandingIframe() {
  if (_registered) return;
  _registered = true;

  ui_web.platformViewRegistry.registerViewFactory(
    'landing-iframe',
    (int viewId) {
      final isLocalhost = html.window.location.hostname == 'localhost';
      final url = isLocalhost
          ? 'http://localhost:52578/?mode=about'
          : '/?mode=about';

      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    },
  );
}
