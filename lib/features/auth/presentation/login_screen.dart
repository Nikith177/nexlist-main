import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';

import '../application/auth_user_bootstrap.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/utils/navigation_trace_utils.dart';
import '../../../shared/utils/phone_gate_utils.dart';

class LoginScreen extends StatefulWidget {
  final String? initialError;

  const LoginScreen({super.key, this.initialError});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  bool _didShowInitialError = false;
  bool _isSigningIn = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final initialError = widget.initialError;

    if (_didShowInitialError ||
        initialError == null ||
        initialError.trim().isEmpty) {
      return;
    }

    _didShowInitialError = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(initialError),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    });
  }

  Future<void> _startSignIn() async {
    if (_isSigningIn) return;

    // Guard: Prevent double login or loops
    if (FirebaseAuth.instance.currentUser != null) {
      print("LOGIN: user already logged in, redirecting to home");
      if (mounted) context.tracedGo('/home');
      return;
    }

    print("LOGIN: button clicked");
    setState(() {
      _isSigningIn = true;
    });

    try {
      UserCredential? userCredential;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        final userCredential = await FirebaseAuth.instance.signInWithPopup(
          provider,
        );
        if (userCredential.user != null) {
          await AuthUserBootstrap.ensureUserProfile(userCredential.user!);
          print("LOGIN: success, user = ${userCredential.user?.uid}");
          debugPrint('LOGIN SUCCESS: ${userCredential.user?.email}');
        }
        return;
      } /*else {
        final googleUser = await _googleSignIn!.signIn();

        if (googleUser == null) {
          throw Exception('Google sign-in cancelled');
        }

        final googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }*/

      if (!kIsWeb && userCredential != null) {
        final user = userCredential.user;
        if (user == null) {
          throw Exception('Authentication failed: user is null');
        }

        await AuthUserBootstrap.ensureUserProfile(user);
        if (!mounted) return;
        final identity = await PhoneGateUtils.ensureIdentity(context);

        if (!mounted || identity == null) return;
        print("LOGIN: success (not web), user = ${user?.uid}");
        context.tracedGo('/home');
      }
    } catch (e) {
      print("LOGIN: failed");
      print("LOGIN ERROR: $e");
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
      final errorMessage = AuthUserBootstrap.formatAuthError(e);
      await AuthUserBootstrap.signOutEverywhere(
        /*googleSignIn: _googleSignIn*/
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSigningIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceMuted = onSurface.withValues(alpha: 0.72);
    final logoAsset = isDark
        ? 'assets/branding/nexlist_logo_dark.png'
        : 'assets/branding/nexlist_logo.png';

    final backgroundColor = isDark
        ? const Color(0xFF0B1220)
        : const Color(0xFFF8FAFC);
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : const Color(0xFFFFFFFF);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              width: double.infinity,
              padding: const EdgeInsets.all(28.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(logoAsset, height: 36),
                  const SizedBox(height: 14),
                  Text(
                    'Enter your campus marketplace',
                    style: AppTypography.h3.copyWith(
                      color: onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sign in with your student ID to access your campus marketplace',
                    style: AppTypography.bodyMedium.copyWith(
                      color: onSurfaceMuted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSigningIn ? null : _startSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSigningIn
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue with Student ID',
                                  style: AppTypography.buttonText.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_user,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Only verified students allowed',
                        style: AppTypography.bodySmall.copyWith(
                          color: onSurface.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
