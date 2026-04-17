import 'package:flutter/material.dart';

import '../widgets/app_top_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _childCanMarkTasksDone = true;
  bool _childCanEditActivities = false;
  bool _childCanDeleteActivities = false;

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

  void _showInviteLinkDialog() {
    const inviteLink = 'https://familiekalender.app/invite/demo-family-123';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Invitationslink'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Del dette link med en forælder eller omsorgsperson for at give adgang til familien.',
              ),
              SizedBox(height: 12),
              SelectableText(
                inviteLink,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Luk'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invitationslink kopieret'),
                  ),
                );
              },
              child: const Text('Kopiér link'),
            ),
          ],
        );
      },
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
                      const _SectionTitle(title: 'Forældretilladelser'),
                      const SizedBox(height: 10),
                      _SettingsCard(
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: _childCanMarkTasksDone,
                              onChanged: (value) {
                                setState(() {
                                  _childCanMarkTasksDone = value;
                                });
                              },
                              title: const Text('Barnet må markere opgaver som udført'),
                              subtitle: const Text(
                                'Giver barnet mulighed for at krydse aktiviteter af.',
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(),
                            SwitchListTile(
                              value: _childCanEditActivities,
                              onChanged: (value) {
                                setState(() {
                                  _childCanEditActivities = value;
                                });
                              },
                              title: const Text('Barnet må redigere aktiviteter'),
                              subtitle: const Text(
                                'Kan bruges til ældre børn med mere selvstændighed.',
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(),
                            SwitchListTile(
                              value: _childCanDeleteActivities,
                              onChanged: (value) {
                                setState(() {
                                  _childCanDeleteActivities = value;
                                });
                              },
                              title: const Text('Barnet må slette aktiviteter'),
                              subtitle: const Text(
                                'Anbefales normalt kun til forældre.',
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _SectionTitle(title: 'Familieadgang'),
                      const SizedBox(height: 10),
                      _SettingsCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _InlineInfoBox(
                              icon: Icons.link_outlined,
                              title: 'Invitér en forælder eller omsorgsperson',
                              text:
                                  'Send et invitationslink for at dele kalender, aktiviteter og familieoversigt.',
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _showInviteLinkDialog,
                              icon: const Icon(Icons.send_outlined),
                              label: const Text('Vis invitationslink'),
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