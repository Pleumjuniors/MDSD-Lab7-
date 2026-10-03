import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:campus_marketplace_w7/screens/sell_item_page.dart';
import 'package:campus_marketplace_w7/services/gemini_service.dart';
import 'package:campus_marketplace_w7/services/gemini_vision_service.dart';

void main() {
  testWidgets('Byte preview, editable AI draft and confirmation reset',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jN1sAAAAASUVORK5CYII=');
    final client = MockClient((request) async {
      final body = jsonDecode(request.body);
      expect(body['contents'][0]['parts'][1]['inlineData']['mimeType'],
          'image/png');
      return http.Response(
          jsonEncode({
            'candidates': [
              {
                'finishReason': 'STOP',
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'title': 'AI title',
                        'category': 'อื่นๆ',
                        'description': 'AI description',
                      })
                    }
                  ]
                },
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    await tester.pumpWidget(MaterialApp(
        home: SellItemPage(
      pickImage: () async =>
          XFile.fromData(bytes, name: 'product.png', mimeType: 'image/png'),
      service: GeminiVisionService(
          service: GeminiService(client: client, apiKey: 'test-key')),
    )));
    await tester.tap(find.text('เลือกรูปภาพสินค้า'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).image, isA<MemoryImage>());
    await tester.tap(find.text('ให้ AI ช่วยแนะนำ'));
    await tester.pumpAndSettle();
    expect(find.text('AI title'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Reviewed title');
    await tester.ensureVisible(find.text('ยืนยันร่างประกาศ'));
    await tester.tap(find.text('ยืนยันร่างประกาศ'));
    await tester.pumpAndSettle();
    expect(find.text('Reviewed title'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(find.text('ยังไม่ได้เลือกรูปสินค้า'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
