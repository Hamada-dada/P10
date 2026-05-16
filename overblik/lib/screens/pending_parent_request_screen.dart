import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart' show themeController;
import '../services/parent_join_service.dart';
import 'daily_calendar_screen.dart';
import 'login_screen.dart';
import 'parent_onboarding_choice_screen.dart';

class PendingParentRequestScreen extends StatefulWidget {
  final String? requestId;
  final String? familyName;

  const PendingParentRequestScreen({
    super.key,
    this.requestId,
    this.familyName,
  });

  @override
  State<PendingParentRequestScreen> createState() =>
      _PendingParentRequestScreenState();
}

class _PendingParentRequestScreenState
    extends State<PendingParentRequestScreen> {
  final ParentJoinService _parentJoinService = ParentJoinService();

  bool _isLoading = false;
  bool _isCancelling = false;

  String? _requestId;
  String? _familyName;

  @override
  void initState() {
    super.initState();

    _requestId = widget.requestId;
    _familyName = widget.familyName;

    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final state = await _parentJoinService.getParentOnboardingState();

      if (!mounted) return;

      switch (state.state) {
        case ParentOnboardingStateType.activeParent:
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const DailyCalendarScreen(),
            ),
            (route) => false,
          );
          return;

        case ParentOnboardingStateType.pendingParentRequest:
          setState(() {
            _requestId = state.requestId;
            _familyName = state.familyName;
            _isLoading = false;
          });
          return;

        case ParentOnboardingStateType.needsOnboarding:
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const ParentOnboardingChoiceScreen(),
            ),
            (route) => false,
          );
          return;
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke opdatere status: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _cancelRequest() async {
    final requestId = _requestId;

    if (requestId == null || requestId.trim().isEmpty) {
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Annuller anmodning'),
          content: const Text(
            'Er du sikker på, at du vil annullere din anmodning?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Nej'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ja, annuller'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      await _parentJoinService.cancelMyJoinRequest(requestId);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const ParentOnboardingChoiceScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCancelling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke annullere anmodning: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      await themeController.setThemeMode(ThemeMode.light);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke logge ud: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyName = _familyName?.trim().isNotEmpty == true
        ? _familyName!
        : 'familien';

    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              width: 420,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.hourglass_top,
                    size: 54,
                    color: Colors.black87,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Afventer godkendelse',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Italiana',
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Din anmodning om adgang til $familyName er sendt. En eksisterende forælder skal godkende dig, før du får adgang.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading || _isCancelling
                          ? null
                          : _refreshStatus,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Opdater status'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isLoading || _isCancelling
                        ? null
                        : _cancelRequest,
                    icon: _isCancelling
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.close),
                    label: const Text('Annuller anmodning'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading || _isCancelling ? null : _logout,
                    child: const Text('Tilbage'),
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