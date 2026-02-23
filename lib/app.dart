import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/home/home_screen.dart';
import 'features/add_property/add_property_screen.dart';
import 'features/property_detail/property_detail_screen.dart';
import 'features/inquiries/property_inquiries_screen.dart';
import 'models/property.dart';
import 'providers/property_provider.dart';

// Notifier that rebuilds the router when auth state changes
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}

final _authNotifier = _AuthChangeNotifier();

final _router = GoRouter(
  initialLocation: '/',
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    final user = Supabase.instance.client.auth.currentUser;
    final isAuthPage = [
      '/',
      '/login',
      '/signup',
    ].contains(state.matchedLocation);

    // If logged in and on auth pages → go home
    if (user != null && isAuthPage) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(
        path: '/add-property', builder: (_, __) => const AddPropertyScreen()),
    GoRoute(
      path: '/property-detail',
      builder: (context, state) {
        final property = state.extra as Property;
        return PropertyDetailScreen(property: property);
      },
    ),
    GoRoute(
      path: '/property-inquiries',
      builder: (context, state) {
        final property = state.extra as Property;
        return PropertyInquiriesScreen(property: property);
      },
    ),
  ],
);

class PropVistaApp extends ConsumerStatefulWidget {
  const PropVistaApp({super.key});

  @override
  ConsumerState<PropVistaApp> createState() => _PropVistaAppState();
}

class _PropVistaAppState extends ConsumerState<PropVistaApp> {
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    // Invalidate all user-scoped providers whenever the signed-in user changes.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userUpdated) {
        ref.invalidate(myListingsProvider);
        ref.invalidate(savedPropertiesProvider);
        ref.invalidate(savedIdsProvider);
        ref.invalidate(homeFeedProvider);
        ref.invalidate(featuredProvider);
        ref.invalidate(propertyInquiriesProvider);
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PropVista',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
