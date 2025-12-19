import 'formula_item.dart';

class FormulaPhase {
  final String id;
  final String name;
  final int order;
  final List<FormulaItem> items;
  final int? totalGrams;

  FormulaPhase({
    required this.id,
    required this.name,
    required this.order,
    required this.items,
    this.totalGrams,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'items': items.map((item) => item.toJson()).toList(),
      if (totalGrams != null) 'totalGrams': totalGrams,
    };
  }

  factory FormulaPhase.fromJson(Map<String, dynamic> json) {
    return FormulaPhase(
      id: json['id'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      items: (json['items'] as List)
          .map((item) => FormulaItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalGrams: json['totalGrams'] as int?,
    );
  }

  FormulaPhase copyWith({
    String? id,
    String? name,
    int? order,
    List<FormulaItem>? items,
    int? totalGrams,
  }) {
    return FormulaPhase(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      items: items ?? this.items,
      totalGrams: totalGrams ?? this.totalGrams,
    );
  }
}
