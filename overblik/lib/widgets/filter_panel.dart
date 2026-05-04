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

  String _displayName(Profile profile) {
    final displayName = profile.displayName.trim();

    if (displayName.isNotEmpty) {
      return displayName;
    }

    return profile.name.trim().isNotEmpty ? profile.name.trim() : 'Ukendt';
  }

  List<Profile> get _otherProfiles {
    final profiles = widget.profiles
        .where((profile) => !_isCurrentProfile(profile))
        .toList();

    profiles.sort((a, b) {
      final roleOrder = _roleSortValue(a).compareTo(_roleSortValue(b));

      if (roleOrder != 0) {
        return roleOrder;
      }

      return _displayName(a)
          .toLowerCase()
          .compareTo(_displayName(b).toLowerCase());
    });

    return profiles;
  }

  int _roleSortValue(Profile profile) {
    if (profile.isParent) return 0;
    if (profile.isChild) return 1;
    return 2;
  }

  bool get _hasCurrentProfile {
    return widget.currentProfileId != null &&
        widget.profiles.any((profile) => profile.id == widget.currentProfileId);
  }

  void _resetToDefault() {
    setState(() {
      if (widget.currentProfileId == null) {
        _tempSelectedProfileIds = {};
        _tempShowFamilyActivities = false;
        return;
      }

      _tempSelectedProfileIds = {widget.currentProfileId!};

      // Required rule:
      // Parent default = own + family.
      // Child default = own only.
      _tempShowFamilyActivities = !widget.isChildView;
    });
  }

  void _selectAll() {
    setState(() {
      _tempSelectedProfileIds =
          widget.profiles.map((profile) => profile.id).toSet();
      _tempShowFamilyActivities = true;
    });
  }

  void _applyFilter() {
    Navigator.pop(context, {
      'profileIds': _tempSelectedProfileIds,
      'showFamily': _tempShowFamilyActivities,
    });
  }

  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          height: 1.2,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFCF9FF),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontFamily: 'Italiana',
                    fontSize: 26,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView(
                    controller: widget.scrollController,
                    shrinkWrap: true,
                    children: [
                      if (_hasCurrentProfile)
                        _buildCheckboxTile(
                          title: 'Mine aktiviteter',
                          value: _tempSelectedProfileIds.contains(
                            widget.currentProfileId,
                          ),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _tempSelectedProfileIds.add(
                                  widget.currentProfileId!,
                                );
                              } else {
                                _tempSelectedProfileIds.remove(
                                  widget.currentProfileId,
                                );
                              }
                            });
                          },
                        ),
                      _buildCheckboxTile(
                        title: 'Familieaktiviteter',
                        value: _tempShowFamilyActivities,
                        onChanged: (checked) {
                          setState(() {
                            _tempShowFamilyActivities = checked ?? false;
                          });
                        },
                      ),
                      ..._otherProfiles.map((profile) {
                        return _buildCheckboxTile(
                          title: 'Med ${_displayName(profile)}',
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
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [

                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: _selectAll,
                        child: const Text('Vis alle'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilter,
                    child: const Text('Anvend filter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}