import 'package:flutter/material.dart';

import '../models/profile.dart';

class FilterPanel extends StatefulWidget {
  final List<Profile> profiles;
  final Set<String> selectedProfileIds;
  final bool showFamilyActivities;
  final bool isChildView;
  final String? currentProfileId;
  final ScrollController? scrollController;

  const FilterPanel({
    super.key,
    required this.profiles,
    required this.selectedProfileIds,
    required this.showFamilyActivities,
    this.isChildView = false,
    this.currentProfileId,
    this.scrollController,
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

  bool _isCurrentProfile(Profile profile) {
    return widget.currentProfileId != null &&
        profile.id == widget.currentProfileId;
  }

  String _profileLabel(Profile profile) {
    if (_isCurrentProfile(profile)) {
      return 'Mine aktiviteter';
    }

    return 'Med ${profile.name}';
  }

  void _selectAll() {
    setState(() {
      _tempSelectedProfileIds = widget.profiles
          .map((profile) => profile.id)
          .toSet();
      _tempShowFamilyActivities = true;
    });
  }

  void _clearAll() {
    setState(() {
      _tempSelectedProfileIds = {};
      _tempShowFamilyActivities = false;
    });
  }

  void _apply() {
    Navigator.pop(context, {
      'profileIds': Set<String>.from(_tempSelectedProfileIds),
      'showFamily': _tempShowFamilyActivities,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          Row(
            children: [
              const Text(
                'Filter',
                style: TextStyle(
                  fontFamily: 'Italiana',
                  fontSize: 26,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Luk',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...widget.profiles.map((profile) {
            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                _profileLabel(profile),
                style: const TextStyle(fontSize: 16),
              ),
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
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Familie / andre',
              style: TextStyle(fontSize: 16),
            ),
            value: _tempShowFamilyActivities,
            onChanged: (checked) {
              setState(() {
                _tempShowFamilyActivities = checked ?? false;
              });
            },
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              TextButton(
                onPressed: _clearAll,
                child: const Text('Ryd'),
              ),
              const Spacer(),
              TextButton(
                onPressed: _selectAll,
                child: const Text('Vis alle'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _apply,
              child: const Text('Anvend filter'),
            ),
          ),
        ],
      ),
    );
  }
}