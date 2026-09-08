class ProductPrice {
  final String id;
  final String category;
  final String name;
  final String grade;
  final String packing;
  final String currency;
  final double currentPrice;
  final double prevPrice;
  final String moq;
  final String validity;
  final String remarks;
  final String lastUpdated;

  ProductPrice({
    required this.id,
    required this.category,
    required this.name,
    required this.grade,
    required this.packing,
    this.currency = 'USD / MT',
    required this.currentPrice,
    this.prevPrice = 0.0,
    this.moq = '1 FCL',
    this.validity = '',
    this.remarks = '',
    this.lastUpdated = '',
  });

  double get changeAmount => currentPrice - prevPrice;

  String get changePercent {
    if (prevPrice <= 0) return '0.0%';
    final pct = (changeAmount / prevPrice) * 100;
    return '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
  }

  String get trend {
    if (changeAmount > 0) return 'up';
    if (changeAmount < 0) return 'down';
    return 'stable';
  }

  ProductPrice copyWith({
    String? id,
    String? category,
    String? name,
    String? grade,
    String? packing,
    String? currency,
    double? currentPrice,
    double? prevPrice,
    String? moq,
    String? validity,
    String? remarks,
    String? lastUpdated,
  }) {
    return ProductPrice(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      packing: packing ?? this.packing,
      currency: currency ?? this.currency,
      currentPrice: currentPrice ?? this.currentPrice,
      prevPrice: prevPrice ?? this.prevPrice,
      moq: moq ?? this.moq,
      validity: validity ?? this.validity,
      remarks: remarks ?? this.remarks,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'grade': grade,
      'packing': packing,
      'currency': currency,
      'currentPrice': currentPrice,
      'prevPrice': prevPrice,
      'moq': moq,
      'validity': validity,
      'remarks': remarks,
      'lastUpdated': lastUpdated,
    };
  }

  factory ProductPrice.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString().replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0;
    }

    return ProductPrice(
      id: json['id']?.toString().trim() ?? '',
      category: json['category']?.toString().trim() ?? 'General',
      name: json['name']?.toString().trim() ?? '',
      grade: json['grade']?.toString().trim() ?? '',
      packing: json['packing']?.toString().trim() ?? '',
      currency: json['currency']?.toString().trim() ?? 'USD / MT',
      currentPrice: parseNum(json['currentPrice'] ?? json['price']),
      prevPrice: parseNum(json['prevPrice']),
      moq: json['moq']?.toString().trim() ?? '1 FCL',
      validity: json['validity']?.toString().trim() ?? '',
      remarks: json['remarks']?.toString().trim() ?? '',
      lastUpdated: json['lastUpdated']?.toString().trim() ?? '',
    );
  }
}

class PriceHistoryItem {
  final String historyId;
  final String weekLabel;
  final String productId;
  final String category;
  final String name;
  final String grade;
  final String packing;
  final String currency;
  final double price;
  final double changeAmount;
  final String changePercent;
  final String recordedAt;

  PriceHistoryItem({
    required this.historyId,
    required this.weekLabel,
    required this.productId,
    required this.category,
    required this.name,
    required this.grade,
    required this.packing,
    required this.currency,
    required this.price,
    required this.changeAmount,
    required this.changePercent,
    required this.recordedAt,
  });

  factory PriceHistoryItem.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString().replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0;
    }

    return PriceHistoryItem(
      historyId: json['historyId']?.toString().trim() ?? '',
      weekLabel: json['weekLabel']?.toString().trim() ?? '',
      productId: json['productId']?.toString().trim() ?? '',
      category: json['category']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      grade: json['grade']?.toString().trim() ?? '',
      packing: json['packing']?.toString().trim() ?? '',
      currency: json['currency']?.toString().trim() ?? 'USD / MT',
      price: parseNum(json['price']),
      changeAmount: parseNum(json['changeAmount']),
      changePercent: json['changePercent']?.toString().trim() ?? '0.0%',
      recordedAt: json['recordedAt']?.toString().trim() ?? '',
    );
  }
}
