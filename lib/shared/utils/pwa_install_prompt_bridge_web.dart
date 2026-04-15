import 'dart:html' as html;

import 'package:flutter/foundation.dart';

class PwaInstallPromptBridge {
  PwaInstallPromptBridge._();

  static final instance = PwaInstallPromptBridge._();
  static const _storageKey = 'nexlist_install_banner_seen';

  Object? _deferredPrompt;
  bool _showBannerForCurrentSession = false;
  bool _isListening = false;
  html.EventListener? _listener;
  VoidCallback? _onChanged;

  bool get _wasShownThisSession =>
      html.window.sessionStorage[_storageKey] == '1';

  bool get canShowBanner =>
      _showBannerForCurrentSession && _deferredPrompt != null;

  void startListening(void Function() onChanged) {
    _onChanged = onChanged;
    if (_isListening) {
      _notify();
      return;
    }

    _listener = (event) {
      event.preventDefault();
      _deferredPrompt = event;
      if (!_wasShownThisSession) {
        html.window.sessionStorage[_storageKey] = '1';
        _showBannerForCurrentSession = true;
      }
      _notify();
    };

    html.window.addEventListener('beforeinstallprompt', _listener);
    _isListening = true;
    _notify();
  }

  void stopListening() {
    _onChanged = null;
  }

  Future<void> prompt() async {
    final dynamic promptEvent = _deferredPrompt;
    if (promptEvent == null) {
      return;
    }

    _showBannerForCurrentSession = false;
    await promptEvent.prompt();
    await promptEvent.userChoice;

    _deferredPrompt = null;
    _notify();
  }

  void dismissBanner() {
    _showBannerForCurrentSession = false;
    _notify();
  }

  void _notify() {
    _onChanged?.call();
  }
}
