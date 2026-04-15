import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'shared/widgets/pwa_install_banner_host.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('APP: initializing Firebase');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('APP: Firebase initialized');

  runApp(const NexlistApp());
}

class NexlistApp extends StatelessWidget {
  const NexlistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nexlist',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 800;
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1200 : double.infinity,
                  ),
                  child: PwaInstallBannerHost(child: child),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
