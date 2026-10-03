import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryApi implements ItemRepository {
  final http.Client? client;
  String? sourceNote;
  ItemRepositoryApi({this.client});
  Future<dynamic> _fetch(String url) async {
    final response =
        await (client?.get(Uri.parse(url)) ?? http.get(Uri.parse(url)))
            .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('โหลดสินค้าไม่สำเร็จ (สถานะ ${response.statusCode})');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  @override
  Future<List<Item>> getItems() async {
    sourceNote = null;
    try {
      final data = await _fetch('https://fakestoreapi.com/products');
      if (data is! List) throw const FormatException();
      return data.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Keep the lab API as primary; identify the live fallback in the UI.
      try {
        final data = await _fetch('https://dummyjson.com/products?limit=20');
        final products = data['products'] as List;
        final items = products
            .map((e) => Item.fromJson({
                  'id': e['id'],
                  'title': e['title'],
                  'price': e['price'],
                  'description': e['description'],
                  'category': e['category'],
                  'image': e['thumbnail'],
                }))
            .toList();
        sourceNote =
            'ข้อมูลจาก DummyJSON (API สำรอง — Fake Store ไม่พร้อมใช้งาน)';
        return items;
      } on TimeoutException {
        throw Exception('การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง');
      } on http.ClientException {
        throw Exception(
            'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ');
      } on FormatException {
        throw Exception('ข้อมูลสินค้าไม่ถูกต้อง กรุณาลองใหม่');
      }
    }
  }
}
