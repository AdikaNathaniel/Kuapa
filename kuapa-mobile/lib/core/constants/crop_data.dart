class CropInfo {
  final String name;
  final String asset;
  final List<String> assets;
  final String unit;
  final double basePrice;
  final String category;

  const CropInfo({
    required this.name,
    required this.asset,
    required this.assets,
    required this.unit,
    required this.basePrice,
    required this.category,
  });
}

class CropData {
  CropData._();

  static const String _base = 'assets/images/crops';

  static List<String> _imgs(String cat, String crop, int count) =>
      List.generate(count, (i) => '$_base/$cat/$crop/${crop}_${i + 1}.jpg');

  static const List<CropInfo> all = [
    // Vegetables
    CropInfo(
      name: 'Tomato',
      asset: '$_base/vegetables/tomato/tomato_9.jpg',
      assets: [],
      unit: 'kg',
      basePrice: 8.50,
      category: 'Vegetables',
    ),
    CropInfo(
      name: 'Pepper',
      asset: '$_base/vegetables/pepper/pepper_1.jpg',
      assets: [],
      unit: 'kg',
      basePrice: 12.00,
      category: 'Vegetables',
    ),
    CropInfo(
      name: 'Onion',
      asset: '$_base/vegetables/onion/onion_1.jpg',
      assets: [],
      unit: 'kg',
      basePrice: 6.00,
      category: 'Vegetables',
    ),
    CropInfo(
      name: 'Okra',
      asset: '$_base/vegetables/okra/okra_1.jpg',
      assets: [],
      unit: 'kg',
      basePrice: 10.00,
      category: 'Vegetables',
    ),
    CropInfo(
      name: 'Cabbage',
      asset: '$_base/vegetables/cabbage/cabbage_1.jpg',
      assets: [],
      unit: 'head',
      basePrice: 5.00,
      category: 'Vegetables',
    ),
    CropInfo(
      name: 'Carrot',
      asset: '$_base/vegetables/carrot/carrot_3.jpg',
      assets: [],
      unit: 'kg',
      basePrice: 7.50,
      category: 'Vegetables',
    ),
    CropInfo(
      name: 'Garden Egg',
      asset: '$_base/vegetables/garden_egg/garden_egg_1.jpg',
      assets: [],
      unit: 'kg',
      basePrice: 9.00,
      category: 'Vegetables',
    ),

    // Staples
    CropInfo(
      name: 'Yam',
      asset: '$_base/staples/yam/yam_1.jpg',
      assets: [],
      unit: 'tuber',
      basePrice: 15.00,
      category: 'Staples',
    ),
    CropInfo(
      name: 'Cassava',
      asset: '$_base/staples/cassava/cassava_1.jpg',
      assets: [],
      unit: 'kg',
      basePrice: 4.00,
      category: 'Staples',
    ),
    CropInfo(
      name: 'Plantain',
      asset: '$_base/staples/plantain/plantain_1.jpg',
      assets: [],
      unit: 'bunch',
      basePrice: 20.00,
      category: 'Staples',
    ),
    CropInfo(
      name: 'Maize',
      asset: '$_base/staples/maize/maize_1.jpg',
      assets: [],
      unit: 'kg',
      basePrice: 3.50,
      category: 'Staples',
    ),
    CropInfo(
      name: 'Rice',
      asset: '$_base/staples/rice/rice_1.jpg',
      assets: [],
      unit: 'kg',
      basePrice: 7.00,
      category: 'Staples',
    ),
    CropInfo(
      name: 'Cocoyam',
      asset: '$_base/staples/cocoyam/cocoyam_1.jpg',
      assets: [],
      unit: 'kg',
      basePrice: 6.50,
      category: 'Staples',
    ),
    CropInfo(
      name: 'Sweet Potato',
      asset: '$_base/staples/sweet_potato/sweet_potato_1.jpg',
      assets: [],
      unit: 'kg',
      basePrice: 5.50,
      category: 'Staples',
    ),

    // Legumes
    CropInfo(
      name: 'Groundnut',
      asset: '$_base/legumes/groundnut/groundnut_1.jpg',
      assets: [],
      unit: 'kg',
      basePrice: 18.00,
      category: 'Legumes',
    ),
    CropInfo(
      name: 'Cowpea',
      asset: '$_base/legumes/cowpea/cowpea_1.jpg',
      assets: [],
      unit: 'kg',
      basePrice: 14.00,
      category: 'Legumes',
    ),

    // Fruits
    CropInfo(
      name: 'Mango',
      asset: '$_base/fruits/mango/mango_1.jpg',
      assets: [],
      unit: 'kg',
      basePrice: 6.00,
      category: 'Fruits',
    ),
    CropInfo(
      name: 'Watermelon',
      asset: '$_base/fruits/watermelon/watermelon_1.jpg',
      assets: [],
      unit: 'piece',
      basePrice: 25.00,
      category: 'Fruits',
    ),
    CropInfo(
      name: 'Pineapple',
      asset: '$_base/fruits/pineapple/pineapple_1.jpg',
      assets: [],
      unit: 'piece',
      basePrice: 8.00,
      category: 'Fruits',
    ),

    // Spices
    CropInfo(
      name: 'Ginger',
      asset: '$_base/spices/ginger/ginger_1.jpg',
      assets: [],
      unit: 'kg',
      basePrice: 22.00,
      category: 'Spices',
    ),
  ];

  static const categories = ['Vegetables', 'Staples', 'Legumes', 'Fruits', 'Spices'];

  static List<CropInfo> byCategory(String category) =>
      all.where((c) => c.category == category).toList();

  static CropInfo? findByName(String name) =>
      all.where((c) => c.name.toLowerCase() == name.toLowerCase()).firstOrNull;

  static String assetFor(String productName) {
    final match = all.where(
      (c) => productName.toLowerCase().contains(c.name.toLowerCase()),
    ).firstOrNull;
    return match?.asset ?? 'assets/images/kuapa_logo.jpg';
  }

  static List<String> assetsFor(String cat, String crop, {int count = 10}) =>
      _imgs(cat, crop, count);
}
