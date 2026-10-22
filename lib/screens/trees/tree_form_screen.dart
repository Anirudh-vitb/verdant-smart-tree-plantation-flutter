import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/tree.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/health_status_badge.dart';
import 'species_picker_sheet.dart';

/// Add a new tree, or edit [existing] when provided.
class TreeFormScreen extends StatefulWidget {
  const TreeFormScreen({super.key, this.existing});

  final Tree? existing;

  bool get isEditing => existing != null;

  @override
  State<TreeFormScreen> createState() => _TreeFormScreenState();
}

class _TreeFormScreenState extends State<TreeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  String? _species;
  String? _scientificName;
  DateTime? _plantedOn;
  late HealthStatus _health;
  bool _saving = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    final tree = widget.existing;
    _name = TextEditingController(text: tree?.name ?? '');
    _location = TextEditingController(text: tree?.location ?? '');
    _notes = TextEditingController(text: tree?.notes ?? '');
    _species = tree?.species;
    _scientificName = tree?.scientificName;
    _plantedOn = tree?.plantedOn ?? Formatters.dateOnly(DateTime.now());
    _health = tree?.health ?? HealthStatus.healthy;
    for (final c in [_name, _location, _notes]) {
      c.addListener(_onChanged);
    }
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _isDirty {
    final tree = widget.existing;
    if (tree == null) {
      return _name.text.trim().isNotEmpty ||
          _location.text.trim().isNotEmpty ||
          _notes.text.trim().isNotEmpty ||
          _species != null ||
          _health != HealthStatus.healthy;
    }
    return _name.text.trim() != tree.name ||
        _location.text.trim() != tree.location ||
        _notes.text.trim() != tree.notes ||
        _species != tree.species ||
        _plantedOn != tree.plantedOn ||
        _health != tree.health;
  }

  Future<void> _pickSpecies() async {
    final picked = await showSpeciesPicker(context);
    if (picked == null) return;
    setState(() {
      _species = picked.commonName;
      _scientificName = picked.scientificName.isEmpty
          ? null
          : picked.scientificName;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final provider = context.read<TreeProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final existing = widget.existing;
      if (existing == null) {
        await provider.addTree(
          name: _name.text,
          species: _species!,
          scientificName: _scientificName,
          plantedOn: _plantedOn!,
          location: _location.text,
          health: _health,
          notes: _notes.text,
        );
      } else {
        await provider.updateTree(
          existing.copyWith(
            name: _name.text.trim(),
            species: _species,
            scientificName: _scientificName,
            clearScientificName: _scientificName == null,
            plantedOn: _plantedOn,
            location: _location.text.trim(),
            health: _health,
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
            widget.isEditing
                ? 'Tree details updated'
                : '"${_name.text.trim()}" added to your plantation',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppFeedback.error(context, 'Could not save the tree: $error');
    }
  }

  Future<void> _cancel() async {
    if (!_isDirty || await AppFeedback.confirmDiscard(context)) {
      if (!mounted) return;
      _allowPop = true;
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return PopScope(
      canPop: _allowPop || !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit tree' : 'Add a tree'),
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
                  title: 'Tree details',
                  children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Tree name *',
                        hintText: 'e.g. Library Mango',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Please enter a name for the tree';
                        }
                        if (text.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _SpeciesField(
                      species: _species,
                      scientificName: _scientificName,
                      onTap: _pickSpecies,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DatePickerField(
                      label: 'Planting date *',
                      value: _plantedOn,
                      firstDate: DateTime(1950),
                      lastDate: now,
                      onChanged: (date) => setState(() => _plantedOn = date),
                      validator: (value) {
                        if (value == null) {
                          return 'Please choose the planting date';
                        }
                        if (value.isAfter(now)) {
                          return 'Planting date cannot be in the future';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                FormSection(
                  title: 'Location & health',
                  children: [
                    TextFormField(
                      controller: _location,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Plantation location *',
                        hintText: 'e.g. Library lawn, north side',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Please enter where the tree is planted'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Health status *',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final status in HealthStatus.values)
                          ChoiceChip(
                            label: Text(status.label),
                            avatar: Icon(
                              status.icon,
                              size: 18,
                              color: status.foreground,
                            ),
                            selected: _health == status,
                            showCheckmark: false,
                            selectedColor: status.background,
                            side: BorderSide(
                              color: _health == status
                                  ? status.foreground
                                  : AppColors.outline,
                            ),
                            onSelected: (_) => setState(() => _health = status),
                          ),
                      ],
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
                        hintText: 'Soil condition, tree guard, who planted it…',
                        alignLabelWithHint: true,
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
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          widget.isEditing ? 'Save changes' : 'Save tree',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeciesField extends StatelessWidget {
  const _SpeciesField({
    required this.species,
    required this.scientificName,
    required this.onTap,
  });

  final String? species;
  final String? scientificName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: ValueKey(species),
      initialValue: species,
      validator: (value) => (value == null || value.trim().isEmpty)
          ? 'Please select a species'
          : null,
      builder: (state) => Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          child: InputDecorator(
            isEmpty: species == null,
            decoration: InputDecoration(
              labelText: 'Species *',
              prefixIcon: const Icon(Icons.eco_outlined),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              errorText: state.errorText,
            ),
            child: species == null
                ? const SizedBox.shrink()
                : Text(
                    scientificName == null || scientificName == species
                        ? species!
                        : '$species ($scientificName)',
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ),
      ),
    );
  }
}
