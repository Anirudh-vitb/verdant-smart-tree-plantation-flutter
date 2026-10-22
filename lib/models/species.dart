/// Where a species suggestion came from.
enum SpeciesSource { local, gbif }

/// A tree species that can be chosen when adding a tree.
class Species {
  const Species({
    required this.commonName,
    required this.scientificName,
    this.family,
    this.source = SpeciesSource.local,
  });

  final String commonName;
  final String scientificName;
  final String? family;
  final SpeciesSource source;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return commonName.toLowerCase().contains(q) ||
        scientificName.toLowerCase().contains(q) ||
        (family?.toLowerCase().contains(q) ?? false);
  }
}
