import 'package:flutter/material.dart';

import '../controllers/theme_controller.dart';
import '../main.dart';
import '../services/notification_preferences.dart';
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
  bool _isCustomDefault = false;
  late TextEditingController _customAmountController;
  String _customUnit = 'minutter';
  String _notificationStyle = 'tydelig';

  ThemeMode _selectedThemeMode = themeController.themeMode;
  AppColorOption _selectedColor = themeController.colorOption;

  final Map<ThemeMode, String> _themeModeOptions = {
    ThemeMode.light: 'Lys tilstand',
    ThemeMode.dark: 'Mørk tilstand',
  };

  final Map<AppColorOption, String> _colorOptions = {
    AppColorOption.green: 'Grøn',
    AppColorOption.blue: 'Blå',
    AppColorOption.purple: 'Lilla',
    AppColorOption.orange: 'Orange',
    AppColorOption.pink: 'Rosa',
  };

  @override
  void initState() {
    super.initState();
    _isCustomDefault =
        !NotificationPreferencesService.isFixedOption(_defaultReminderMinutes);
    final init = _minutesToAmountUnit(_defaultReminderMinutes);
    _customAmountController = TextEditingController(
      text: _isCustomDefault ? init.amount.toString() : '',
    );
    _customUnit = _isCustomDefault ? init.unit : 'minutter';
    _loadNotificationDefaults();
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  ({int amount, String unit}) _minutesToAmountUnit(int minutes) {
    if (minutes > 0 && minutes % 10080 == 0) {
      return (amount: minutes ~/ 10080, unit: 'uger');
    }
    if (minutes > 0 && minutes % 1440 == 0) {
      return (amount: minutes ~/ 1440, unit: 'dage');
    }
    if (minutes > 0 && minutes % 60 == 0) {
      return (amount: minutes ~/ 60, unit: 'timer');
    }
    return (amount: minutes, unit: 'minutter');
  }

  int _amountUnitToMinutes(int amount, String unit) {
    switch (unit) {
      case 'uger':
        return amount * 10080;
      case 'dage':
        return amount * 1440;
      case 'timer':
        return amount * 60;
      default:
        return amount;
    }
  }

  Future<void> _loadNotificationDefaults() async {
    final svc = NotificationPreferencesService();
    final enabled = await svc.loadDefaultEnabled();
    final minutes = await svc.loadDefaultReminderMinutes();
    final style = await svc.loadDefaultNotificationStyle();
    if (!mounted) return;
    final isCustom = !NotificationPreferencesService.isFixedOption(minutes);
    final init = _minutesToAmountUnit(minutes);
    setState(() {
      _defaultEnabled = enabled;
      _defaultReminderMinutes = minutes;
      _isCustomDefault = isCustom;
      _notificationStyle = style;
      if (isCustom) {
        _customAmountController.text = init.amount.toString();
        _customUnit = init.unit;
      }
    });
  }

  void _openManageProfiles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ManageProfilesScreen(),
      ),
    );
  }

  void _showSavedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Din ændring er gemt.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF050706) : colorScheme.primaryContainer,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppTopHeader(
                title: 'Indstillinger',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _SettingsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SectionTitle(
                            title: 'Notifikationer',
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
                            title: const Text('Notifikationer til nye aktiviteter'),
                            subtitle: const Text(
                              'Standardindstilling for nye aktiviteter. '
                              'Kan ændres per aktivitet.',
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const Divider(),
                          DropdownButtonFormField<int?>(
                            key: ValueKey(
                              _isCustomDefault ? null : _defaultReminderMinutes,
                            ),
                            initialValue:
                                _isCustomDefault ? null : _defaultReminderMinutes,
                            decoration: const InputDecoration(
                              labelText: 'Standard påmindelsestid',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              ...NotificationPreferencesService
                                  .fixedReminderOptions
                                  .map(
                                    (m) => DropdownMenuItem<int?>(
                                      value: m,
                                      child: Text(
                                        NotificationPreferencesService
                                            .reminderLabel(m),
                                      ),
                                    ),
                                  ),
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Tilpasset'),
                              ),
                            ],
                            onChanged: _defaultEnabled
                                ? (value) async {
                                    if (value != null) {
                                      setState(() {
                                        _isCustomDefault = false;
                                        _defaultReminderMinutes = value;
                                      });
                                      await NotificationPreferencesService()
                                          .saveDefaultReminderMinutes(value);
                                    } else {
                                      final init = _minutesToAmountUnit(
                                        _defaultReminderMinutes,
                                      );
                                      setState(() {
                                        _isCustomDefault = true;
                                        _customAmountController.text =
                                            init.amount.toString();
                                        _customUnit = init.unit;
                                      });
                                    }
                                  }
                                : null,
                          ),
                          if (_isCustomDefault && _defaultEnabled) ...[
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _customAmountController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Antal',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (raw) async {
                                      final amount =
                                          int.tryParse(raw.trim());
                                      if (amount == null || amount < 0) return;
                                      final total = _amountUnitToMinutes(
                                        amount,
                                        _customUnit,
                                      );
                                      if (total < 0 || total > 10080) return;
                                      setState(
                                        () => _defaultReminderMinutes = total,
                                      );
                                      await NotificationPreferencesService()
                                          .saveDefaultReminderMinutes(total);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey(_customUnit),
                                    initialValue: _customUnit,
                                    decoration: const InputDecoration(
                                      labelText: 'Enhed',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'minutter',
                                        child: Text('minutter'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'timer',
                                        child: Text('timer'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'dage',
                                        child: Text('dage'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'uger',
                                        child: Text('uger'),
                                      ),
                                    ],
                                    onChanged: (unit) async {
                                      if (unit == null) return;
                                      setState(() => _customUnit = unit);
                                      final amount = int.tryParse(
                                        _customAmountController.text.trim(),
                                      );
                                      if (amount == null || amount < 0) return;
                                      final total =
                                          _amountUnitToMinutes(amount, unit);
                                      if (total < 0 || total > 10080) return;
                                      setState(
                                        () => _defaultReminderMinutes = total,
                                      );
                                      await NotificationPreferencesService()
                                          .saveDefaultReminderMinutes(total);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey(_notificationStyle),
                            initialValue: _notificationStyle,
                            decoration: const InputDecoration(
                              labelText: 'Standard notifikationsstil',
                              border: OutlineInputBorder(),
                            ),
                            items: NotificationPreferencesService
                                .notificationStyleOptions
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      NotificationPreferencesService
                                          .notificationStyleLabel(s),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _defaultEnabled
                                ? (value) async {
                                    if (value == null) return;
                                    setState(
                                      () => _notificationStyle = value,
                                    );
                                    await NotificationPreferencesService()
                                        .saveDefaultNotificationStyle(value);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SectionTitle(
                            title: 'Udseende',
                            icon: Icons.palette_outlined,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<ThemeMode>(
                            initialValue: _selectedThemeMode,
                            decoration: const InputDecoration(
                              labelText: 'Tema',
                              border: OutlineInputBorder(),
                            ),
                            items: _themeModeOptions.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) async {
                              if (value == null) return;

                              setState(() {
                                _selectedThemeMode = value;
                              });

                              await themeController.setThemeMode(value);

                              if (!context.mounted) return;
                              _showSavedSnackBar();
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<AppColorOption>(
                            initialValue: _selectedColor,
                            decoration: const InputDecoration(
                              labelText: 'Farve',
                              border: OutlineInputBorder(),
                            ),
                            items: _colorOptions.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) async {
                              if (value == null) return;

                              setState(() {
                                _selectedColor = value;
                              });

                              await themeController.setColorOption(value);

                              if (!context.mounted) return;
                              _showSavedSnackBar();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SectionTitle(
                            title: 'Familieprofiler',
                            icon: Icons.group_outlined,
                          ),
                          const SizedBox(height: 12),
                          const _InlineInfoBox(
                            icon: Icons.group_outlined,
                            title: 'Administrér profiler',
                            text:
                                'Opret børneprofiler, vælg adgangsniveau, se login-koder og ændre børnenes rolle mellem begrænset og udvidet adgang.',
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _openManageProfiles,
                            icon: const Icon(Icons.manage_accounts_outlined),
                            label: const Text('Administrér profiler'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _SettingsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionTitle(
                            title: 'Adgangsstruktur',
                            icon: Icons.admin_panel_settings_outlined,
                          ),
                          SizedBox(height: 12),
                          _InlineInfoBox(
                            icon: Icons.admin_panel_settings_outlined,
                            title: 'Forælder',
                            text:
                                'Har fuld adgang til at oprette, redigere og slette aktiviteter samt administrere profiler, belønninger og indstillinger.',
                          ),
                          SizedBox(height: 12),
                          Divider(),
                          SizedBox(height: 12),
                          _InlineInfoBox(
                            icon: Icons.child_care_outlined,
                            title: 'Barn · begrænset adgang',
                            text:
                                'Kan se kalenderen, markere aktiviteter som udført og krydse checklisten af.',
                          ),
                          SizedBox(height: 12),
                          Divider(),
                          SizedBox(height: 12),
                          _InlineInfoBox(
                            icon: Icons.edit_calendar_outlined,
                            title: 'Barn · udvidet adgang',
                            text:
                                'Kan også oprette, redigere og slette egne aktiviteter.',
                          ),
                        ],
                      ),
                    ),
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

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.18),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
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

  const _SettingsCard({
    required this.child,
  });

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
          backgroundColor: colorScheme.primary.withValues(alpha:
            isDark ? 0.22 : 0.14,
          ),
          child: Icon(
            icon,
            size: 22,
            color: colorScheme.primary,
          ),
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
