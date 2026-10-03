import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:campus_marketplace_w7/services/gemini_service.dart';
import 'package:campus_marketplace_w7/services/gemini_vision_service.dart';

http.Response reply(Map<String, dynamic> data) =>
    http.Response(jsonEncode(data), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});
void main() {
  test('Vision sends image/schema and parses Thai JSON', () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters.containsKey('key'), false);
      expect(request.headers['x-goog-api-key'], 'test-key');
      final body = jsonDecode(request.body);
      expect(body['contents'][0]['parts'][1]['inlineData']['mimeType'],
          'image/png');
      expect(body['generationConfig']['responseSchema']['required'],
          ['title', 'category', 'description']);
      return reply({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'title': 'หนังสือ',
                    'category': 'หนังสือเรียน',
                    'description': 'ตรวจสอบสภาพก่อนซื้อ'
                  })
                }
              ]
            },
            'finishReason': 'STOP'
          }
        ]
      });
    });
    final service = GeminiVisionService(
        service: GeminiService(client: client, apiKey: 'test-key'));
    final result = await service.analyzeProductImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        prompt: 'test',
        mimeType: 'image/png');
    expect(result['title'], 'หนังสือ');
  });
  for (final payload in [
    {
      'promptFeedback': {'blockReason': 'SAFETY'}
    },
    {
      'candidates': [
        {'finishReason': 'SAFETY'}
      ]
    },
    {'candidates': []},
    {
      'candidates': [
        {
          'content': {'parts': []}
        }
      ]
    },
  ]) {
    test('Handles blocked/empty response ${jsonEncode(payload)}', () async {
      final service = GeminiService(
          apiKey: 'test-key', client: MockClient((_) async => reply(payload)));
      await expectLater(
          service.generateText('test'), throwsA(isA<Exception>()));
    });
  }
  test('Shows quota error', () async {
    final service = GeminiService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response('{}', 429)));
    await expectLater(service.generateText('test'),
        throwsA(predicate((e) => e.toString().contains('429'))));
  });
}
