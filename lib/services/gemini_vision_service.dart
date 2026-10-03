import 'dart:convert';
import 'dart:typed_data';
import '../models/listing_draft.dart';
import 'gemini_service.dart';

class GeminiVisionService {
  final GeminiService service;
  GeminiVisionService({GeminiService? service})
      : service = service ?? GeminiService();

  Future<Map<String, dynamic>> analyzeProductImage({
    required Uint8List imageBytes,
    required String prompt,
    String mimeType = 'image/jpeg',
  }) async {
    if (imageBytes.isEmpty || imageBytes.length > 10 * 1024 * 1024) {
      throw Exception('กรุณาเลือกรูปภาพขนาดไม่เกิน 10 MB');
    }
    if (!['image/jpeg', 'image/png', 'image/webp'].contains(mimeType)) {
      throw Exception('รองรับเฉพาะรูป JPEG, PNG และ WebP');
    }
    final text = await service.generate(parts: [
      {'text': prompt},
      {
        'inlineData': {'mimeType': mimeType, 'data': base64Encode(imageBytes)}
      },
    ], schema: {
      'type': 'OBJECT',
      'properties': {
        'title': {'type': 'STRING'},
        'category': {'type': 'STRING', 'enum': ListingDraft.categories},
        'description': {'type': 'STRING'},
      },
      'required': ['title', 'category', 'description'],
    });
    try {
      final result = jsonDecode(text);
      if (result is! Map<String, dynamic>) throw const FormatException();
      ListingDraft.fromJson(result);
      return result;
    } on FormatException {
      throw Exception('ร่างประกาศจาก AI ไม่ถูกต้อง กรุณาลองใหม่');
    }
  }
}
