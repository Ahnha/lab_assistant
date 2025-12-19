enum RecipeKind { soap, cream }

extension RecipeKindExtension on RecipeKind {
  String get displayName {
    switch (this) {
      case RecipeKind.soap:
        return 'SOAP';
      case RecipeKind.cream:
        return 'CREAM';
    }
  }
}
