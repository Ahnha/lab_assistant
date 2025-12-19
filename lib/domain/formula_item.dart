class FormulaItem {
  final String id;
  final String name;
  final double grams;
  final double? percent;
  final String? notes;

  FormulaItem({
    required this.id,
    required this.name,
    required this.grams,
    this.percent,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grams': grams,
      if (percent != null) 'percent': percent,
      if (notes != null) 'notes': notes,
    };
  }

  factory FormulaItem.fromJson(Map<String, dynamic> json) {
    double? percentValue;
    final percentData = json['percent'];
    if (percentData != null) {
      if (percentData is num) {
        percentValue = percentData.toDouble();
      }
    }

    final gramsData = json['grams'];
    final gramsValue = (gramsData is num) ? gramsData.toDouble() : 0.0;

    return FormulaItem(
      id: json['id'] as String,
      name: json['name'] as String,
      grams: gramsValue,
      percent: percentValue,
      notes: json['notes'] as String?,
    );
  }

  FormulaItem copyWith({
    String? id,
    String? name,
    double? grams,
    double? percent,
    String? notes,
  }) {
    return FormulaItem(
      id: id ?? this.id,
      name: name ?? this.name,
      grams: grams ?? this.grams,
      percent: percent ?? this.percent,
      notes: notes ?? this.notes,
    );
  }
}
