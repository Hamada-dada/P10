import 'package:flutter/material.dart';

import 'create_family_screen.dart';
import 'request_parent_join_screen.dart';

class ParentOnboardingChoiceScreen extends StatelessWidget {
  const ParentOnboardingChoiceScreen({super.key});

  void _openCreateFamily(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateFamilyScreen(),
      ),
    );
  }

  void _openRequestJoin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RequestParentJoinScreen(),
      ),
    );
  }

  void _goBack(BuildContext context) {
    Navigator.maybePop(context);
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Tilbage',
                      onPressed: () => _goBack(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 28,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.family_restroom,
                    size: 56,
                    color: Colors.black87,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Familieadgang',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Italiana',
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Vælg om du vil oprette en ny familie eller anmode om adgang til en eksisterende familie.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ChoiceButton(
                    icon: Icons.add_home_outlined,
                    title: 'Opret ny familie',
                    subtitle: 'Start en ny familie og administrér profiler.',
                    onTap: () => _openCreateFamily(context),
                  ),
                  const SizedBox(height: 12),
                  _ChoiceButton(
                    icon: Icons.group_add_outlined,
                    title: 'Anmod om adgang',
                    subtitle: 'Send en anmodning til en eksisterende familie.',
                    onTap: () => _openRequestJoin(context),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => _goBack(context),
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

class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
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
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: Colors.black87,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
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
          ),
        ),
      ),
    );
  }
} 