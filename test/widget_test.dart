import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:campus_marketplace_w7/models/cart_model.dart';
import 'package:campus_marketplace_w7/models/item.dart';
import 'package:campus_marketplace_w7/repositories/item_repository.dart';
import 'package:campus_marketplace_w7/screens/main_scaffold.dart';

class FakeRepository implements ItemRepository {
  @override
  Future<List<Item>> getItems() async => [
        const Item(
            id: 1,
            title: 'หนังสือเรียน',
            price: 100,
            description: 'หนังสือ',
            category: 'หนังสือเรียน',
            imageUrl: '')
      ];
}

void main() {
  testWidgets('Home, cart and retained sell tab', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => CartModel(),
        child: MaterialApp(home: MainScaffold(repository: FakeRepository()))));
    await tester.pumpAndSettle();
    expect(find.text('หนังสือเรียน'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_shopping_cart));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.shopping_cart));
    await tester.pumpAndSettle();
    expect(find.text('ตะกร้าสินค้า'), findsOneWidget);
    expect(find.text('รวมทั้งหมด: 100.00 บาท'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลงประกาศขาย').last);
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่ได้เลือกรูปสินค้า'), findsOneWidget);
    expect(find.byType(IndexedStack), findsOneWidget);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'ให้ AI ช่วยแนะนำ'))
            .onPressed,
        isNull);
    expect(tester.takeException(), isNull);
  });
}
