import 'package:flutter/material.dart';

import '../controllers/theme_controller.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/profile.dart';
import '../services/notification_preferences.dart';
import '../services/profile_service.dart';
import '../widgets/app_top_header.dart';
import 'manage_profiles_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _defaultEnabled = true;
  int _defaultReminderMinutes = 10;
  String _notificationStyle = 'tydelig';

  ThemeMode _selectedThemeMode = themeController.themeMode;
  AppColorOption _selectedColor = themeController.colorOption;
  String _selectedLocale = localeController.locale.languageCode;

  Profile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadNotificationDefaults();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final profile = await ProfileService().getCurrentAuthenticatedProfile();
    if (!mounted) return;
    setState(() => _currentProfile = profile);
  }

  Future<void> _loadNotificationDefaults() async {
    final svc = NotificationPreferencesService();
    final enabled = await svc.loadDefaultEnabled();
    final minutes = await svc.loadDefaultReminderMinutes();
    final style = await svc.loadDefaultNotificationStyle();
    if (!mounted) return;
    setState(() {
      _defaultEnabled = enabled;
      _defaultReminderMinutes = minutes;
      _notificationStyle = style;
    });
  }

  void _openManageProfiles() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageProfilesScreen()),
    );
  }

  void _showSavedSnackBar() {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.changesSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final themeModeOptions = {
      ThemeMode.light: l.lightMode,
      ThemeMode.dark: l.darkMode,
    };

    final colorOptions = {
      AppColorOption.green: l.colorGreen,
      AppColorOption.blue: l.colorBlue,
      AppColorOption.purple: l.colorPurple,
      AppColorOption.orange: l.colorOrange,
      AppColorOption.pink: l.colorPink,
    };

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF050706) : colorScheme.primaryContainer,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTopHeader(title: l.settingsTitle),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _SettingsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionTitle(
                            title: l.notificationsSectionTitle,
                            icon: Icons.notifications_none_outlined,
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            value: _defaultEnabled,
                            onChanged: (value) async {
                              setState(() => _defaultEnabled = value);
                              await NotificationPreferencesService()
                                  .saveDefaultEnabled(value);
                            },
                            title: Text(l.notificationsForNewActivities),
                            subtitle: Text(l.notificationsNewActivitiesSubtitle),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const Divider(),
                          DropdownButtonFormField<int>(
                            key: ValueKey(_defaultReminderMinutes),
                            initialValue: _defaultReminderMinutes,
                            decoration: InputDecoration(
                              labelText: l.defaultReminderTime,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: NotificationPreferencesService
                                .fixedReminderOptions
                                .map(
                                  (m) => DropdownMenuItem<int>(
                                    value: m,
                                    child: Text(l.reminderLabel(m)),
                                  ),
                                )
                                .toList(),
                            onChanged: _defaultEnabled
                                ? (value) async {
                                    if (value == null) return;
                                    setState(
                                      () => _defaultReminderMinutes = value,
                                    );
                                    await NotificationPreferencesService()
                                        .saveDefaultReminderMinutes(value);
                                  }
                                : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey(_notificationStyle),
                            initialValue: _notificationStyle,
                            decoration: InputDecoration(
                              labelText: l.defaultNotifStyle,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: NotificationPreferencesService
                                .notificationStyleOptions
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(l.notificationStyleLabel(s)),
                                  ),
                                )
                                .toList(),
                            onChanged: _defaultEnabled
                                ? (value) async {
                                    if (value == null) return;
                                    setState(() => _notificationStyle = value);
                                    await NotificationPreferencesService()
                                        .saveDefaultNotificationStyle(value);
                                  }
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l.notificationStyleDescription(_notificationStyle),
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionTitle(
                            title: l.appearanceSectionTitle,
                            icon: Icons.palette_outlined,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<ThemeMode>(
                            initialValue: _selectedThemeMode,
                            decoration: InputDecoration(
                              labelText: l.themeLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: themeModeOptions.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) async {
                              if (value == null) return;
                              setState(() => _selectedThemeMode = value);
                              await themeController.setThemeMode(value);
                              if (!context.mounted) return;
                              _showSavedSnackBar();
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<AppColorOption>(
                            initialValue: _selectedColor,
                            decoration: InputDecoration(
                              labelText: l.colorLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: colorOptions.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) async {
                              if (value == null) return;
                              setState(() => _selectedColor = value);
                              await themeController.setColorOption(value);
                              if (!context.mounted) return;
                              _showSavedSnackBar();
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey(_selectedLocale),
                            initialValue: _selectedLocale,
                            decoration: InputDecoration(
                              labelText: l.languageLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'da',
                                child: Text(l.languageDanish),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text(l.languageEnglish),
                              ),
                            ],
                            onChanged: (value) async {
                              if (value == null) return;
                              setState(() => _selectedLocale = value);
                              await localeController.setLocale(Locale(value));
                              if (!context.mounted) return;
                              _showSavedSnackBar();
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_currentProfile?.isParent == true) ...[
                      const SizedBox(height: 14),
                      _SettingsCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SectionTitle(
                              title: l.familyProfilesSectionTitle,
                              icon: Icons.group_outlined,
                            ),
                            const SizedBox(height: 12),
                            _InlineInfoBox(
                              icon: Icons.group_outlined,
                              title: l.manageProfilesInfoTitle,
                              text: l.manageProfilesInfoText,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _openManageProfiles,
                              icon: const Icon(Icons.manage_accounts_outlined),
                              label: Text(l.manageProfilesButton),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_currentProfile?.isParent == true) ...[
                      const SizedBox(height: 14),
                      _SettingsCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SectionTitle(
                              title: l.accessStructureSectionTitle,
                              icon: Icons.admin_panel_settings_outlined,
                            ),
                            const SizedBox(height: 12),
                            _InlineInfoBox(
                              icon: Icons.admin_panel_settings_outlined,
                              title: l.accessStructureParentTitle,
                              text: l.accessStructureParentText,
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            _InlineInfoBox(
                              icon: Icons.child_care_outlined,
                              title: l.accessStructureChildLimitedTitle,
                              text: l.accessStructureChildLimitedText,
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            _InlineInfoBox(
                              icon: Icons.edit_calendar_outlined,
                              title: l.accessStructureChildExtendedTitle,
                              text: l.accessStructureChildExtendedText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.18),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101312) : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2D2C) : Colors.transparent,
        ),
      ),
      child: child,
    );
  }
}

class _InlineInfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InlineInfoBox({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.primary.withValues(
            alpha: isDark ? 0.22 : 0.14,
          ),
          child: Icon(icon, size: 22, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.78),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
