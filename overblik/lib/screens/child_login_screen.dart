import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/profile_service.dart';
import 'daily_calendar_screen.dart';

class ChildLoginScreen extends StatefulWidget {
  const ChildLoginScreen({super.key});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _familyCodeController = TextEditingController();
  final TextEditingController _childCodeController = TextEditingController();

  final ProfileService _profileService = ProfileService();

  bool _isLoading = false;

  @override
  void dispose() {
    _familyCodeController.dispose();
    _childCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleChildLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final familyCode = _familyCodeController.text.trim().toUpperCase();
    final childCode = _childCodeController.text.trim();

    try {
      debugPrint(
        'ChildLoginScreen: logging in through Edge Function '
        'familyCode=$familyCode childCode=$childCode',
      );

      final childSession = await _profileService.loginChildWithCode(
        familyCode: familyCode,
        childCode: childCode,
      );

      if (childSession == null) {
        throw Exception('Familiekoden eller børnekoden er forkert.');
      }

      final currentUser = Supabase.instance.client.auth.currentUser;

      debugPrint(
        'ChildLoginScreen: child login success '
        'authUserId=${currentUser?.id} '
        'familyId=${childSession.familyId} '
        'profileId=${childSession.profileId} '
        'displayName=${childSession.displayName} '
        'role=${childSession.role}',
      );

      if (currentUser == null) {
        throw Exception(
          'Børnelogin lykkedes, men der blev ikke oprettet en aktiv session.',
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DailyCalendarScreen(),
        ),
      );
    } on AuthException catch (e) {
      debugPrint('ChildLoginScreen AuthException message: ${e.message}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loginfejl: ${e.message}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } on FunctionException catch (e) {
      debugPrint('ChildLoginScreen FunctionException: ${e.details}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kunne ikke logge barnet ind. Prøv igen.'),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e, st) {
      debugPrint('ChildLoginScreen _handleChildLogin failed: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE0E0E0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE0E0E0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ChildHero(),
                    const SizedBox(height: 22),
                    const Text(
                      'Log ind som barn',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Indtast familiekode og børnekode',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _familyCodeController,
                            textCapitalization: TextCapitalization.characters,
                            textAlign: TextAlign.center,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              labelText: 'Familiekode',
                              hintText: 'Indtast familiekoden',
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';

                              if (text.isEmpty) {
                                return 'Skriv familiekoden';
                              }

                              if (text.length < 4) {
                                return 'Familiekoden er for kort';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _childCodeController,
                            textCapitalization: TextCapitalization.characters,
                            textAlign: TextAlign.center,
                            textInputAction: TextInputAction.done,
                            decoration: _inputDecoration(
                              labelText: 'Børnekode',
                              hintText: 'Indtast børnekoden',
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';

                              if (text.isEmpty) {
                                return 'Skriv børnekoden';
                              }

                              if (text.length < 4) {
                                return 'Børnekoden er for kort';
                              }

                              return null;
                            },
                            onFieldSubmitted: (_) {
                              if (!_isLoading) {
                                _handleChildLogin();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleChildLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Fortsæt',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Tilbage'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChildHero extends StatelessWidget {
  const _ChildHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: const Color(0xFFDDF4E3),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF8BCB99),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            '🧒',
            style: TextStyle(fontSize: 36),
          ),
        ),
      ],
    );
  }
}