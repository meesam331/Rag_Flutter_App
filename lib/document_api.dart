import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DocumentApiException implements Exception {
  const DocumentApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DocumentApi {
  DocumentApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? _apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  static String get _apiBaseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) return configuredUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://127.0.0.1:5000';
  }

  Future<String> upload(PlatformFile file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload'),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: file.name,
      ),
    );
    final streamedResponse = await _client
        .send(request)
        .timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);
    final data = _decode(response);
    return data['name'] as String;
  }

  Future<String> ask(String question) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/ask'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'question': question}),
        )
        .timeout(const Duration(seconds: 60));
    final data = _decode(response);
    final answer = data['answer'] as String;
    final sources = data['sources'] as List<dynamic>? ?? [];
    if (sources.isEmpty) return answer;
    return '$answer\n\nSources: ${sources.join(', ')}';
  }

  Map<String, dynamic> _decode(http.Response response) {
    final Object? body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DocumentApiException(
          'Server error (HTTP ${response.statusCode}).',
        );
      }
      throw const DocumentApiException(
        'The server returned an invalid response.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body is Map<String, dynamic> ? body['error'] : null;
      throw DocumentApiException(
        error is String ? error : 'Server error (HTTP ${response.statusCode}).',
      );
    }
    if (body is! Map<String, dynamic>) {
      throw const DocumentApiException(
        'The server returned an invalid response.',
      );
    }
    return body;
  }

  void close() => _client.close();
}
