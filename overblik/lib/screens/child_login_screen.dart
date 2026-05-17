import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
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
    if (!_formKey.currentState!.validate()) return;

    final l = AppLocalizations.of(context);

    setState(() => _isLoading = true);

    final familyCode = _familyCodeController.text.trim().toUpperCase();
    final childCode = _childCodeController.text.trim();

    try {
      final childSession = await _profileService.loginChildWithCode(
        familyCode: familyCode,
        childCode: childCode,
      );

      if (childSession == null) {
        throw Exception('WRONG_CODES');
      }

      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('NO_SESSION');
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DailyCalendarScreen()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.childLoginAuthError(e.message)),
          duration: const Duration(seconds: 5),
        ),
      );
    } on FunctionException catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.childLoginFailed),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e, st) {
      debugPrint('ChildLoginScreen _handleChildLogin failed: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      final raw = e.toString().replaceFirst('Exception: ', '');
      final message = raw == 'WRONG_CODES'
          ? l.wrongCodes
          : raw == 'NO_SESSION'
              ? l.noSessionCreated
              : raw;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

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
                    Text(
                      l.childLoginTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.childLoginSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                              labelText: l.familyCodeLabel,
                              hintText: l.familyCodeHint,
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return l.familyCodeRequired;
                              if (text.length < 4) return l.familyCodeTooShort;
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
                              labelText: l.childCodeLabel,
                              hintText: l.childCodeHint,
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return l.childCodeRequired;
                              if (text.length < 4) return l.childCodeTooShort;
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              if (!_isLoading) _handleChildLogin();
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
                              : Text(
                                  l.continueButton,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text(l.back),
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
            border: Border.all(color: const Color(0xFF8BCB99), width: 2),
          ),
          alignment: Alignment.center,
          child: const Text('🧒', style: TextStyle(fontSize: 36)),
        ),
      ],
    );
  }
}
