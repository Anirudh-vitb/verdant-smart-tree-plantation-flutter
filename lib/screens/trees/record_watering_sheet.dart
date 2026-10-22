import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/feedback.dart';

/// Opens the "Record watering" form.
///
/// When [treeId] is null the user picks the tree from a dropdown.
/// Returns true when a record was saved.
Future<bool> showRecordWateringSheet(
  BuildContext context, {
  String? treeId,
}) async {
  if (context.read<TreeProvider>().trees.isEmpty) {
    AppFeedback.error(context, 'Add a tree before recording watering.');
    return false;
  }
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => RecordWateringSheet(treeId: treeId),
  );
  return saved ?? false;
}

class RecordWateringSheet extends StatefulWidget {
  const RecordWateringSheet({super.key, this.treeId});

  final String? treeId;

  @override
  State<RecordWateringSheet> createState() => _RecordWateringSheetState();
}

class _RecordWateringSheetState extends State<RecordWateringSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _duration = TextEditingController();
  final _notes = TextEditingController();
  String? _treeId;
  late DateTime _wateredAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _treeId = widget.treeId;
    final now = DateTime.now();
    _wateredAt = DateTime(now.year, now.month, now.day, now.hour, now.minute);
  }

  @override
  void dispose() {
    _quantity.dispose();
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _wateredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Date watered',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_wateredAt),
      helpText: 'Time watered',
    );
    if (!mounted) return;
    setState(() {
      _wateredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _wateredAt.hour,
        time?.minute ?? _wateredAt.minute,
      );
    });
  }

  String? _validateNumber(
    String? value, {
    required double max,
    bool integer = false,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null; // Optional field.
    final number = integer ? int.tryParse(text) : double.tryParse(text);
    if (number == null) {
      return integer ? 'Enter whole minutes' : 'Enter a number';
    }
    if (number <= 0) return 'Must be greater than 0';
    if (number > max) return 'Must be ${max.toInt()} or less';
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_wateredAt.isAfter(DateTime.now())) {
      AppFeedback.error(context, 'Watering time cannot be in the future.');
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<TreeProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.recordWatering(
        treeId: _treeId!,
        wateredAt: _wateredAt,
        quantityLitres: double.tryParse(_quantity.text.trim()),
        durationMinutes: int.tryParse(_duration.text.trim()),
        notes: _notes.text,
      );
      if (!mounted) return;
      final treeName = provider.treeById(_treeId!)?.name ?? 'tree';
      Navigator.of(context).pop(true);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.water,
          content: Text('Watering recorded for $treeName'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppFeedback.error(context, 'Could not save watering record: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final trees = context.watch<TreeProvider>().trees.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final fixedTree = widget.treeId == null
        ? null
        : context.read<TreeProvider>().treeById(widget.treeId!);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.waterBg,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                    child: const Icon(Icons.water_drop, color: AppColors.water),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      fixedTree == null
                          ? 'Record watering'
                          : 'Record watering · ${fixedTree.name}',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Logs that the tree was watered. It does not control any irrigation device.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              if (fixedTree == null) ...[
                DropdownButtonFormField<String>(
                  initialValue: _treeId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tree *',
                    prefixIcon: Icon(Icons.park_outlined),
                  ),
                  items: [
                    for (final tree in trees)
                      DropdownMenuItem(
                        value: tree.id,
                        child: Text(
                          '${tree.name} · ${tree.species}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _treeId = value),
                  validator: (value) =>
                      value == null ? 'Please choose a tree' : null,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date and time *',
                    prefixIcon: Icon(Icons.schedule),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(Formatters.dateTime(_wateredAt)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantity,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        suffixText: 'litres',
                      ),
                      validator: (v) => _validateNumber(v, max: 1000),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _duration,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        suffixText: 'min',
                      ),
                      validator: (v) =>
                          _validateNumber(v, max: 600, integer: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notes,
                maxLines: 2,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: AppColors.water),
                icon: const Icon(Icons.check),
                label: const Text('Save watering record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
