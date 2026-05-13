import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/parent_join_service.dart';
import '../services/profile_service.dart';
import 'daily_calendar_screen.dart';
import 'login_screen.dart';
import 'parent_onboarding_choice_screen.dart';
import 'pending_parent_request_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

bool _isNetworkError(Object error) {
  if (error is SocketException) return true;
  final text = error.toString().toLowerCase();
  return text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('no address associated with hostname') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('connection failed');
}

class _AuthGateState extends State<AuthGate> {
  final ParentJoinService _parentJoinService = ParentJoinService();
  final ProfileService _profileService = ProfileService();

  late final Future<Widget> _initialScreenFuture;

  @override
  void initState() {
    super.initState();
    _initialScreenFuture = _resolveInitialScreen();
  }

  Future<Widget> _resolveInitialScreen() async {
    final session = Supabase.instance.client.auth.currentSession;

    debugPrint(
      'AuthGate: current session user id = ${session?.user.id}',
    );

    if (session == null) {
      return const LoginScreen();
    }

    try {
      final profile = await _profileService.getCurrentAuthenticatedProfile();

      if (profile == null) {
        debugPrint('AuthGate: authenticated user has no active profile');
        await Supabase.instance.client.auth.signOut();
        return const LoginScreen();
      }

      debugPrint(
        'AuthGate: active profile id=${profile.id} role=${profile.role}',
      );

      if (profile.isChild) {
        debugPrint('AuthGate: routing authenticated child to calendar');
        return const DailyCalendarScreen();
      }

      if (profile.isParent) {
        final state = await _parentJoinService.getParentOnboardingState();

        debugPrint('AuthGate: onboarding state = ${state.state}');

        switch (state.state) {
          case ParentOnboardingStateType.activeParent:
            return const DailyCalendarScreen();

          case ParentOnboardingStateType.pendingParentRequest:
            return PendingParentRequestScreen(
              requestId: state.requestId,
              familyName: state.familyName,
            );

          case ParentOnboardingStateType.needsOnboarding:
            return const ParentOnboardingChoiceScreen();
        }
      }

      debugPrint('AuthGate: unsupported profile role, signing out');
      await Supabase.instance.client.auth.signOut();
      return const LoginScreen();
    } catch (e, st) {
      debugPrint('AuthGate: failed to resolve authenticated state: $e');
      debugPrintStack(stackTrace: st);

      // Only sign out on real auth/permission errors.
      // A network failure at cold start must not destroy a valid session.
      if (!_isNetworkError(e)) {
        await Supabase.instance.client.auth.signOut();
      }

      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _AuthLoadingScreen();
        }

        if (snapshot.hasError) {
          return const LoginScreen();
        }

        return snapshot.data ?? const LoginScreen();
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFA2E5AD),
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}