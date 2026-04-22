import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'daily_calendar_screen.dart';

class CreateFamilyScreen extends StatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  State<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _parentNameController.dispose();
    _familyNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _generateFamilyCode({int length = 6}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _generateProfileId() {
    final milliseconds = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999).toString().padLeft(5, '0');
    return 'profile-$milliseconds-$random';
  }

  Future<String> _generateUniqueFamilyCode(SupabaseClient client) async {
    for (int i = 0; i < 20; i++) {
      final code = _generateFamilyCode();

      final existing = await client
          .from('families')
          .select('id')
          .eq('family_code', code)
          .limit(1);

      if ((existing as List).isEmpty) {
        return code;
      }
    }

    throw Exception('Could not generate a unique family code.');
  }

  Future<void> _handleCreateFamily() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final client = Supabase.instance.client;

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final parentName = _parentNameController.text.trim();
      final familyName = _familyNameController.text.trim();

      final authResponse = await client.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('User creation failed.');
      }

      final familyCode = await _generateUniqueFamilyCode(client);

      final familyInsertResponse = await client
          .from('families')
          .insert({
            'family_name': familyName,
            'family_code': familyCode,
            'created_by': user.id,
          })
          .select('id')
          .single();

      final familyId = familyInsertResponse['id'] as String;

      await client.from('profiles').insert({
        'id': _generateProfileId(),
        'name': parentName,
        'display_name': parentName,
        'emoji': '🙂',
        'role': 'parent',
        'auth_user_id': user.id,
        'family_id': familyId,
      });

      if (!mounted) return;

      final hasSession = client.auth.currentSession != null;

      if (hasSession) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const DailyCalendarScreen(),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Familien er oprettet. Familiekode: $familyCode. '
              'Tjek din email, hvis bekræftelse er slået til.',
            ),
            duration: const Duration(seconds: 6),
          ),
        );

        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create family: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
    }
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _FamilyHero(),
                      const SizedBox(height: 22),
                      const Text(
                        'Opret familie',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Start med den første forælder',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _parentNameController,
                        decoration: InputDecoration(
                          labelText: 'Forælders navn',
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
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'Skriv navn';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _familyNameController,
                        decoration: InputDecoration(
                          labelText: 'Familienavn',
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
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'Skriv familienavn';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
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
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'Skriv email';
                          }
                          if (!text.contains('@')) {
                            return 'Skriv en gyldig email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Adgangskode',
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
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final text = value ?? '';
                          if (text.isEmpty) {
                            return 'Skriv adgangskode';
                          }
                          if (text.length < 6) {
                            return 'Mindst 6 tegn';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Gentag adgangskode',
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
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final text = value ?? '';
                          if (text.isEmpty) {
                            return 'Gentag adgangskoden';
                          }
                          if (text != _passwordController.text) {
                            return 'Adgangskoderne matcher ikke';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleCreateFamily,
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
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Opret familie',
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
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tilbage'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyHero extends StatelessWidget {
  const _FamilyHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _HeroBubble(
              emoji: '👩',
              size: 62,
            ),
            SizedBox(width: 10),
            _HeroBubble(
              emoji: '🧒',
              size: 72,
              highlighted: true,
            ),
            SizedBox(width: 10),
            _HeroBubble(
              emoji: '👨',
              size: 62,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroBubble extends StatelessWidget {
  final String emoji;
  final double size;
  final bool highlighted;

  const _HeroBubble({
    required this.emoji,
    required this.size,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFFDDF4E3)
            : const Color(0xFFF7F7F7),
        shape: BoxShape.circle,
        border: Border.all(
          color: highlighted
              ? const Color(0xFF8BCB99)
              : const Color(0xFFE0E0E0),
          width: highlighted ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(
          fontSize: highlighted ? 34 : 28,
        ),
      ),
    );
  }
}