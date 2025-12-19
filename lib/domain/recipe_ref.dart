import 'recipe_kind.dart';

class RecipeRef {
  final String id;
  final RecipeKind kind;
  final String name;
  final int? defaultBatchSizeGrams;

  RecipeRef({
    required this.id,
    required this.kind,
    required this.name,
    this.defaultBatchSizeGrams,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'name': name,
      'defaultBatchSizeGrams': defaultBatchSizeGrams,
    };
  }

  factory RecipeRef.fromJson(Map<String, dynamic> json) {
    return RecipeRef(
      id: json['id'] as String,
      kind: RecipeKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => RecipeKind.soap,
      ),
      name: json['name'] as String,
      defaultBatchSizeGrams: json['defaultBatchSizeGrams'] as int?,
    );
  }
}
