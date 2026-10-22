import 'tree.dart';

enum TreeSort {
  recentlyAdded('Recently added'),
  nameAsc('Name (A–Z)'),
  plantedNewest('Planting date (newest)'),
  plantedOldest('Planting date (oldest)');

  const TreeSort(this.label);

  final String label;
}

/// Search, filter and sort options for the tree list.
///
/// Kept as plain Dart (no Flutter) so the logic is easy to unit test.
class TreeQuery {
  const TreeQuery({
    this.search = '',
    this.health,
    this.sort = TreeSort.recentlyAdded,
  });

  final String search;

  /// Null means "all statuses".
  final HealthStatus? health;
  final TreeSort sort;

  List<Tree> apply(Iterable<Tree> trees) {
    final term = search.trim().toLowerCase();
    final result = trees.where((tree) {
      if (health != null && tree.health != health) return false;
      if (term.isEmpty) return true;
      return tree.name.toLowerCase().contains(term) ||
          tree.species.toLowerCase().contains(term) ||
          (tree.scientificName?.toLowerCase().contains(term) ?? false);
    }).toList();

    switch (sort) {
      case TreeSort.recentlyAdded:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TreeSort.nameAsc:
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case TreeSort.plantedNewest:
        result.sort((a, b) => b.plantedOn.compareTo(a.plantedOn));
      case TreeSort.plantedOldest:
        result.sort((a, b) => a.plantedOn.compareTo(b.plantedOn));
    }
    return result;
  }
}
