import 'package:flutter/material.dart';

import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String name;
  final String roleLabel;
  final String emoji;
  final List<String> familyMembers;
  final VoidCallback? onOpenCalendar;
  final VoidCallback? onOpenRewards;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onBack;

  const ProfileScreen({
    super.key,
    this.name = 'Mig',
    this.roleLabel = 'Barn',
    this.emoji = '🙂',
    this.familyMembers = const ['Mig', 'Mor', 'Far'],
    this.onOpenCalendar,
    this.onOpenRewards,
    this.onOpenSettings,
    this.onBack,
  });

  void _openSettings(BuildContext context) {
    if (onOpenSettings != null) {
      onOpenSettings!.call();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label kommer snart'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(
                title: 'Profil',
                onBack: onBack ?? () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHeader(
                          name: name,
                          roleLabel: roleLabel,
                          emoji: emoji,
                        ),
                        const SizedBox(height: 20),
                        const _SectionTitle(title: 'Hurtige handlinger'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.calendar_today_outlined,
                                label: 'Kalender',
                                onTap: onOpenCalendar ??
                                    () => _showComingSoon(context, 'Kalender'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.card_giftcard_outlined,
                                label: 'Belønninger',
                                onTap: onOpenRewards ??
                                    () => _showComingSoon(context, 'Belønninger'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.settings_outlined,
                                label: 'Indstillinger',
                                onTap: () => _openSettings(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: _InfoCard(
                                icon: Icons.star_border,
                                title: 'Favoritter',
                                subtitle: 'Dine vigtige aktiviteter',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const _SectionTitle(title: 'Dagens fokus'),
                        const SizedBox(height: 10),
                        const _LargeInfoCard(
                          icon: Icons.wb_sunny_outlined,
                          title: 'I dag',
                          body:
                              'Her kan du hurtigt få overblik over dagens aktiviteter, belønninger og det vigtigste, du skal huske.',
                        ),
                        const SizedBox(height: 20),
                        const _SectionTitle(title: 'Familie og deltagere'),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: familyMembers
                                .map(
                                  (member) => Chip(
                                    label: Text(member),
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _SectionTitle(title: 'Profiloplysninger'),
                        const SizedBox(height: 10),
                        const _LargeInfoCard(
                          icon: Icons.info_outline,
                          title: 'Om profilen',
                          body:
                              'Profilen bruges til at vise aktiviteter, deltagere og kalenderoversigter på en tydelig måde.',
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: onOpenCalendar ??
                                () => _showComingSoon(context, 'Kalender'),
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Text('Åbn kalender'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
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

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _TopBar({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
            color: Colors.black,
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Italiana',
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 30),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String roleLabel;
  final String emoji;

  const _ProfileHeader({
    required this.name,
    required this.roleLabel,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 34),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Italiana',
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Text(
              roleLabel,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Colors.black87),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _LargeInfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}