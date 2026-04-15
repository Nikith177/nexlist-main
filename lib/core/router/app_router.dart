import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexlist_mobile/core/state/app_state.dart';
import 'package:nexlist_mobile/shared/utils/navigation_trace_utils.dart';

import '../../features/auth/presentation/auth_gate.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/services/presentation/services_screen.dart';
import '../../features/listing/presentation/listing_detail_screen.dart';
import '../../features/post_listing/presentation/post_listing_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/my_listings_screen.dart';
import '../../features/profile/presentation/my_requests_screen.dart';
import '../../features/profile/presentation/my_services_screen.dart';
import '../../features/profile/presentation/about_screen.dart';
import '../../features/profile/presentation/support_form_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/saved/presentation/saved_screen.dart';
import '../../features/requests/presentation/requests_screen.dart';
import '../../shared/widgets/custom_bottom_nav_bar.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'homeTab');
final shellNavigatorServicesKey = GlobalKey<NavigatorState>(
  debugLabel: 'servicesTab',
);
final shellNavigatorRequestsKey = GlobalKey<NavigatorState>(
  debugLabel: 'requestsTab',
);
final shellNavigatorProfileKey = GlobalKey<NavigatorState>(
  debugLabel: 'profileTab',
);

String _resolveInitialLocation() {
  listingLaunchedFromDeepLink = false;
  final segments = Uri.base.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList();

  if (segments.length >= 2 && segments[0] == 'listing') {
    final listingId = Uri.decodeComponent(segments[1]).trim();
    if (listingId.isNotEmpty) {
      listingLaunchedFromDeepLink = true;
      return '/listing/${Uri.encodeComponent(listingId)}';
    }
  }

  return '/';
}

final goRouter = GoRouter(
  initialLocation: _resolveInitialLocation(),
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.idTokenChanges(),
  ),
  navigatorKey: rootNavigatorKey,
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final location = state.matchedLocation;
    final isLoginRoute = location == '/login';
    final isAuthGateRoute = location == '/';
    print(
      "NAVIGATION: redirect check location=$location, user=${user?.uid}, isLoggedIn=$isLoggedIn",
    );

    if (!isLoggedIn) {
      if (isAuthGateRoute || isLoginRoute) {
        print("NAVIGATION: staying at $location");
        return null;
      }
      print("NAVIGATION: going to LOGIN (redirect)");
      print("NAVIGATION: redirect -> /login");
      return '/login';
    }

    if (isAuthGateRoute || isLoginRoute) {
      print("NAVIGATION: going to HOME (redirect)");
      print("NAVIGATION: redirect -> /home");
      return '/home';
    }

    print("NAVIGATION: staying at $location");
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),
    GoRoute(
      path: '/login',
      builder: (context, state) =>
          LoginScreen(initialError: state.uri.queryParameters['error']),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(
          body: navigationShell,
          currentIndex: navigationShell.currentIndex,
          onNavTap: (index) {
            tracedGoBranch(
              navigationShell,
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          onPostTap: () {
            context.tracedPush('/post');
          },
        );
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: shellNavigatorHomeKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: shellNavigatorServicesKey,
          routes: [
            GoRoute(
              path: '/services',
              builder: (context, state) => const ServicesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: shellNavigatorRequestsKey,
          routes: [
            GoRoute(
              path: '/requests',
              builder: (context, state) => const RequestsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: shellNavigatorProfileKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/post',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          PostListingScreen(initialType: state.uri.queryParameters['type']),
    ),
    GoRoute(
      path: '/listing/:id',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ListingDetailScreen(listingId: id),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        );
      },
    ),

    GoRoute(
      path: '/saved',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final initialData =
            extra?['initialData'] as List<Map<String, dynamic>>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: SavedScreen(initialSavedItems: initialData),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/my-listings',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final initialData =
            extra?['initialData'] as List<Map<String, dynamic>>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: MyListingsScreen(initialListings: initialData),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/my-requests',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const MyRequestsScreen(),
    ),
    GoRoute(
      path: '/my-services',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const MyServicesScreen(),
    ),
    GoRoute(
      path: '/support-form',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final type = state.uri.queryParameters['type'] ?? 'help';
        return SupportFormScreen(type: type);
      },
    ),
    GoRoute(
      path: '/edit-profile',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/about',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AboutScreen(),
    ),
  ],
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
