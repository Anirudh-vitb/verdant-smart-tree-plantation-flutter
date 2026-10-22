import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tree.dart';
import '../../models/tree_query.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/health_status_badge.dart';
import '../../widgets/tree_card.dart';
import 'tree_actions.dart';

/// List of all trees with search, health filter and sorting.
class TreesScreen extends StatefulWidget {
  const TreesScreen({super.key});

  @override
  State<TreesScreen> createState() => _TreesScreenState();
}

class _TreesScreenState extends State<TreesScreen> {
  final _searchController = TextEditingController();
  TreeQuery _query = const TreeQuery();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _update({
    String? search,
    HealthStatus? health,
    bool clearHealth = false,
    TreeSort? sort,
  }) {
    setState(() {
      _query = TreeQuery(
        search: search ?? _query.search,
        health: clearHealth ? null : health ?? _query.health,
        sort: sort ?? _query.sort,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TreeProvider>();
    final allTrees = provider.trees;
    final trees = provider.query(_query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trees'),
        actions: [
          PopupMenuButton<TreeSort>(
            tooltip: 'Sort trees',
            icon: const Icon(Icons.sort),
            initialValue: _query.sort,
            onSelected: (sort) => _update(sort: sort),
            itemBuilder: (context) => [
              for (final sort in TreeSort.values)
                CheckedPopupMenuItem(
                  value: sort,
                  checked: sort == _query.sort,
                  child: Text(sort.label),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-trees',
        onPressed: () => TreeActions.openAddForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add tree'),
      ),
      body: allTrees.isEmpty
          ? EmptyState(
              icon: Icons.park_outlined,
              title: 'No trees yet',
              message: 'Add the first tree planted in your drive to start tracking its health.',
              actionLabel: 'Add a tree',
              onAction: () => TreeActions.openAddForm(context),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search by name or species',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.search.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _update(search: '');
                              },
                            ),
                    ),
                    onChanged: (value) => _update(search: value),
                  ),
                ),
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    children: [
                      _FilterChip(
                        label: 'All (${allTrees.length})',
                        selected: _query.health == null,
                        onSelected: () => _update(clearHealth: true),
                      ),
                      for (final status in HealthStatus.values)
                        _FilterChip(
                          label:
                              '${status.label} (${allTrees.where((t) => t.health == status).length})',
                          selected: _query.health == status,
                          color: status.foreground,
                          background: status.background,
                          onSelected: () => _update(health: status),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: trees.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off,
                          title: 'No matching trees',
                          message:
                              'Try a different search term or health filter.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.xs,
                            AppSpacing.md,
                            96,
                          ),
                          itemCount: trees.length + 1,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Text(
                                '${trees.length} of ${allTrees.length} trees · ${_query.sort.label}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textMuted),
                              );
                            }
                            final tree = trees[index - 1];
                            return TreeCard(
                              tree: tree,
                              lastWatered: provider.lastWatered(tree.id),
                              onTap: () =>
                                  TreeActions.openDetails(context, tree.id),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
    this.background,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: background ?? AppColors.leafSoft,
        side: BorderSide(
          color: selected ? (color ?? AppColors.forest) : AppColors.outline,
        ),
        labelStyle: TextStyle(
          color: selected ? (color ?? AppColors.forest) : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
