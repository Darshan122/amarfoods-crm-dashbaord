/// Official Export Product Catalog for Amar Foods
/// Contains all 47 commercial dehydrated alliums, vegetable powders, spices & seeds with HSN codes.
class CatalogProduct {
  final int srNo;
  final String id;
  final String name;
  final String hsnCode;
  final String category;
  final String standardPacking;
  final String description;

  const CatalogProduct({
    required this.srNo,
    required this.id,
    required this.name,
    required this.hsnCode,
    required this.category,
    this.standardPacking = '20 kg / 25 kg Bag',
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
    'srNo': srNo,
    'id': id,
    'name': name,
    'hsnCode': hsnCode,
    'category': category,
    'standardPacking': standardPacking,
    'description': description,
  };

  factory CatalogProduct.fromJson(Map<String, dynamic> json) => CatalogProduct(
    srNo: json['srNo'] ?? 0,
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    hsnCode: json['hsnCode'] ?? '',
    category: json['category'] ?? 'General',
    standardPacking: json['standardPacking'] ?? '20 kg Bag',
    description: json['description'] ?? '',
  );
}

class AmarFoodsCatalog {
  static const List<CatalogProduct> products = [
    // ─── WHITE ONION ──────────────────────────────────────────────────────────
    CatalogProduct(
      srNo: 1,
      id: 'AF-01',
      name: 'Dehydrated White Onion Flakes',
      hsnCode: '07122000',
      category: 'Dehydrated White Onion',
      standardPacking: '14 kg Bag',
      description: 'A-Grade Optical Sorted / Commercial Grade',
    ),
    CatalogProduct(
      srNo: 2,
      id: 'AF-02',
      name: 'Dehydrated White Onion Chopped',
      hsnCode: '07122000',
      category: 'Dehydrated White Onion',
      standardPacking: '20 kg Bag',
      description: '3 - 5 mm (Export Quality)',
    ),
    CatalogProduct(
      srNo: 3,
      id: 'AF-03',
      name: 'Dehydrated White Onion Minced',
      hsnCode: '07122000',
      category: 'Dehydrated White Onion',
      standardPacking: '20 kg Bag',
      description: '1 - 3 mm (Export Quality)',
    ),
    CatalogProduct(
      srNo: 4,
      id: 'AF-04',
      name: 'Dehydrated White Onion Granules',
      hsnCode: '07122000',
      category: 'Dehydrated White Onion',
      standardPacking: '25 kg Bag',
      description: '40 - 60 Mesh (Export Quality)',
    ),
    CatalogProduct(
      srNo: 5,
      id: 'AF-05',
      name: 'Dehydrated White Onion Powder',
      hsnCode: '07122000',
      category: 'Dehydrated White Onion',
      standardPacking: '25 kg Bag',
      description: '80 - 100 Mesh (100% Pure & Fine)',
    ),

    // ─── GARLIC ───────────────────────────────────────────────────────────────
    CatalogProduct(
      srNo: 6,
      id: 'AF-06',
      name: 'Dehydrated Garlic Flakes',
      hsnCode: '07129030',
      category: 'Dehydrated Garlic',
      standardPacking: '25 kg Bag',
      description: 'A-Grade Machine Sorted / Commercial',
    ),
    CatalogProduct(
      srNo: 7,
      id: 'AF-07',
      name: 'Dehydrated Garlic Chopped',
      hsnCode: '07129040',
      category: 'Dehydrated Garlic',
      standardPacking: '25 kg Bag',
      description: '3 - 5 mm (Export Quality)',
    ),
    CatalogProduct(
      srNo: 8,
      id: 'AF-08',
      name: 'Dehydrated Garlic Minced',
      hsnCode: '07129040',
      category: 'Dehydrated Garlic',
      standardPacking: '25 kg Bag',
      description: '1 - 3 mm (Export Quality)',
    ),
    CatalogProduct(
      srNo: 9,
      id: 'AF-09',
      name: 'Dehydrated Garlic Granules',
      hsnCode: '07129040',
      category: 'Dehydrated Garlic',
      standardPacking: '25 kg Bag',
      description: '40 - 60 Mesh (Golden White Free Flowing)',
    ),
    CatalogProduct(
      srNo: 10,
      id: 'AF-10',
      name: 'Dehydrated Garlic Powder',
      hsnCode: '07129020',
      category: 'Dehydrated Garlic',
      standardPacking: '25 kg Bag',
      description: '100 Mesh (Pure Aromatic Flavor)',
    ),
    CatalogProduct(
      srNo: 11,
      id: 'AF-11',
      name: 'Black Garlic Powder',
      hsnCode: '07129090*',
      category: 'Dehydrated Garlic',
      standardPacking: '20 kg / 25 kg Bag',
      description: 'Aged Fermented Black Garlic Powder (Rich Umami)',
    ),

    // ─── RED ONION ────────────────────────────────────────────────────────────
    CatalogProduct(
      srNo: 12,
      id: 'AF-12',
      name: 'Dehydrated Red Onion Flakes',
      hsnCode: '07122000',
      category: 'Dehydrated Red Onion',
      standardPacking: '14 kg Bag',
      description: 'A-Grade Optical Sorted / Domestic',
    ),
    CatalogProduct(
      srNo: 13,
      id: 'AF-13',
      name: 'Dehydrated Red Onion Chopped',
      hsnCode: '07122000',
      category: 'Dehydrated Red Onion',
      standardPacking: '20 kg Bag',
      description: '3 - 5 mm (Export Quality)',
    ),
    CatalogProduct(
      srNo: 14,
      id: 'AF-14',
      name: 'Dehydrated Red Onion Minced',
      hsnCode: '07122000',
      category: 'Dehydrated Red Onion',
      standardPacking: '20 kg Bag',
      description: '1 - 3 mm (Export Quality)',
    ),
    CatalogProduct(
      srNo: 15,
      id: 'AF-15',
      name: 'Dehydrated Red Onion Granules',
      hsnCode: '07122000',
      category: 'Dehydrated Red Onion',
      standardPacking: '25 kg Bag',
      description: '40 - 60 Mesh (Free Flowing)',
    ),
    CatalogProduct(
      srNo: 16,
      id: 'AF-16',
      name: 'Dehydrated Red Onion Powder',
      hsnCode: '07122000',
      category: 'Dehydrated Red Onion',
      standardPacking: '25 kg Bag',
      description: '80 - 100 Mesh (Deep Natural Red)',
    ),

    // ─── PINK ONION ───────────────────────────────────────────────────────────
    CatalogProduct(
      srNo: 17,
      id: 'AF-17',
      name: 'Dehydrated Pink Onion Flakes',
      hsnCode: '07122000',
      category: 'Dehydrated Pink Onion',
      standardPacking: '14 kg Bag',
      description: 'A-Grade Optical Sorted / Domestic',
    ),
    CatalogProduct(
      srNo: 18,
      id: 'AF-18',
      name: 'Dehydrated Pink Onion Chopped',
      hsnCode: '07122000',
      category: 'Dehydrated Pink Onion',
      standardPacking: '20 kg Bag',
      description: '3 - 5 mm (Export Quality)',
    ),
    CatalogProduct(
      srNo: 19,
      id: 'AF-19',
      name: 'Dehydrated Pink Onion Minced',
      hsnCode: '07122000',
      category: 'Dehydrated Pink Onion',
      standardPacking: '20 kg Bag',
      description: '1 - 3 mm (Export Quality)',
    ),
    CatalogProduct(
      srNo: 20,
      id: 'AF-20',
      name: 'Pink Onion Granules',
      hsnCode: '07122000',
      category: 'Dehydrated Pink Onion',
      standardPacking: '25 kg Bag',
      description: '40 - 60 Mesh (Free Flowing)',
    ),
    CatalogProduct(
      srNo: 21,
      id: 'AF-21',
      name: 'Dehydrated Pink Onion Powder',
      hsnCode: '07122000',
      category: 'Dehydrated Pink Onion',
      standardPacking: '25 kg Bag',
      description: '80 - 100 Mesh (100% Pure Pink Onion)',
    ),

    // ─── VEGETABLE & ROOT POWDERS ─────────────────────────────────────────────
    CatalogProduct(
      srNo: 22,
      id: 'AF-22',
      name: 'Pure Ginger Powder (Sonth)',
      hsnCode: '09101210',
      category: 'Vegetables & Roots',
      standardPacking: '25 kg Bag',
      description: 'High Gingerol, Hot & Pungent',
    ),
    CatalogProduct(
      srNo: 23,
      id: 'AF-23',
      name: 'Dehydrated Beetroot Powder',
      hsnCode: '07129090*',
      category: 'Vegetables & Roots',
      standardPacking: '20 kg Bag',
      description: 'Natural Vibrant Red Food Coloring & Nutrient Rich',
    ),
    CatalogProduct(
      srNo: 24,
      id: 'AF-24',
      name: 'Dehydrated Carrot Powder',
      hsnCode: '07129090*',
      category: 'Vegetables & Roots',
      standardPacking: '20 kg Bag',
      description: 'Natural Orange, Beta-Carotene Rich',
    ),
    CatalogProduct(
      srNo: 25,
      id: 'AF-25',
      name: 'Sweet Potato Powder',
      hsnCode: '11062090*',
      category: 'Vegetables & Roots',
      standardPacking: '25 kg Bag',
      description: 'Pure Ground Dehydrated Sweet Potato',
    ),
    CatalogProduct(
      srNo: 26,
      id: 'AF-26',
      name: 'Moringa Leaf Powder',
      hsnCode: '12119099*',
      category: 'Leaves & Herbs',
      standardPacking: '20 kg Bag',
      description: 'Superfood Grade Organic/Conventional Moringa Oleifera',
    ),
    CatalogProduct(
      srNo: 27,
      id: 'AF-27',
      name: 'Dehydrated Spinach Powder (Palak)',
      hsnCode: '07129090*',
      category: 'Leaves & Herbs',
      standardPacking: '20 kg Bag',
      description: 'Natural Green Spinach Fine Powder',
    ),
    CatalogProduct(
      srNo: 28,
      id: 'AF-28',
      name: 'Dehydrated Mint Powder (Pudina)',
      hsnCode: '12119070',
      category: 'Leaves & Herbs',
      standardPacking: '15 kg / 20 kg Bag',
      description: 'High Menthol Aroma, Pure Dried Mint',
    ),
    CatalogProduct(
      srNo: 29,
      id: 'AF-29',
      name: 'Coriander Leaf Powder (Cilantro)',
      hsnCode: '12119099*',
      category: 'Leaves & Herbs',
      standardPacking: '15 kg / 20 kg Bag',
      description: 'Fresh Green Cilantro Powder for Seasonings',
    ),
    CatalogProduct(
      srNo: 30,
      id: 'AF-30',
      name: 'Curry Leaf Powder (Kadi Patta)',
      hsnCode: '12119099*',
      category: 'Leaves & Herbs',
      standardPacking: '15 kg / 20 kg Bag',
      description: 'Aromatic Dried Curry Leaves Powder',
    ),
    CatalogProduct(
      srNo: 31,
      id: 'AF-31',
      name: 'Kasuri Methi (Dried Fenugreek Leaves)',
      hsnCode: '09109990*',
      category: 'Leaves & Herbs',
      standardPacking: '10 kg / 15 kg Box',
      description: 'Fragrant Green Kasuri Methi (Optical Cleaned)',
    ),

    // ─── CHILLI & FRUIT POWDERS ───────────────────────────────────────────────
    CatalogProduct(
      srNo: 32,
      id: 'AF-32',
      name: 'Dehydrated Green Chilli Powder',
      hsnCode: '09042211',
      category: 'Chilli & Spices',
      standardPacking: '20 kg Bag',
      description: 'Sharp Pungent Green Chilli Powder',
    ),
    CatalogProduct(
      srNo: 33,
      id: 'AF-33',
      name: 'Premium Red Chilli Powder',
      hsnCode: '09042211',
      category: 'Chilli & Spices',
      standardPacking: '25 kg Bag',
      description: 'Stemless Pure Red Chilli (Low/Medium/High SHU)',
    ),
    CatalogProduct(
      srNo: 34,
      id: 'AF-34',
      name: 'Dry Mango Powder (Amchur)',
      hsnCode: '11063030*',
      category: 'Fruit Powders',
      standardPacking: '25 kg Bag',
      description: 'Pure Sour Tangy Green Raw Mango Powder',
    ),
    CatalogProduct(
      srNo: 35,
      id: 'AF-35',
      name: 'Spray-Dried Tomato Powder',
      hsnCode: '07129090*',
      category: 'Fruit Powders',
      standardPacking: '20 kg Bag / Carton',
      description: '100% Soluble Rich Red Tomato Powder',
    ),
    CatalogProduct(
      srNo: 36,
      id: 'AF-36',
      name: 'Natural Lemon Powder',
      hsnCode: '11063090*',
      category: 'Fruit Powders',
      standardPacking: '20 kg Bag',
      description: 'Spray Dried Citrus Lemon Flavor',
    ),
    CatalogProduct(
      srNo: 37,
      id: 'AF-37',
      name: 'Pure Tamarind Powder',
      hsnCode: '11063010',
      category: 'Fruit Powders',
      standardPacking: '20 kg Bag',
      description: 'Natural Tart Tamarind Extract Powder',
    ),

    // ─── SPICES & SEEDS ───────────────────────────────────────────────────────
    CatalogProduct(
      srNo: 38,
      id: 'AF-38',
      name: 'Whole Cumin Seeds (Jeera)',
      hsnCode: '09093129',
      category: 'Whole Spices',
      standardPacking: '25 kg / 50 kg Jute or PP Bag',
      description: 'Singapore Quality (99% / 99.5% Machine Cleaned)',
    ),
    CatalogProduct(
      srNo: 39,
      id: 'AF-39',
      name: 'Pure Cumin Powder (Jeera Powder)',
      hsnCode: '09093200',
      category: 'Ground Spices',
      standardPacking: '25 kg Bag',
      description: 'Freshly Ground Aromatic Cumin Powder',
    ),
    CatalogProduct(
      srNo: 40,
      id: 'AF-40',
      name: 'Whole Coriander Seeds (Dhania)',
      hsnCode: '09092190',
      category: 'Whole Spices',
      standardPacking: '20 kg / 25 kg Bag',
      description: 'Eagle / Scooter / Green Quality (Sorted)',
    ),
    CatalogProduct(
      srNo: 41,
      id: 'AF-41',
      name: 'Pure Coriander Powder (Dhania Powder)',
      hsnCode: '09092200',
      category: 'Ground Spices',
      standardPacking: '25 kg Bag',
      description: '100% Pure Coriander Ground Powder',
    ),
    CatalogProduct(
      srNo: 42,
      id: 'AF-42',
      name: 'Whole Turmeric Fingers (Haldi)',
      hsnCode: '09103020',
      category: 'Whole Spices',
      standardPacking: '25 kg / 50 kg Bag',
      description: 'Salem / Nizamabad Polished Fingers (Curcumin 2.5% - 4.5%)',
    ),
    CatalogProduct(
      srNo: 43,
      id: 'AF-43',
      name: 'Pure Turmeric Powder (Curcumin Rich)',
      hsnCode: '09103030',
      category: 'Ground Spices',
      standardPacking: '25 kg Bag',
      description: 'Microbiologically Tested, High Curcumin (3% - 5%)',
    ),

    // ─── FRIED ONIONS & SESAME ────────────────────────────────────────────────
    CatalogProduct(
      srNo: 44,
      id: 'AF-44',
      name: 'Crispy Fried Onion (Birista)',
      hsnCode: '07122000*',
      category: 'Specialty Onion',
      standardPacking: '10 kg / 15 kg Carton (Vacuum / Nitrogen Flush)',
      description: 'Crisp Golden Brown Fried Shallots/Onions',
    ),
    CatalogProduct(
      srNo: 45,
      id: 'AF-45',
      name: 'Toasted Dehydrated Onion',
      hsnCode: '07122000*',
      category: 'Specialty Onion',
      standardPacking: '20 kg Bag',
      description: 'Gently Roasted Dehydrated Flakes & Granules (Rich Roasted Aroma)',
    ),
    CatalogProduct(
      srNo: 46,
      id: 'AF-46',
      name: 'Natural White Sesame Seeds (Til)',
      hsnCode: '12074090*',
      category: 'Sesame Seeds',
      standardPacking: '25 kg / 50 kg Bag',
      description: '99/1 / 99.9% Purity Machine Cleaned Gujarat Sesame',
    ),
    CatalogProduct(
      srNo: 47,
      id: 'AF-47',
      name: 'Premium Hulled Sesame Seeds (Til)',
      hsnCode: '12074090*',
      category: 'Sesame Seeds',
      standardPacking: '25 kg / 50 kg Paper Bag',
      description: 'Auto-Sortex Mechanically Hulled 99.98% Purity',
    ),
  ];

  static List<String> get categories => [
    'All (47)',
    'Dehydrated White Onion',
    'Dehydrated Garlic',
    'Dehydrated Red Onion',
    'Dehydrated Pink Onion',
    'Vegetables & Roots',
    'Leaves & Herbs',
    'Chilli & Spices',
    'Fruit Powders',
    'Whole Spices',
    'Ground Spices',
    'Specialty Onion',
    'Sesame Seeds',
  ];

  static List<CatalogProduct> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return products;
    return products.where((p) =>
      p.name.toLowerCase().contains(q) ||
      p.hsnCode.toLowerCase().contains(q) ||
      p.category.toLowerCase().contains(q) ||
      p.description.toLowerCase().contains(q)
    ).toList();
  }

  static List<CatalogProduct> filterByCategory(String cat) {
    if (cat.startsWith('All')) return products;
    return products.where((p) => p.category == cat).toList();
  }

  /// Formatted text list of products with HSN codes for copy-pasting to buyers
  static String formatForBuyerMessage({List<int>? selectedSrNos}) {
    final list = selectedSrNos == null
        ? products
        : products.where((p) => selectedSrNos.contains(p.srNo)).toList();

    final buffer = StringBuffer();
    buffer.writeln('📋 *AMAR FOODS — OFFICIAL PRODUCT RANGE & HSN CODES:*');
    for (final p in list) {
      buffer.writeln('• ${p.srNo}. ${p.name} (HSN: ${p.hsnCode}) — ${p.standardPacking}');
    }
    return buffer.toString();
  }
}
