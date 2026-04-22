import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'child_login_screen.dart';
import 'create_family_screen.dart';
import 'daily_calendar_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _parentFormKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isParentLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleParentLogin() async {
    if (!_parentFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isParentLoading = true;
    });

    try {
      final client = Supabase.instance.client;

      await client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DailyCalendarScreen(),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Noget gik galt under login.'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isParentLoading = false;
      });
    }
  }

  void _openChildLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChildLoginScreen(),
      ),
    );
  }

  void _openCreateFamily() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateFamilyScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              const _BrandHeader(),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _FamilyHero(),
                        const SizedBox(height: 22),
                        const Text(
                          'Log ind som forælder',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Fortsæt til familiens kalender',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Form(
                          key: _parentFormKey,
                          child: Column(
                            children: [
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
                                    return 'Skriv din adgangskode';
                                  }
                                  if (text.length < 6) {
                                    return 'Mindst 6 tegn';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isParentLoading
                                      ? null
                                      : _handleParentLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    child: _isParentLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Log ind',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        const Divider(height: 1),
                        const SizedBox(height: 18),
                        _TextNavigationRow(
                          icon: Icons.child_care_outlined,
                          title: 'Log ind som barn',
                          onTap: _openChildLogin,
                        ),
                        const SizedBox(height: 10),
                        _TextNavigationRow(
                          icon: Icons.group_add_outlined,
                          title: 'Ny familie',
                          onTap: _openCreateFamily,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Overblik+',
        style: TextStyle(
          fontFamily: 'Italiana',
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: Colors.black,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FamilyHero extends StatelessWidget {
  const _FamilyHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE4EFE6),
        ),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroBubble(
                emoji: '👩',
                label: 'Mor',
                size: 64,
              ),
              SizedBox(width: 12),
              _HeroBubble(
                emoji: '🧒',
                label: 'Barn',
                size: 76,
                highlighted: true,
              ),
              SizedBox(width: 12),
              _HeroBubble(
                emoji: '👨',
                label: 'Far',
                size: 64,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Et roligt overblik for hele familien',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBubble extends StatelessWidget {
  final String emoji;
  final String label;
  final double size;
  final bool highlighted;

  const _HeroBubble({
    required this.emoji,
    required this.label,
    required this.size,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: highlighted
                ? const Color(0xFFDDF4E3)
                : const Color(0xFFFFFFFF),
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
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TextNavigationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _TextNavigationRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: Colors.black87,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}