class ListingDraft {
  static const categories = [
    'หนังสือเรียน',
    'อุปกรณ์อิเล็กทรอนิกส์',
    'ของแต่งหอพัก',
    'เสื้อผ้า',
    'อื่นๆ'
  ];
  final String title;
  final String category;
  final String description;
  const ListingDraft(
      {required this.title, required this.category, required this.description});
  factory ListingDraft.fromJson(Map<String, dynamic> json) {
    for (final field in ['title', 'category', 'description']) {
      if (json[field] is! String || (json[field] as String).trim().isEmpty) {
        throw FormatException('Missing or invalid $field');
      }
    }
    if (!categories.contains(json['category'])) {
      throw const FormatException('Invalid category');
    }
    return ListingDraft(
        title: (json['title'] as String).trim(),
        category: (json['category'] as String).trim(),
        description: (json['description'] as String).trim());
  }
}
