import 'package:flutter/material.dart';

import '../models/profile.dart';
import 'rewards_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Profile profile;
  final List<String> familyMembers;
  final VoidCallback? onOpenCalendar;
  final VoidCallback? onOpenRewards;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onBack;

  const ProfileScreen({
    super.key,
    required this.profile,
    this.familyMembers = const ['Mig', 'Mor', 'Far'],
    this.onOpenCalendar,
    this.onOpenRewards,
    this.onOpenSettings,
    this.onBack,
  });

  String get _roleLabel {
    switch (profile.role) {
      case ProfileRole.parent:
        return 'Forælder';
      case ProfileRole.childExtended:
        return 'Barn · udvidet adgang';
      case ProfileRole.childLimited:
        return 'Barn · begrænset adgang';
    }
  }

  bool get _canOpenSettings {
    return profile.role == ProfileRole.parent;
  }

  bool get _canOpenRewards {
    return profile.role == ProfileRole.parent;
  }

  void _openSettings(BuildContext context) {
    if (!_canOpenSettings) {
      _showMessage(context, 'Indstillinger er kun tilgængelige for forældre');
      return;
    }

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

  void _openRewards(BuildContext context) {
    if (!_canOpenRewards) {
      _showMessage(context, 'Belønninger kan kun administreres af forældre');
      return;
    }

    if (onOpenRewards != null) {
      onOpenRewards!.call();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RewardsScreen(),
      ),
    );
  }

  void _showMessage(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF050706)
          : colorScheme.primaryContainer,
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
                    color: isDark
                        ? const Color(0xFF101312)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2A2D2C)
                          : Colors.transparent,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHeader(
                          name: profile.name,
                          roleLabel: _roleLabel,
                          emoji: profile.emoji,
                        ),
                        const SizedBox(height: 22),
                        const _SectionTitle(title: 'Hurtige handlinger'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.card_giftcard_outlined,
                                label: 'Belønninger',
                                isDisabled: !_canOpenRewards,
                                onTap: () => _openRewards(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.settings_outlined,
                                label: 'Indstillinger',
                                isDisabled: !_canOpenSettings,
                                onTap: () => _openSettings(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const _SectionTitle(title: 'Familie og deltagere'),
                        const SizedBox(height: 10),
                        _FamilyMembersCard(familyMembers: familyMembers),
                        const SizedBox(height: 22),
                        const _SectionTitle(title: 'Profiloplysninger'),
                        const SizedBox(height: 10),
                        _LargeInfoCard(
                          icon: Icons.info_outline,
                          title: 'Om profilen',
                          body:
                          '${profile.name} vises her med rolle, familieoversigt og adgang til relevante profilfunktioner.',
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
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onBack,
          icon: Icon(
            Icons.arrow_back,
            size: 30,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Italiana',
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface,
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101312) : colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? colorScheme.primary.withValues(alpha: 0.45) : Colors.transparent,
          width: isDark ? 1.4 : 0,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: isDark
                ? colorScheme.primary.withValues(alpha: 0.16)
                : Colors.white,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 36),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Italiana',
              fontSize: 30,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.transparent
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDark
                    ? colorScheme.primary.withValues(alpha: 0.55)
                    : const Color(0xFFE0E0E0),
              ),
            ),
            child: Text(
              roleLabel,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
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
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDisabled;

  const _ActionCard({
    required this.icon,
    required this.label,
    this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor = isDark ? colorScheme.primary : colorScheme.onSurface;
    final disabledColor = colorScheme.onSurface.withValues(alpha: 0.32);

    final contentColor = isDisabled ? disabledColor : activeColor;
    final textColor = isDisabled
        ? colorScheme.onSurface.withValues(alpha: 0.32)
        : colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101312) : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? colorScheme.primary.withValues(alpha: isDisabled ? 0.18 : 0.45)
                : const Color(0xFFE0E0E0),
            width: isDark ? 1.3 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: contentColor),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyMembersCard extends StatelessWidget {
  final List<String> familyMembers;

  const _FamilyMembersCard({
    required this.familyMembers,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101312) : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? colorScheme.primary.withValues(alpha: 0.45)
              : const Color(0xFFE0E0E0),
          width: isDark ? 1.3 : 1,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: familyMembers
            .map(
              (member) => Chip(
            label: Text(
              member,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: isDark
                ? Colors.transparent
                : colorScheme.surface,
            side: BorderSide(
              color: isDark
                  ? colorScheme.primary.withValues(alpha: 0.55)
                  : const Color(0xFFE0E0E0),
            ),
          ),
        )
            .toList(),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101312) : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? colorScheme.primary.withValues(alpha: 0.45)
              : const Color(0xFFE0E0E0),
          width: isDark ? 1.3 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 30,
            color: isDark ? colorScheme.primary : colorScheme.onSurface,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.78),
                    height: 1.45,
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