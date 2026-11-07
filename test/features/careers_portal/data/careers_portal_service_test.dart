import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/services/careers_portal_service.dart';

void main() {
  group('CareersPortalService reliability', () {
    test('unsupported company completes within the discovery deadline',
        () async {
      final client = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return http.Response('not found', 404);
      });
      final service = CareersPortalService(
        client: client,
        probeTimeout: const Duration(milliseconds: 30),
        discoveryTimeout: const Duration(milliseconds: 80),
      );
      final stopwatch = Stopwatch()..start();

      await expectLater(
        service.fetchJobs('Unsupported Company'),
        throwsA(isA<CareersPortalException>()),
      );
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 500)));
    });

    test('runs ATS and slug probes concurrently instead of sequentially',
        () async {
      var activeRequests = 0;
      var peakRequests = 0;
      final client = MockClient((request) async {
        activeRequests++;
        if (activeRequests > peakRequests) peakRequests = activeRequests;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        activeRequests--;
        return http.Response('not found', 404);
      });
      final service = CareersPortalService(
        client: client,
        probeTimeout: const Duration(milliseconds: 100),
        discoveryTimeout: const Duration(milliseconds: 200),
      );

      await expectLater(
        service.fetchJobs('Example Holdings'),
        throwsA(isA<CareersPortalException>()),
      );

      expect(peakRequests, greaterThan(1));
    });

    test('preserves source diagnostics and official careers fallback URL',
        () async {
      final service = CareersPortalService(
        client: MockClient((request) async {
          if (request.url.host == 'api.lever.co') {
            return http.Response('temporarily unavailable', 503);
          }
          return http.Response('not found', 404);
        }),
        probeTimeout: const Duration(milliseconds: 100),
        discoveryTimeout: const Duration(milliseconds: 300),
      );

      try {
        await service.fetchJobs('Example Company');
        fail('Expected CareersPortalException');
      } on CareersPortalException catch (error) {
        expect(error.diagnostics, isNotEmpty);
        expect(
          error.diagnostics,
          contains(
            isA<CareersSourceDiagnostic>()
                .having((item) => item.source, 'source', 'Lever')
                .having(
                  (item) => item.detail,
                  'detail',
                  contains('503'),
                ),
          ),
        );
        expect(error.officialCareersUrl, isNotNull);
        expect(
          error.officialCareersUrl!.queryParameters['q'],
          'Example Company official careers jobs',
        );
      }
    });

    test('returns jobs from a successful source while other probes fail',
        () async {
      final service = CareersPortalService(
        client: MockClient((request) async {
          if (request.url.host == 'api.lever.co' &&
              request.url.path == '/v0/postings/acme') {
            return http.Response(
              jsonEncode([
                {
                  'id': 'job-1',
                  'text': 'Platform Engineer',
                  'hostedUrl': 'https://jobs.example/job-1',
                  'createdAt': DateTime.now().millisecondsSinceEpoch,
                  'categories': {
                    'department': 'Engineering',
                    'location': 'Remote',
                    'commitment': 'Full-time',
                  },
                },
              ]),
              200,
            );
          }
          return http.Response('not found', 404);
        }),
        probeTimeout: const Duration(milliseconds: 100),
        discoveryTimeout: const Duration(milliseconds: 300),
      );

      final result = await service.fetchJobs('Acme');

      expect(result.platform, AtsPlatform.lever);
      expect(result.companySlug, 'acme');
      expect(result.jobs.single.title, 'Platform Engineer');
    });
  });
}
