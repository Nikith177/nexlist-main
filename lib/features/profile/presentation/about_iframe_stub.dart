/// Stub for non-web platforms — iframe is not supported.

final _debugLoad = () { print('DEBUG: STUB iframe file loaded'); return true; }();

bool get isIframeAvailable => false;

void registerLandingIframe() {}
