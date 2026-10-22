import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/species_catalogue.dart';
import '../models/species.dart';

/// Result of a species search, including where the data came from.
class SpeciesSearchResult {
  const SpeciesSearchResult({
    required this.species,
    required this.source,
    this.message,
  });

  final List<Species> species;
  final SpeciesSource source;

  /// Explains a fallback (for example "You appear to be offline").
  final String? message;
}

/// Contract used by the UI. Screens never talk to HTTP directly.
abstract class SpeciesService {
  /// Searches the bundled offline catalogue. Always available.
  List<Species> searchLocal(String query);

  /// Searches an online source, falling back to [searchLocal] on failure.
  Future<SpeciesSearchResult> searchOnline(String query);
}

/// Offline-only implementation used when online lookup is not wanted.
class LocalSpeciesService implements SpeciesService {
  const LocalSpeciesService();

  @override
  List<Species> searchLocal(String query) =>
      localSpeciesCatalogue.where((s) => s.matches(query)).toList();

  @override
  Future<SpeciesSearchResult> searchOnline(String query) async {
    return SpeciesSearchResult(
      species: searchLocal(query),
      source: SpeciesSource.local,
      message: 'Online search is disabled. Showing the offline catalogue.',
    );
  }
}

/// Looks up plant species names in the free GBIF Species API
/// (https://api.gbif.org/v1/species/suggest). No API key is required.
///
/// Any network error, timeout or unexpected response falls back to the
/// offline catalogue, so the form keeps working without internet.
class GbifSpeciesService extends LocalSpeciesService {
  GbifSpeciesService({
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  static const String _host = 'api.gbif.org';
  static const String _path = '/v1/species/suggest';

  @override
  Future<SpeciesSearchResult> searchOnline(String query) async {
    final term = query.trim();
    if (term.length < 3) {
      return SpeciesSearchResult(
        species: searchLocal(term),
        source: SpeciesSource.local,
        message: 'Type at least 3 letters to search online.',
      );
    }

    final uri = Uri.https(_host, _path, {
      'q': term,
      'rank': 'SPECIES',
      'limit': '20',
    });

    try {
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode != 200) {
        return _fallback(
          term,
          'Online service returned ${response.statusCode}.',
        );
      }
      final species = parseSuggestResponse(response.body);
      if (species.isEmpty) {
        return _fallback(term, 'No online matches found.');
      }
      return SpeciesSearchResult(species: species, source: SpeciesSource.gbif);
    } on TimeoutException {
      return _fallback(term, 'Online search timed out.');
    } on FormatException {
      return _fallback(term, 'Online service sent an unexpected response.');
    } catch (_) {
      // SocketException / ClientException when offline.
      return _fallback(term, 'Could not reach the online service.');
    }
  }

  SpeciesSearchResult _fallback(String term, String reason) {
    return SpeciesSearchResult(
      species: searchLocal(term),
      source: SpeciesSource.local,
      message: '$reason Showing the offline catalogue instead.',
    );
  }

  /// Parses GBIF's suggest response (a JSON array of name usages), keeping
  /// only plant species with a usable name.
  static List<Species> parseSuggestResponse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON array');
    }
    final seen = <String>{};
    final result = <Species>[];
    for (final item in decoded.whereType<Map>()) {
      final kingdom = item['kingdom'];
      if (kingdom is String && kingdom != 'Plantae') continue;
      final name = (item['canonicalName'] ?? item['scientificName']);
      if (name is! String || name.trim().isEmpty) continue;
      if (!seen.add(name.toLowerCase())) continue;
      final family = item['family'];
      result.add(
        Species(
          commonName: name,
          scientificName: name,
          family: family is String ? family : null,
          source: SpeciesSource.gbif,
        ),
      );
    }
    return result;
  }
}
