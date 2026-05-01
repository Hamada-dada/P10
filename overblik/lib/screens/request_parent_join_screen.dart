import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/parent_join_service.dart';
import 'pending_parent_request_screen.dart';

class RequestParentJoinScreen extends StatefulWidget {
  const RequestParentJoinScreen({super.key});

  @override
  State<RequestParentJoinScreen> createState() =>
      _RequestParentJoinScreenState();
}

class _RequestParentJoinScreenState extends State<RequestParentJoinScreen> {
  final _formKey = GlobalKey<FormState>();

  final ParentJoinService _parentJoinService = ParentJoinService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _familyCodeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;

  bool get _hasAuthUser {
    return Supabase.instance.client.auth.currentUser != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _familyCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> _ensureParentAuthIfNeeded() async {
    if (_hasAuthUser) {
      return;
    }

    final response = await Supabase.instance.client.auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    final user = response.user ?? Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Kontoen blev oprettet, men du skal muligvis bekræfte din email og logge ind, før anmodningen kan sendes.',
      );
    }
  }

  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _ensureParentAuthIfNeeded();

      final result = await _parentJoinService.requestParentJoin(
        familyCode: _familyCodeController.text.trim(),
        name: _nameController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PendingParentRequestScreen(
            requestId: result.requestId,
            familyName: result.familyName,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          duration: const Duration(seconds: 6),
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
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
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

  void _goBack() {
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hasAuthUser = _hasAuthUser;

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
                      const SizedBox(height: 26),
                      const Text(
                        'Anmod om adgang',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Send en anmodning til en eksisterende familie',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          hintText: 'Forælders navn',
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';

                          if (text.isEmpty) {
                            return 'Skriv forælders navn';
                          }

                          if (text.length < 2) {
                            return 'Navnet er for kort';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _familyCodeController,
                        textCapitalization: TextCapitalization.characters,
                        textAlign: TextAlign.start,
                        textInputAction: hasAuthUser
                            ? TextInputAction.done
                            : TextInputAction.next,
                        decoration: _inputDecoration(
                          hintText: 'Familiekode',
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
                        onFieldSubmitted: (_) {
                          if (hasAuthUser && !_isLoading) {
                            _sendRequest();
                          }
                        },
                      ),
                      if (!hasAuthUser) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            hintText: 'Email',
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';

                            if (text.isEmpty) {
                              return 'Skriv din email';
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
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            hintText: 'Adgangskode',
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
                              return 'Skriv en adgangskode';
                            }

                            if (text.length < 6) {
                              return 'Mindst 6 tegn';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _repeatPasswordController,
                          obscureText: _obscureRepeatPassword,
                          textInputAction: TextInputAction.done,
                          decoration: _inputDecoration(
                            hintText: 'Gentag adgangskode',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureRepeatPassword =
                                      !_obscureRepeatPassword;
                                });
                              },
                              icon: Icon(
                                _obscureRepeatPassword
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
                              return 'Adgangskoderne er ikke ens';
                            }

                            return null;
                          },
                          onFieldSubmitted: (_) {
                            if (!_isLoading) {
                              _sendRequest();
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
                                    'Send anmodning',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _isLoading ? null : _goBack,
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
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _HeroBubble(
          emoji: '👩',
          size: 64,
        ),
        SizedBox(width: 12),
        _HeroBubble(
          emoji: '🧒',
          size: 76,
          highlighted: true,
        ),
        SizedBox(width: 12),
        _HeroBubble(
          emoji: '👨',
          size: 64,
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
        color: highlighted ? const Color(0xFFDDF4E3) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: highlighted
              ? const Color(0xFF8BCB99)
              : const Color(0xFFE5E5E5),
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