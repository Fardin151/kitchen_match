enum Difficulty { easy, medium, hard }

enum Cuisine {
  any,
  italian,
  asian,
  mexican,
  middleEastern,
  american,
  mediterranean,
}

extension DifficultyLabel on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }
}

extension CuisineLabel on Cuisine {
  String get label {
    switch (this) {
      case Cuisine.any:
        return 'All';
      case Cuisine.italian:
        return 'Italian';
      case Cuisine.asian:
        return 'Asian';
      case Cuisine.mexican:
        return 'Mexican';
      case Cuisine.middleEastern:
        return 'Middle Eastern';
      case Cuisine.american:
        return 'American';
      case Cuisine.mediterranean:
        return 'Mediterranean';
    }
  }
}

class RecipeIngredient {
  final String name;
  final String quantity;

  const RecipeIngredient({required this.name, required this.quantity});

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String,
      quantity: json['quantity'] as String,
    );
  }
}

class Recipe {
  final String id;
  final String title;
  final String description;
  final String imageEmoji;
  final String? imageUrl;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final int cookTimeMinutes;
  final int servings;
  final Difficulty difficulty;
  final Cuisine cuisine;
  final List<String> tags;

  // Computed at runtime — not stored
  final double matchScore;
  final int matchedCount;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageEmoji,
    this.imageUrl,
    required this.ingredients,
    required this.steps,
    required this.cookTimeMinutes,
    required this.servings,
    required this.difficulty,
    required this.cuisine,
    this.tags = const [],
    this.matchScore = 0,
    this.matchedCount = 0,
  });

  Recipe copyWith({double? matchScore, int? matchedCount}) {
    return Recipe(
      id: id,
      title: title,
      description: description,
      imageEmoji: imageEmoji,
      imageUrl: imageUrl,
      ingredients: ingredients,
      steps: steps,
      cookTimeMinutes: cookTimeMinutes,
      servings: servings,
      difficulty: difficulty,
      cuisine: cuisine,
      tags: tags,
      matchScore: matchScore ?? this.matchScore,
      matchedCount: matchedCount ?? this.matchedCount,
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageEmoji: json['imageEmoji'] as String,
      imageUrl: json['imageUrl'] as String?,
      ingredients: (json['ingredients'] as List)
          .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: List<String>.from(json['steps'] as List),
      cookTimeMinutes: json['cookTimeMinutes'] as int,
      servings: json['servings'] as int,
      difficulty: Difficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => Difficulty.medium,
      ),
      cuisine: Cuisine.values.firstWhere(
        (c) => c.name == json['cuisine'],
        orElse: () => Cuisine.any,
      ),
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }

  bool get isEasy => difficulty == Difficulty.easy;
  String get matchPercent => '${(matchScore * 100).round()}%';
}
