import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/maintenance_task.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/form_fields.dart';

/// Create a maintenance task, or edit [existing].
///
/// [initialTreeId] pre-selects a tree when opened from a tree's details.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.existing, this.initialTreeId});

  final MaintenanceTask? existing;
  final String? initialTreeId;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late TaskType _type;
  String? _treeId;
  DateTime? _dueDate;
  bool _saving = false;
  bool _allowPop = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final task = widget.existing;
    _title = TextEditingController(text: task?.title ?? '')
      ..addListener(_refresh);
    _notes = TextEditingController(text: task?.notes ?? '')
      ..addListener(_refresh);
    _type = task?.type ?? TaskType.watering;
    _treeId = task?.treeId ?? widget.initialTreeId;
    _dueDate = task?.dueDate ?? Formatters.dateOnly(DateTime.now());
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _isDirty {
    final task = widget.existing;
    if (task == null) {
      return _title.text.trim().isNotEmpty || _notes.text.trim().isNotEmpty;
    }
    return _title.text.trim() != task.title ||
        _notes.text.trim() != task.notes ||
        _type != task.type ||
        _treeId != task.treeId ||
        _dueDate != task.dueDate;
  }

  Future<void> _cancel() async {
    if (!_isDirty || await AppFeedback.confirmDiscard(context)) {
      if (!mounted) return;
      _allowPop = true;
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final provider = context.read<MaintenanceProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final existing = widget.existing;
      if (existing == null) {
        await provider.addTask(
          title: _title.text,
          type: _type,
          dueDate: _dueDate!,
          treeId: _treeId,
          notes: _notes.text,
        );
      } else {
        await provider.updateTask(
          existing.copyWith(
            title: _title.text.trim(),
            type: _type,
            treeId: _treeId,
            clearTree: _treeId == null,
            dueDate: Formatters.dateOnly(_dueDate!),
            notes: _notes.text.trim(),
          ),
        );
      }
      if (!mounted) return;
      _allowPop = true;
      Navigator.of(context).pop(true);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.forest,
          content: Text(
            _isEditing ? 'Task updated' : 'Maintenance task scheduled',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppFeedback.error(context, 'Could not save the task: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final trees = context.watch<TreeProvider>().trees.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    // Guard against a stale tree id (e.g. the tree was deleted).
    if (_treeId != null && trees.every((t) => t.id != _treeId)) _treeId = null;
    final today = Formatters.dateOnly(DateTime.now());

    return PopScope(
      canPop: _allowPop || !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit task' : 'New maintenance task'),
          leading: IconButton(
            tooltip: 'Cancel',
            icon: const Icon(Icons.close),
            onPressed: _cancel,
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                FormSection(
                  title: 'Task',
                  children: [
                    TextFormField(
                      controller: _title,
                      maxLength: 80,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'e.g. Water new saplings',
                        prefixIcon: Icon(Icons.task_alt),
                      ),
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Please enter a task title'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<TaskType>(
                      initialValue: _type,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Task type *',
                        prefixIcon: Icon(_type.icon),
                      ),
                      items: [
                        for (final type in TaskType.values)
                          DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _type = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String?>(
                      initialValue: _treeId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Assign to tree',
                        prefixIcon: Icon(Icons.park_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Whole plantation (no specific tree)'),
                        ),
                        for (final tree in trees)
                          DropdownMenuItem<String?>(
                            value: tree.id,
                            child: Text(
                              '${tree.name} · ${tree.species}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _treeId = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DatePickerField(
                      label: 'Due date *',
                      value: _dueDate,
                      // Editing keeps old due dates valid; new tasks start today.
                      firstDate: _isEditing && _dueDate!.isBefore(today)
                          ? _dueDate!
                          : today,
                      lastDate: today.add(const Duration(days: 730)),
                      onChanged: (date) => setState(() => _dueDate = date),
                      validator: (value) {
                        if (value == null) return 'Please choose a due date';
                        if (!_isEditing && value.isBefore(today)) {
                          return 'Due date cannot be in the past';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                FormSection(
                  title: 'Notes (optional)',
                  children: [
                    TextFormField(
                      controller: _notes,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Tools needed, volunteers assigned…',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _cancel,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.check),
                        label: Text(
                          _isEditing ? 'Save changes' : 'Schedule task',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
