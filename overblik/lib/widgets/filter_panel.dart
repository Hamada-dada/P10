import 'package:flutter/material.dart';

import '../models/profile.dart';

class FilterPanel extends StatefulWidget {
  final List<Profile> profiles;
  final Set<String> selectedProfileIds;
  final bool showFamilyActivities;
  final bool isChildView;

  const FilterPanel({
    super.key,
    required this.profiles,
    required this.selectedProfileIds,
    required this.showFamilyActivities,
    this.isChildView = false,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late Set<String> _tempSelectedProfileIds;
  late bool _tempShowFamilyActivities;

  @override
  void initState() {
    super.initState();
    _tempSelectedProfileIds = {...widget.selectedProfileIds};
    _tempShowFamilyActivities = widget.showFamilyActivities;
  }

  void _selectAll() {
    setState(() {
      _tempSelectedProfileIds = {
        ...widget.selectedProfileIds,
        ...widget.profiles.map((profile) => profile.id),
      };
      _tempShowFamilyActivities = true;
    });
  }

  String _profileLabel(Profile profile) {
    if (widget.isChildView) {
      return '${profile.name} (mig)';
    }

    return profile.name;
  }

  @override
  Widget build(BuildContext context) {
    final familyLabel = widget.isChildView ? 'Familieaktiviteter' : 'Familie';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter:',
              style: TextStyle(
                fontFamily: 'Italiana',
                fontSize: 24,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.profiles.map((profile) {
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(_profileLabel(profile)),
                value: _tempSelectedProfileIds.contains(profile.id),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _tempSelectedProfileIds.add(profile.id);
                    } else {
                      _tempSelectedProfileIds.remove(profile.id);
                    }
                  });
                },
              );
            }),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(familyLabel),
              value: _tempShowFamilyActivities,
              onChanged: (checked) {
                setState(() {
                  _tempShowFamilyActivities = checked ?? false;
                });
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _selectAll,
                child: const Text('Vis alle'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'profileIds': _tempSelectedProfileIds,
                    'showFamily': _tempShowFamilyActivities,
                  });
                },
                child: const Text('Anvend filter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
