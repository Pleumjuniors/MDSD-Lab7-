import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Common transport for text and image requests. Secrets never appear in URLs.
class GeminiService {
  final http.Client? client;
  final String apiKey;
  final String model;
  GeminiService({
    this.client,
    this.apiKey = const String.fromEnvironment('GEMINI_API_KEY'),
    this.model = const String.fromEnvironment('GEMINI_MODEL',
        defaultValue: 'gemini-3.5-flash-lite'),
  });

  Future<String> generateText(String prompt) => generate(parts: [
        {'text': prompt}
      ]);

  Future<String> generate(
      {required List<Map<String, dynamic>> parts,
      Map<String, dynamic>? schema}) async {
    if (apiKey.trim().isEmpty) {
      throw Exception(
          'ไม่พบ GEMINI_API_KEY กรุณารันด้วย --dart-define=GEMINI_API_KEY=YOUR_API_KEY');
    }
    final ownedClient = client ?? http.Client();
    try {
      final response = await ownedClient
          .post(
            Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent'),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey
            },
            body: jsonEncode({
              'contents': [
                {'parts': parts}
              ],
              'generationConfig': {
                'maxOutputTokens': 4096,
                if (schema != null) 'responseMimeType': 'application/json',
                if (schema != null) 'responseSchema': schema,
              },
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        final message = switch (response.statusCode) {
          400 => 'คำขอหรือ API key ไม่ถูกต้อง',
          401 || 403 => 'API key ไม่มีสิทธิ์ใช้งาน กรุณาตรวจสอบคีย์',
          404 => 'ไม่พบโมเดล Gemini กรุณาตรวจสอบ GEMINI_MODEL',
          429 => 'ใช้งานเกินโควตา กรุณารอสักครู่แล้วลองใหม่',
          503 => 'Gemini มีปริมาณการใช้งานสูง กรุณาลองใหม่ภายหลัง',
          _ => 'เรียก Gemini API ไม่สำเร็จ',
        };
        throw Exception('$message (สถานะ ${response.statusCode})');
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) throw const FormatException();
      final feedback = data['promptFeedback'];
      if (feedback is Map && feedback['blockReason'] != null) {
        throw Exception('คำขอถูกบล็อกโดยระบบความปลอดภัยของ Gemini');
      }
      final candidates = data['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        throw Exception(
            'AI ไม่ส่งผลลัพธ์กลับมา อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม');
      }
      final candidate = candidates.first;
      if (candidate is! Map) throw const FormatException();
      final reason = candidate['finishReason'];
      if (['SAFETY', 'PROHIBITED_CONTENT', 'BLOCKLIST', 'SPII', 'IMAGE_SAFETY']
          .contains(reason)) {
        throw Exception('เนื้อหาถูกบล็อกโดยระบบความปลอดภัยของ Gemini');
      }
      if (reason == 'MAX_TOKENS') {
        throw Exception('คำตอบ AI ถูกตัด กรุณาลองใหม่ด้วยคำบรรยายสั้นลง');
      }
      final content = candidate['content'];
      final responseParts = content is Map ? content['parts'] : null;
      if (responseParts is! List) throw const FormatException();
      final text = responseParts
          .whereType<Map>()
          .where((p) => p['thought'] != true && p['text'] is String)
          .map((p) => p['text'] as String)
          .join()
          .trim();
      if (text.isEmpty) throw const FormatException();
      return text;
    } on TimeoutException {
      throw Exception('Gemini ใช้เวลานานเกิน 20 วินาที กรุณาลองใหม่');
    } on http.ClientException {
      throw Exception('ไม่สามารถเชื่อมต่อ Gemini ได้ กรุณาตรวจสอบอินเทอร์เน็ต');
    } on FormatException {
      throw Exception('ข้อมูลคำตอบจาก Gemini ไม่ถูกต้อง กรุณาลองใหม่');
    } finally {
      if (client == null) ownedClient.close();
    }
  }
}
