import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/cart_model.dart';
import '../repositories/item_repository.dart';
import '../repositories/item_repository_api.dart';
import '../services/gemini_service.dart';
import 'checkout_page.dart';

class HomePage extends StatefulWidget {
  final ItemRepository repository;
  const HomePage({super.key, required this.repository});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Item>> _itemsFuture;
  bool _isTestingGemini = false;
  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.repository.getItems();
  }

  Future<void> _testGemini() async {
    setState(() => _isTestingGemini = true);
    try {
      final result = await GeminiService().generateText(
          'ช่วยแต่งประโยคทักทายลูกค้าร้านค้าออนไลน์แบบเป็นกันเอง แบ่งเป็น 4 สไตล์ ได้แก่ น่ารักสดใส สุภาพเป็นมิตร ตอบกลับอัตโนมัติ และทักทายนอกเวลาทำการ แต่ละสไตล์มีตัวอย่าง 3 ประโยค ใช้หัวข้อ Markdown และอีโมจิประกอบ');
      debugPrint('GEMINI RESPONSE: $result');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.8),
              child: SingleChildScrollView(child: Text(result))),
          showCloseIcon: true,
          duration: const Duration(minutes: 5)));
    } catch (e) {
      debugPrint('GEMINI ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isTestingGemini = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Campus Marketplace'), actions: [
          IconButton(
              icon: Badge(
                  label: Text('${context.watch<CartModel>().itemCount}'),
                  child: const Icon(Icons.shopping_cart)),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CheckoutPage()))),
        ]),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                      onPressed: _isTestingGemini ? null : _testGemini,
                      icon: _isTestingGemini
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isTestingGemini
                          ? 'กำลังทดสอบ Gemini...'
                          : 'ทดสอบ Gemini API')))),
          Expanded(
              child: FutureBuilder<List<Item>>(
                  future: _itemsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('เกิดข้อผิดพลาด: ${snapshot.error}',
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 12),
                                    OutlinedButton(
                                        onPressed: () => setState(() =>
                                            _itemsFuture =
                                                widget.repository.getItems()),
                                        child: const Text('ลองโหลดสินค้าใหม่')),
                                  ])));
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const Center(child: Text('ไม่พบสินค้า'));
                    }
                    return Column(children: [
                      if (widget.repository is ItemRepositoryApi &&
                          (widget.repository as ItemRepositoryApi).sourceNote !=
                              null)
                        Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                                (widget.repository as ItemRepositoryApi)
                                    .sourceNote!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12))),
                      Expanded(
                          child: ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return ListTile(
                                    leading: Image.network(item.imageUrl,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, error, stack) =>
                                            const Icon(Icons.broken_image)),
                                    title: Text(item.title),
                                    subtitle: Text('${item.price} บาท'),
                                    trailing: IconButton(
                                        icon:
                                            const Icon(Icons.add_shopping_cart),
                                        onPressed: () {
                                          context.read<CartModel>().add(item);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'เพิ่ม "${item.title}" ลงตะกร้าแล้ว')));
                                        }));
                              })),
                    ]);
                  })),
        ]),
      );
}
