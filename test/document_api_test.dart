import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lab133/document_api.dart';

void main() {
  test('asks the backend and returns its answer', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/ask');
      expect(jsonDecode(request.body), {'question': 'When does it close?'});
      return http.Response(
        jsonEncode({
          'answer': 'It closes at 8 PM.',
          'sources': ['hours.pdf (page 1)'],
        }),
        200,
      );
    });
    final api = DocumentApi(client: client, baseUrl: 'http://localhost:5000');
    addTearDown(api.close);

    expect(
      await api.ask('When does it close?'),
      'It closes at 8 PM.\n\nSources: hours.pdf (page 1)',
    );
  });

  test('shows the HTTP status when the server returns an error page', () async {
    final api = DocumentApi(
      client: MockClient((_) async => http.Response('<html>error</html>', 500)),
      baseUrl: 'http://localhost:5000',
    );
    addTearDown(api.close);

    await expectLater(
      api.ask('A question'),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          'Server error (HTTP 500).',
        ),
      ),
    );
  });
}
