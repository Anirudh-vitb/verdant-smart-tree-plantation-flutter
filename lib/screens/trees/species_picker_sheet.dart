import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/species.dart';
import '../../services/species_service.dart';

/// Opens a searchable species list and returns the chosen species.
Future<Species?> showSpeciesPicker(BuildContext context) {
  return showModalBottomSheet<Species>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const SpeciesPickerSheet(),
  );
}

class SpeciesPickerSheet extends StatefulWidget {
  const SpeciesPickerSheet({super.key});

  @override
  State<SpeciesPickerSheet> createState() => _SpeciesPickerSheetState();
}

class _SpeciesPickerSheetState extends State<SpeciesPickerSheet> {
  final _search = TextEditingController();
  List<Species>? _onlineResults;
  String? _onlineMessage;
  bool _loading = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _searchOnline() async {
    final service = context.read<SpeciesService>();
    setState(() {
      _loading = true;
      _onlineMessage = null;
    });
    final result = await service.searchOnline(_search.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _onlineMessage = result.message;
      _onlineResults = result.source == SpeciesSource.gbif
          ? result.species
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<SpeciesService>();
    final query = _search.text.trim();
    final results = _onlineResults ?? service.searchLocal(query);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose species', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _search,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Search common or scientific name',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {
                      _onlineResults = null;
                      _onlineMessage = null;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _onlineResults != null
                              ? 'Results from GBIF (online)'
                              : 'Offline catalogue · ${results.length} species',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _loading ? null : _searchOnline,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.travel_explore, size: 18),
                        label: const Text('Search online'),
                      ),
                    ],
                  ),
                  if (_onlineMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        _onlineMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.attentionFg,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  if (query.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: Text('Use "$query"'),
                      subtitle: const Text(
                        'Enter a species that is not listed',
                      ),
                      onTap: () => Navigator.of(context)
                          .pop(Species(commonName: query, scientificName: '')),
                    ),
                  for (final species in results)
                    ListTile(
                      leading: const Icon(
                        Icons.park_outlined,
                        color: AppColors.forest,
                      ),
                      title: Text(species.commonName),
                      subtitle: Text(
                        [
                          if (species.scientificName != species.commonName)
                            species.scientificName,
                          if (species.family != null) species.family!,
                        ].join(' · '),
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      onTap: () => Navigator.of(context).pop(species),
                    ),
                  if (results.isEmpty && query.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('No species available.'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
