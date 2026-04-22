import 'package:flutter/material.dart';

import 'daily_calendar_screen.dart';

class ChildLoginScreen extends StatefulWidget {
  const ChildLoginScreen({super.key});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _familyCodeController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _familyCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleChildLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DailyCalendarScreen(),
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
                    'Indtast familiens kode',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _familyCodeController,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Familiekode',
                        hintText: 'ABC123',
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
                          return 'Skriv familiekoden';
                        }
                        return null;
                      },
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
                    onPressed: () => Navigator.pop(context),
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