import 'package:flutter/material.dart';

import '../widgets/app_top_header.dart';
import 'manage_profiles_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  String _selectedTheme = 'Standard';
  String _selectedNotificationStyle = 'Rolig';

  final List<String> _themeOptions = [
    'Standard',
    'Blød',
    'Kontrastrig',
  ];

  final List<String> _notificationStyles = [
    'Rolig',
    'Tydelig',
    'Diskret',
  ];

  void _openManageProfiles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ManageProfilesScreen(),
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
              const AppTopHeader(
                title: 'Indstillinger',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                    children: [
                      const _SectionTitle(title: 'Notifikationer'),
                      const SizedBox(height: 10),
                      _SettingsCard(
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: _notificationsEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _notificationsEnabled = value;
                                });
                              },
                              title: const Text('Aktivér notifikationer'),
                              subtitle: const Text(
                                'Vis påmindelser og ændringer i aktiviteter.',
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(),
                            SwitchListTile(
                              value: _soundEnabled,
                              onChanged: _notificationsEnabled
                                  ? (value) {
                                      setState(() {
                                        _soundEnabled = value;
                                      });
                                    }
                                  : null,
                              title: const Text('Lyd'),
                              subtitle: const Text(
                                'Afspil lyd ved vigtige påmindelser.',
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(),
                            SwitchListTile(
                              value: _vibrationEnabled,
                              onChanged: _notificationsEnabled
                                  ? (value) {
                                      setState(() {
                                        _vibrationEnabled = value;
                                      });
                                    }
                                  : null,
                              title: const Text('Vibration'),
                              subtitle: const Text(
                                'Brug vibration som støtte ved påmindelser.',
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedNotificationStyle,
                              decoration: const InputDecoration(
                                labelText: 'Notifikationsstil',
                                border: OutlineInputBorder(),
                              ),
                              items: _notificationStyles
                                  .map(
                                    (style) => DropdownMenuItem(
                                      value: style,
                                      child: Text(style),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _notificationsEnabled
                                  ? (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _selectedNotificationStyle = value;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const _SectionTitle(title: 'Udseende'),
                      const SizedBox(height: 10),
                      _SettingsCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedTheme,
                              decoration: const InputDecoration(
                                labelText: 'App-tema',
                                border: OutlineInputBorder(),
                              ),
                              items: _themeOptions
                                  .map(
                                    (theme) => DropdownMenuItem(
                                      value: theme,
                                      child: Text(theme),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedTheme = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            const _InlineInfoBox(
                              icon: Icons.palette_outlined,
                              title: 'Visuel tilpasning',
                              text:
                                  'Tema og notifikationsstil kan bruges til at gøre appen mere rolig, tydelig eller enkel afhængigt af barnets behov.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const _SectionTitle(title: 'Familieprofiler'),
                      const SizedBox(height: 10),
                      _SettingsCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _InlineInfoBox(
                              icon: Icons.group_outlined,
                              title: 'Administrér profiler',
                              text:
                                  'Opret børneprofiler, vælg adgangsniveau, se login-koder og ændr børns rolle mellem begrænset og udvidet adgang.',
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _openManageProfiles,
                              icon: const Icon(Icons.manage_accounts_outlined),
                              label: const Text('Administrér profiler'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const _SectionTitle(title: 'Adgangsstruktur'),
                      const SizedBox(height: 10),
                      const _SettingsCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _InlineInfoBox(
                              icon: Icons.admin_panel_settings_outlined,
                              title: 'Forælder',
                              text:
                                  'Har fuld adgang til at oprette, redigere og slette aktiviteter samt administrere profiler, belønninger og indstillinger.',
                            ),
                            SizedBox(height: 12),
                            _InlineInfoBox(
                              icon: Icons.child_care_outlined,
                              title: 'Barn · begrænset adgang',
                              text:
                                  'Kan se kalenderen, markere aktiviteter som udført og krydse checklisten af.',
                            ),
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

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(14),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.black87),
        const SizedBox(width: 10),
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
              const SizedBox(height: 4),
              Text(
                text,
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
    );
  }
}