import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  Widget _buildLoadingScaffold(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Loading Nexlist...",
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("LIFECYCLE: resumed");
      FirebaseAuth.instance.currentUser?.reload();
    } else if (state == AppLifecycleState.paused) {
      print("LIFECYCLE: paused");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print("AUTH: connectionState = ${snapshot.connectionState}");
        print("AUTH: hasData = ${snapshot.hasData}");
        print("AUTH: user = ${snapshot.data?.uid}");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScaffold(context);
        }

        if (snapshot.data == null) {
          print("AUTH: rendering LOGIN");
          return const LoginScreen();
        }

        print("AUTH: authenticated user at AuthGate");
        return _buildLoadingScaffold(context);
      },
    );
  }
}
