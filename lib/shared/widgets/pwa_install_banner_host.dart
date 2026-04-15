import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../utils/pwa_install_prompt_bridge.dart';

class PwaInstallBannerHost extends StatefulWidget {
  final Widget child;

  const PwaInstallBannerHost({super.key, required this.child});

  @override
  State<PwaInstallBannerHost> createState() => _PwaInstallBannerHostState();
}

class _PwaInstallBannerHostState extends State<PwaInstallBannerHost> {
  final _bridge = PwaInstallPromptBridge.instance;
  bool _showBanner = false;
  bool _isPrompting = false;

  @override
  void initState() {
    super.initState();
    _bridge.startListening(_syncBannerState);
    _showBanner = _bridge.canShowBanner;
  }

  @override
  void dispose() {
    _bridge.stopListening();
    super.dispose();
  }

  Future<void> _install() async {
    if (_isPrompting) {
      return;
    }

    setState(() {
      _isPrompting = true;
    });

    await _bridge.prompt();

    if (!mounted) {
      return;
    }

    setState(() {
      _isPrompting = false;
      _showBanner = _bridge.canShowBanner;
    });
  }

  void _dismiss() {
    _bridge.dismissBanner();
    setState(() {
      _showBanner = false;
    });
  }

  void _syncBannerState() {
    if (!mounted) {
      return;
    }

    setState(() {
      _showBanner = _bridge.canShowBanner;
      if (!_showBanner) {
        _isPrompting = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        if (_showBanner)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: Material(
                color: AppColors.surface,
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/branding/nexlist_icon.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Install Nexlist for faster access ⚡',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall,
                        ),
                      ),
                      TextButton(
                        onPressed: _isPrompting ? null : _install,
                        child: Text(_isPrompting ? '...' : 'Install'),
                      ),
                      IconButton(
                        onPressed: _dismiss,
                        splashRadius: 18,
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
