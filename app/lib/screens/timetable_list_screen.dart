import 'package:flutter/material.dart';
import '../models/syllabus_models.dart';
import '../models/timetable_models.dart';
import '../providers/app_state_notifier.dart';
import '../services/timetable_service.dart';
import '../utils/breakpoints.dart';
import '../utils/app_spacing.dart';
import '../widgets/hoverable.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/searchable_dropdown.dart';
import 'syllabus/syllabus_selection_screen.dart';
import 'timetable_detail_screen.dart';

class TimetableListScreen extends StatefulWidget {
  const TimetableListScreen({super.key});

  @override
  State<TimetableListScreen> createState() => _TimetableListScreenState();
}

class _TimetableListScreenState extends State<TimetableListScreen> {
  final TimetableService _timetableService = TimetableService();
  List<TimetableSubject> _subjects = [];
  bool _isLoading = true;
  // Selected subject for the desktop master-detail split view (unused on
  // mobile/tablet, which keep push/pop navigation to TimetableDetailScreen).
  TimetableSubject? _selectedSubject;

  @override
  void initState() {
    super.initState();
    final cached = AppStateNotifier.instance.timetableSubjects;
    if (cached != null) {
      _subjects = cached;
      _isLoading = false;
    }
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    if (_subjects.isEmpty) setState(() => _isLoading = true);
    try {
      final subjects = await _timetableService.getAllSubjects();
      setState(() {
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subjects: $e')),
        );
      }
    }
  }

  int _slotMinutes(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return h * 60 + m;
  }

  bool _slotsOverlap(Map<String, String> a, Map<String, String> b) {
    if (a['day'] != b['day']) return false;
    final aStart = _slotMinutes(a['startTime'] ?? '00:00');
    final aEnd = _slotMinutes(a['endTime'] ?? '00:00');
    final bStart = _slotMinutes(b['startTime'] ?? '00:00');
    final bEnd = _slotMinutes(b['endTime'] ?? '00:00');
    return aStart < bEnd && bStart < aEnd;
  }

  // Checks the slots about to be saved against every class already on any
  // other subject (same-day, overlapping time) and against each other, so a
  // student can't double-book a period. Returns a user-facing message for
  // the first conflict found, or null if there are none.
  String? _findSlotConflict(
    List<Map<String, String>> newSlots,
    Iterable<TimetableSubject> otherSubjects,
  ) {
    for (var i = 0; i < newSlots.length; i++) {
      final slot = newSlots[i];
      for (final other in otherSubjects) {
        for (final c in other.classes) {
          final existingSlot = {
            'day': c.day,
            'startTime': c.startTime,
            'endTime': c.endTime,
          };
          if (_slotsOverlap(slot, existingSlot)) {
            return '${slot['day']} ${slot['startTime']}–${slot['endTime']} '
                'overlaps ${other.name}\'s ${c.startTime}–${c.endTime} slot.';
          }
        }
      }
      for (var j = i + 1; j < newSlots.length; j++) {
        if (_slotsOverlap(slot, newSlots[j])) {
          return 'You have two overlapping slots on ${slot['day']}.';
        }
      }
    }
    return null;
  }

  Future<void> _showSubjectSheet({TimetableSubject? subject}) async {
    final isEditing = subject != null;

    final List<Map<String, String>> slots = subject?.classes
            .map((c) => {
                  'day': c.day,
                  'startTime': c.startTime,
                  'endTime': c.endTime,
                  'room': c.room,
                  'type': c.type,
                })
            .toList() ??
        [];

    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final types = ['CORE', 'LAB', 'BREAK'];
    bool isSaving = false;

    // When editing a subject whose code isn't in the user's saved syllabus
    // subjects (e.g. a legacy free-text entry), keep it selectable by
    // synthesizing an entry rather than forcing a re-pick.
    SavedSubject? selectedSubject;
    if (isEditing) {
      final saved = AppStateNotifier.instance.savedSubjects ?? [];
      final match = saved.where((s) => s.subjectCode == subject.code);
      selectedSubject = match.isNotEmpty
          ? match.first
          : SavedSubject(subjectCode: subject.code, subjectName: subject.name);
    }

    Widget buildSheetContent(BuildContext ctx) {
      return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final rawSavedSubjects = AppStateNotifier.instance.savedSubjects ?? [];
            final hasAssignedSubjects = rawSavedSubjects.isNotEmpty &&
                !AppStateNotifier.instance.savedSubjectsFromCurriculum;
            final availableSubjects = <SavedSubject>[
              if (selectedSubject != null &&
                  !rawSavedSubjects
                      .any((s) => s.subjectCode == selectedSubject!.subjectCode))
                selectedSubject!,
              if (hasAssignedSubjects) ...rawSavedSubjects,
            ];
            final showSubjectCta = !hasAssignedSubjects && selectedSubject == null;

            // Recomputed on every rebuild (i.e. whenever a slot is added or
            // removed via setSheetState below), so the error clears itself
            // the moment the offending slot is deleted — no separate state
            // to keep in sync, and no network call since _subjects is
            // already loaded locally.
            final otherSubjects =
                _subjects.where((s) => !isEditing || s.id != subject.id);
            final conflictError = _findSlotConflict(slots, otherSubjects);

            String formatHour(double h) {
              final totalMinutes = (h * 60).round();
              final hh = totalMinutes ~/ 60;
              final mm = totalMinutes % 60;
              return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
            }

            Future<void> addSlot() async {
              final selectedDays = <String>{'MON'};
              double startHour = 9;
              double endHour = 10;
              String selectedType = types.first;
              final roomController = TextEditingController();

              final confirmed = await showDialog<bool>(
                context: ctx,
                builder: (dlgCtx) => StatefulBuilder(
                  builder: (dlgCtx, setDlgState) {
                    final dayOrder = days.where(selectedDays.contains).toList();
                    final previewText = dayOrder.isEmpty
                        ? 'Select at least one day'
                        : '${dayOrder.join(', ')} · ${formatHour(startHour)}–${formatHour(endHour)}';

                    return AlertDialog(
                      backgroundColor: const Color(0xFFFFF8E4),
                      title: const Text(
                        'Add Class Slot',
                        style:
                            TextStyle(fontFamily: 'Lexend Mega', fontSize: 16),
                      ),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Days',
                              style: TextStyle(
                                  fontFamily: 'Public Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: days.map((d) {
                                final isOn = selectedDays.contains(d);
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => setDlgState(() {
                                      if (isOn) {
                                        selectedDays.remove(d);
                                      } else {
                                        selectedDays.add(d);
                                      }
                                    }),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 2),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isOn
                                            ? Colors.black
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.black, width: 1.5),
                                      ),
                                      child: Text(
                                        d.substring(0, 1),
                                        style: TextStyle(
                                          fontFamily: 'Public Sans',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isOn
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Time',
                              style: TextStyle(
                                  fontFamily: 'Public Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                const Text('Start  ',
                                    style: TextStyle(
                                        fontFamily: 'Public Sans',
                                        fontSize: 12)),
                                Text(
                                  formatHour(startHour),
                                  style: const TextStyle(
                                      fontFamily: 'Public Sans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            Slider(
                              value: startHour,
                              min: 6,
                              max: 22,
                              divisions: 64,
                              label: formatHour(startHour),
                              onChanged: (v) => setDlgState(() {
                                startHour = v;
                                if (endHour < startHour + 0.25) {
                                  endHour = (startHour + 0.25).clamp(6, 22);
                                }
                              }),
                            ),
                            Row(
                              children: [
                                const Text('End  ',
                                    style: TextStyle(
                                        fontFamily: 'Public Sans',
                                        fontSize: 12)),
                                Text(
                                  formatHour(endHour),
                                  style: const TextStyle(
                                      fontFamily: 'Public Sans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            Slider(
                              value: endHour,
                              min: 6,
                              max: 22,
                              divisions: 64,
                              label: formatHour(endHour),
                              onChanged: (v) => setDlgState(() {
                                endHour = v;
                                if (startHour > endHour - 0.25) {
                                  startHour = (endHour - 0.25).clamp(6, 22);
                                }
                              }),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Type',
                              style: TextStyle(
                                  fontFamily: 'Public Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: types.map((t) {
                                final isOn = selectedType == t;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setDlgState(() => selectedType = t),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 2),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isOn
                                            ? Colors.black
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.black, width: 1.5),
                                      ),
                                      child: Text(
                                        t,
                                        style: TextStyle(
                                          fontFamily: 'Public Sans',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                          color: isOn
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: roomController,
                              decoration: const InputDecoration(
                                  labelText: 'Room (optional)'),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Adding: $previewText',
                                style: const TextStyle(
                                    fontFamily: 'Public Sans', fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dlgCtx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: selectedDays.isEmpty
                              ? null
                              : () => Navigator.pop(dlgCtx, true),
                          child: const Text('Add'),
                        ),
                      ],
                    );
                  },
                ),
              );

              if (confirmed == true) {
                setSheetState(() {
                  for (final day in days.where(selectedDays.contains)) {
                    slots.add({
                      'day': day,
                      'startTime': formatHour(startHour),
                      'endTime': formatHour(endHour),
                      'room': roomController.text.trim(),
                      'type': selectedType,
                    });
                  }
                });
              }
            }

            Future<void> saveSubject() async {
              if (selectedSubject == null) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Select a subject first.')),
                  );
                }
                return;
              }
              final name = selectedSubject!.subjectName;
              final code = selectedSubject!.subjectCode;

              setSheetState(() => isSaving = true);

              try {
                final existing = await _timetableService.getAllSubjects();

                final classes = slots.map((s) {
                  final start = s['startTime'] ?? '09:00';
                  return TimetableClass(
                    day: s['day'] ?? 'MON',
                    startTime: start,
                    endTime: s['endTime'] ?? start,
                    period: (int.tryParse(start.split(':').first) ?? 9) >= 12
                        ? 'PM'
                        : 'AM',
                    room: s['room'] ?? '',
                    type: s['type'] ?? 'CORE',
                    duration: 1,
                  );
                }).toList();

                final newSubject = TimetableSubject(
                  id: isEditing
                      ? subject.id
                      : code.toLowerCase().replaceAll(' ', '_'),
                  name: name,
                  code: code,
                  classes: classes,
                );

                final List<TimetableSubject> merged;
                if (isEditing) {
                  merged = existing
                      .map((s) => s.id == subject.id ? newSubject : s)
                      .toList();
                } else {
                  merged = [...existing, newSubject];
                }
                await _timetableService.saveSubjects(merged);

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() => _subjects = merged);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing
                          ? 'Subject updated successfully!'
                          : 'Subject added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  setSheetState(() => isSaving = false);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error saving subject: $e')),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEditing ? 'Edit Subject' : 'Add Subject',
                      style: const TextStyle(
                        fontFamily: 'Lexend Mega',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (showSubjectCta)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8B0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'No subjects assigned yet',
                              style: TextStyle(
                                  fontFamily: 'Public Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Confirm your actual subjects for this semester before building a timetable.',
                              style: TextStyle(
                                  fontFamily: 'Public Sans',
                                  fontSize: 12,
                                  color: Colors.black87),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    ctx,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SyllabusSelectionScreen(),
                                    ),
                                  );
                                  setSheetState(() {});
                                },
                                icon: const Icon(Icons.checklist),
                                label: const Text('Configure subjects'),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SearchableDropdown<SavedSubject>(
                        items: availableSubjects,
                        value: selectedSubject,
                        labelBuilder: (s) =>
                            '${s.subjectCode} — ${s.subjectName}',
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (s) =>
                            setSheetState(() => selectedSubject = s),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Class Slots',
                          style: TextStyle(
                            fontFamily: 'Public Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: addSlot,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Slot'),
                        ),
                      ],
                    ),
                    if (slots.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No class slots added yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...(() {
                        // Slots sharing the same time/room/type (added
                        // together across multiple days) collapse into one
                        // row, e.g. "MON/WED/FRI 09:00-10:00", instead of a
                        // separate row per day.
                        final grouped = <String, List<int>>{};
                        for (var i = 0; i < slots.length; i++) {
                          final s = slots[i];
                          final key =
                              '${s['startTime']}|${s['endTime']}|${s['room']}|${s['type']}';
                          grouped.putIfAbsent(key, () => []).add(i);
                        }
                        return grouped.values.map((indices) {
                          final first = slots[indices.first];
                          final dayLabels = indices
                              .map((i) => slots[i]['day']!)
                              .toList()
                            ..sort((a, b) =>
                                days.indexOf(a).compareTo(days.indexOf(b)));
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${dayLabels.join('/')} ${first['startTime']}–${first['endTime']}',
                              style: const TextStyle(
                                  fontFamily: 'Public Sans',
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${first['type']}${first['room']!.isNotEmpty ? ' · ${first['room']}' : ''}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => setSheetState(() {
                                for (final i in indices.toList()
                                  ..sort((a, b) => b.compareTo(a))) {
                                  slots.removeAt(i);
                                }
                              }),
                            ),
                          );
                        });
                      })(),
                    if (conflictError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD9D9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                conflictError,
                                style: const TextStyle(
                                  fontFamily: 'Public Sans',
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (isSaving || conflictError != null)
                            ? null
                            : saveSubject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD966),
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : Text(
                                isEditing ? 'Update Subject' : 'Save Subject',
                                style: const TextStyle(
                                  fontFamily: 'Public Sans',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

    final width = MediaQuery.of(context).size.width;
    if (Breakpoints.isAtLeastDesktop(width)) {
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: const Color(0xFFFFF8E4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: buildSheetContent(ctx),
            ),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFFFFF8E4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          side: BorderSide(color: Colors.black, width: 2),
        ),
        builder: buildSheetContent,
      );
    }
  }

  Future<void> _removeSubject(TimetableSubject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: const Text(
          'Remove Subject',
          style: TextStyle(fontFamily: 'Lexend Mega', fontSize: 16),
        ),
        content: Text('Remove "${subject.name}" from your timetable?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final existing = await _timetableService.getAllSubjects();
      final updated = existing.where((s) => s.id != subject.id).toList();
      await _timetableService.saveSubjects(updated);
      setState(() => _subjects = updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Subject removed.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing subject: $e')),
        );
      }
    }
  }

  void _openTimetableDetail(TimetableSubject subject) {
    if (Breakpoints.isAtLeastDesktop(MediaQuery.of(context).size.width)) {
      setState(() => _selectedSubject = subject);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimetableDetailScreen(subject: subject),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEEEC3),
      body: SafeArea(
        bottom: false,
        child: ResponsiveLayout(
          mobile: (_) => _mobileBody(context),
          desktop: (_) => _desktopSplitView(context),
        ),
      ),
    );
  }

  Widget _mobileBody(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        // Main content
        Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.045,
                vertical: 20,
              ),
              child: _buildHeader(screenWidth),
            ),

            // Subject cards list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _subjects.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.045,
                          ).copyWith(
                            bottom:
                                100 + MediaQuery.of(context).padding.bottom,
                          ),
                          itemCount: _subjects.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _buildSubjectCard(
                                _subjects[index],
                                screenWidth,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),

        // Floating Action Button for adding a subject manually
        Positioned(
          right: 20,
          bottom: 20,
          child: _buildAddButton(),
        ),
      ],
    );
  }

  // Desktop: master-detail split — subject list on the left, the selected
  // subject's weekly schedule (TimetableDetailView, no Scaffold/header of
  // its own) on the right. Mobile/tablet keep the push/pop navigation above
  // completely unchanged.
  Widget _desktopSplitView(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_subjects.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(AppSpacing.pagePadding(width)),
        child: _buildEmptyState(),
      );
    }

    final selected = _selectedSubject ?? _subjects.first;

    return Padding(
      padding: EdgeInsets.all(AppSpacing.pagePadding(width)),
      child: MaxWidthContent(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(width),
                  SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _subjects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        return _buildSubjectListTile(
                          subject,
                          subject.id == selected.id,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showSubjectSheet(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Subject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD966),
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.xl),
            Expanded(
              child: TimetableDetailView(
                key: ValueKey(selected.id),
                subject: selected,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectListTile(TimetableSubject subject, bool isSelected) {
    return Hoverable(
      builder: (context, hovered) => GestureDetector(
        onTap: () => setState(() => _selectedSubject = subject),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFD966)
                : (hovered ? const Color(0xFFFFF8E4) : Colors.white),
            border: Border.all(
                color: Colors.black, width: isSelected ? 2 : 1.5),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                offset: const Offset(2, 2),
                color: Colors.black.withValues(alpha: isSelected ? 1 : 0.35),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.code,
                      style: const TextStyle(
                        fontFamily: 'Lexend Mega',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subject.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Public Sans',
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showSubjectSheet(subject: subject),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined, size: 18),
                ),
              ),
              GestureDetector(
                onTap: () => _removeSubject(subject),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    return const Row(
      children: [
        Icon(Icons.calendar_today, size: 24, color: Colors.black),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Time Table',
            style: TextStyle(
              fontFamily: 'Lexend Mega',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(TimetableSubject subject, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD966),
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(offset: Offset(4, 4), color: Colors.black),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _openTimetableDetail(subject),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.code,
                        style: const TextStyle(
                          fontFamily: 'Lexend Mega',
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subject.name,
                        style: TextStyle(
                          fontFamily: 'Public Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: Colors.black.withValues(alpha: 0.8),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _showSubjectSheet(subject: subject),
                    child: const Icon(Icons.edit_outlined,
                        size: 20, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _removeSubject(subject),
                    child: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _openTimetableDetail(subject),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.black),
                const SizedBox(width: 8),
                Text(
                  '${subject.classes.length} classes per week',
                  style: const TextStyle(
                    fontFamily: 'Public Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month,
            size: 80,
            color: Colors.black.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No timetables yet',
            style: TextStyle(
              fontFamily: 'Public Sans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a subject',
            style: TextStyle(
              fontFamily: 'Public Sans',
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD966),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            offset: Offset(4, 4),
            color: Colors.black,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSubjectSheet(),
          customBorder: const CircleBorder(),
          child: const Icon(
            Icons.add,
            size: 28,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
