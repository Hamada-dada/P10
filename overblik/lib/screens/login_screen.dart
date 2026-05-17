import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/theme_controller.dart' show AppColorOption;
import '../l10n/app_localizations.dart';
import '../main.dart' show localeController, themeController;
import '../services/parent_join_service.dart';
import 'child_login_screen.dart';
import 'daily_calendar_screen.dart';
import 'parent_onboarding_choice_screen.dart';
import 'pending_parent_request_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _parentFormKey = GlobalKey<FormState>();

  final ParentJoinService _parentJoinService = ParentJoinService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isParentLoading = false;

  @override
  void initState() {
    super.initState();
    themeController.setThemeMode(ThemeMode.light);
    themeController.setColorOption(AppColorOption.green);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _routeAfterParentAuth() async {
    final onboardingState =
        await _parentJoinService.getParentOnboardingState();

    if (!mounted) return;

    switch (onboardingState.state) {
      case ParentOnboardingStateType.activeParent:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DailyCalendarScreen(),
          ),
        );
        return;

      case ParentOnboardingStateType.pendingParentRequest:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PendingParentRequestScreen(
              requestId: onboardingState.requestId,
              familyName: onboardingState.familyName,
            ),
          ),
        );
        return;

      case ParentOnboardingStateType.needsOnboarding:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ParentOnboardingChoiceScreen(),
          ),
        );
        return;
    }
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

      await _routeAfterParentAuth();
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
          content: Text(AppLocalizations.of(context).loginError(e)),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isParentLoading = false;
        });
      }
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

void _openNewParentFlow() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const ParentOnboardingChoiceScreen(),
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  const Expanded(child: SizedBox()),
                  const _BrandHeader(),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _LangToggle(),
                    ),
                  ),
                ],
              ),
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
                        _SectionTitle(
                          title: l.loginParentSectionTitle,
                          subtitle: l.loginParentSubtitle,
                        ),
                        const SizedBox(height: 14),
                        Form(
                          key: _parentFormKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  labelText: l.emailLabel,
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) return l.emailRequired;
                                  if (!text.contains('@')) return l.emailInvalid;
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                decoration: _inputDecoration(
                                  labelText: l.passwordLabel,
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
                                  if (text.isEmpty) return l.passwordRequired;
                                  if (text.length < 6) return l.passwordTooShort;
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  if (!_isParentLoading) {
                                    _handleParentLogin();
                                  }
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
                                        : Text(
                                            l.loginButton,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        _ChildLoginCard(
                          onTap: _openChildLogin,
                        ),
                        const SizedBox(height: 12),
                        _NewParentCard(
                          onTap: _openNewParentFlow,
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

  InputDecoration _inputDecoration({
    required String labelText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      suffixIcon: suffixIcon,
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
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Overblik+',
      style: TextStyle(
        fontFamily: 'Italiana',
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: Color(0xFF1A3D1A),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  const _LangToggle();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (_, _) {
        final current = localeController.locale.languageCode;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangChip(
              label: 'DA',
              selected: current == 'da',
              onTap: () => localeController.setLocale(const Locale('da')),
            ),
            const SizedBox(width: 2),
            _LangChip(
              label: 'EN',
              selected: current == 'en',
              onTap: () => localeController.setLocale(const Locale('en')),
            ),
          ],
        );
      },
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: selected ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2E7D32) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF2E7D32)
                : const Color(0xFF1A3D1A).withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF1A3D1A),
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
    final l = AppLocalizations.of(context);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroBubble(emoji: '👩', label: l.mom, size: 64),
              const SizedBox(width: 12),
              _HeroBubble(emoji: '🧒', label: l.child, size: 76, highlighted: true),
              const SizedBox(width: 12),
              _HeroBubble(emoji: '👨', label: l.dad, size: 64),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l.familyTagline,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _ChildLoginCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ChildLoginCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
            ),
          ),
          child: Builder(
            builder: (ctx) {
              final l = AppLocalizations.of(ctx);
              return Row(
                children: [
                  const Icon(
                    Icons.child_care_outlined,
                    size: 26,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.childLoginCardTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l.childLoginCardSubtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.black54,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NewParentCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NewParentCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6FBF7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE4EFE6),
            ),
          ),
          child: Builder(
            builder: (ctx) {
              final l = AppLocalizations.of(ctx);
              return Row(
                children: [
                  const Icon(
                    Icons.add_home_outlined,
                    size: 26,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.newParentCardTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l.newParentCardSubtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.black54,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}