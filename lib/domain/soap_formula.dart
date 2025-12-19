class SoapOil {
  final String id;
  final String name;
  final double grams;
  final double? percent;

  SoapOil({
    required this.id,
    required this.name,
    required this.grams,
    this.percent,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grams': grams,
      if (percent != null) 'percent': percent,
    };
  }

  factory SoapOil.fromJson(Map<String, dynamic> json) {
    double? percentValue;
    final percentData = json['percent'];
    if (percentData != null) {
      percentValue = (percentData is num) ? percentData.toDouble() : null;
    }

    // Handle both int and double for backward compatibility
    final gramsData = json['grams'];
    final gramsValue = (gramsData is num) ? gramsData.toDouble() : 0.0;

    return SoapOil(
      id: json['id'] as String,
      name: json['name'] as String,
      grams: gramsValue,
      percent: percentValue,
    );
  }
}

class SoapLye {
  final String name;
  final double grams;

  SoapLye({required this.name, required this.grams});

  Map<String, dynamic> toJson() {
    return {'name': name, 'grams': grams};
  }

  factory SoapLye.fromJson(Map<String, dynamic> json) {
    // Handle both int and double for backward compatibility
    final gramsData = json['grams'];
    final gramsValue = (gramsData is num) ? gramsData.toDouble() : 0.0;
    return SoapLye(name: json['name'] as String, grams: gramsValue);
  }
}

class SoapWater {
  final String name;
  final double grams;

  SoapWater({required this.name, required this.grams});

  Map<String, dynamic> toJson() {
    return {'name': name, 'grams': grams};
  }

  factory SoapWater.fromJson(Map<String, dynamic> json) {
    // Handle both int and double for backward compatibility
    final gramsData = json['grams'];
    final gramsValue = (gramsData is num) ? gramsData.toDouble() : 0.0;
    return SoapWater(name: json['name'] as String, grams: gramsValue);
  }
}

class SoapFormula {
  final double batchSizeGrams;
  final double oilsTotalGrams;
  final List<SoapOil> oils;
  final SoapLye lye;
  final SoapWater water;
  final double? superfatPercent;

  SoapFormula({
    required this.batchSizeGrams,
    required this.oilsTotalGrams,
    required this.oils,
    required this.lye,
    required this.water,
    this.superfatPercent,
  });

  Map<String, dynamic> toJson() {
    return {
      'batchSizeGrams': batchSizeGrams,
      'oilsTotalGrams': oilsTotalGrams,
      'oils': oils.map((oil) => oil.toJson()).toList(),
      'lye': lye.toJson(),
      'water': water.toJson(),
      if (superfatPercent != null) 'superfatPercent': superfatPercent,
    };
  }

  factory SoapFormula.fromJson(Map<String, dynamic> json) {
    double? superfatPercentValue;
    final superfatPercentData = json['superfatPercent'];
    if (superfatPercentData != null) {
      superfatPercentValue = (superfatPercentData is num)
          ? superfatPercentData.toDouble()
          : null;
    }

    // Handle both int and double for backward compatibility
    final batchSizeData = json['batchSizeGrams'];
    final batchSizeValue = (batchSizeData is num)
        ? batchSizeData.toDouble()
        : 0.0;

    final oilsTotalData = json['oilsTotalGrams'];
    final oilsTotalValue = (oilsTotalData is num)
        ? oilsTotalData.toDouble()
        : 0.0;

    return SoapFormula(
      batchSizeGrams: batchSizeValue,
      oilsTotalGrams: oilsTotalValue,
      oils: (json['oils'] as List)
          .map((oil) => SoapOil.fromJson(oil as Map<String, dynamic>))
          .toList(),
      lye: SoapLye.fromJson(json['lye'] as Map<String, dynamic>),
      water: SoapWater.fromJson(json['water'] as Map<String, dynamic>),
      superfatPercent: superfatPercentValue,
    );
  }
}
