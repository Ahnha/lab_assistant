import 'package:flutter/material.dart';
import '../domain/recipe_kind.dart';

class RecipeBadge extends StatelessWidget {
  final RecipeKind kind;

  const RecipeBadge({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kind == RecipeKind.soap
            ? Colors.orange.shade100
            : Colors.purple.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        kind.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: kind == RecipeKind.soap
              ? Colors.orange.shade900
              : Colors.purple.shade900,
        ),
      ),
    );
  }
}
