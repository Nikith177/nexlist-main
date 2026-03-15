import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/listing_feed/home_feed_screen.dart';

void main() {
  runApp(const NexlistApp());
}

class NexlistApp extends StatelessWidget {
  const NexlistApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexlist MVP Scaffold',
      theme: AppTheme.lightTheme,
      home: const InitialNavigationWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InitialNavigationWrapper extends StatefulWidget {
  const InitialNavigationWrapper({Key? key}) : super(key: key);

  @override
  State<InitialNavigationWrapper> createState() => _InitialNavigationWrapperState();
}

class _InitialNavigationWrapperState extends State<InitialNavigationWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AuthScreen(),
    const HomeFeedScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Auth Screen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home Feed',
          ),
        ],
      ),
    );
  }
}
