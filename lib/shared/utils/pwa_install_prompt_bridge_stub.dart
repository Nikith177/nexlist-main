class PwaInstallPromptBridge {
  const PwaInstallPromptBridge._();

  static const instance = PwaInstallPromptBridge._();

  bool get canShowBanner => false;

  void startListening(void Function() onChanged) {}

  void stopListening() {}

  Future<void> prompt() async {}

  void dismissBanner() {}
}
