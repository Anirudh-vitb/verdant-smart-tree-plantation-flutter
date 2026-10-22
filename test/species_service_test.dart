import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:verdant_smart_tree_plantation_flutter/models/species.dart';
import 'package:verdant_smart_tree_plantation_flutter/services/species_service.dart';

void main() {
  group('LocalSpeciesService', () {
    const service = LocalSpeciesService();

    test('returns the whole catalogue for an empty query', () {
      expect(service.searchLocal('').length, greaterThanOrEqualTo(25));
    });

    test('matches common, scientific and family names', () {
      expect(
        service.searchLocal('neem').single.scientificName,
        'Azadirachta indica',
      );
      expect(
        service.searchLocal('ficus').map((s) => s.commonName),
        containsAll(['Peepal', 'Banyan']),
      );
      expect(service.searchLocal('myrtaceae'), isNotEmpty);
    });

    test('online search reports that it is disabled', () async {
      final result = await service.searchOnline('neem');
      expect(result.source, SpeciesSource.local);
      expect(result.message, isNotNull);
    });
  });

  group('GbifSpeciesService', () {
    test(
      'requests the documented suggest endpoint and parses plants',
      () async {
        late Uri requested;
        final client = MockClient((request) async {
          requested = request.url;
          return http.Response(
            jsonEncode([
              {
                'canonicalName': 'Quercus robur',
                'scientificName': 'Quercus robur L.',
                'family': 'Fagaceae',
                'kingdom': 'Plantae',
              },
              {
                'canonicalName': 'Quercus robur',
                'kingdom': 'Plantae',
              }, // Duplicate.
              {
                'canonicalName': 'Querquedula',
                'kingdom': 'Animalia',
              }, // Not a plant.
              {'family': 'NoName'},
            ]),
            200,
          );
        });

        final result = await GbifSpeciesService(client: client)
            .searchOnline('quercus');

        expect(requested.host, 'api.gbif.org');
        expect(requested.path, '/v1/species/suggest');
        expect(requested.queryParameters['q'], 'quercus');
        expect(requested.queryParameters['rank'], 'SPECIES');
        expect(result.source, SpeciesSource.gbif);
        expect(result.species.single.scientificName, 'Quercus robur');
        expect(result.species.single.family, 'Fagaceae');
      },
    );

    test('falls back to the local catalogue on server errors', () async {
      final client = MockClient((_) async => http.Response('error', 503));
      final result = await GbifSpeciesService(client: client)
          .searchOnline('neem');
      expect(result.source, SpeciesSource.local);
      expect(result.species.single.commonName, 'Neem');
      expect(result.message, contains('503'));
    });

    test('falls back when offline', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('offline'),
      );
      final result = await GbifSpeciesService(client: client)
          .searchOnline('mango');
      expect(result.source, SpeciesSource.local);
      expect(result.message, contains('Could not reach'));
    });

    test('falls back on timeout', () async {
      final client = MockClient((_) => Completer<http.Response>().future);
      final result = await GbifSpeciesService(
        client: client,
        timeout: const Duration(milliseconds: 10),
      ).searchOnline('mango');
      expect(result.source, SpeciesSource.local);
      expect(result.message, contains('timed out'));
    });

    test('falls back on malformed JSON', () async {
      final client = MockClient(
        (_) async => http.Response('{"not":"a list"}', 200),
      );
      final result = await GbifSpeciesService(client: client)
          .searchOnline('mango');
      expect(result.source, SpeciesSource.local);
      expect(result.message, contains('unexpected'));
    });

    test('does not call the network for very short queries', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('[]', 200);
      });
      await GbifSpeciesService(client: client).searchOnline('ne');
      expect(calls, 0);
    });
  });
}
