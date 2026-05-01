import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/parent_join_service.dart';
import 'daily_calendar_screen.dart';
import 'login_screen.dart';
import 'parent_onboarding_choice_screen.dart';
import 'pending_parent_request_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final ParentJoinService _parentJoinService = ParentJoinService();

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
    } catch (e, st) {
      debugPrint('AuthGate: failed to resolve onboarding state: $e');
      debugPrintStack(stackTrace: st);

      await Supabase.instance.client.auth.signOut();

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