import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe.dart';
import 'pantry_provider.dart';
import '../services/spoonacular_service.dart';

// ── Raw recipe loader ────────────────────────────────────────────────────────

final allRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/recipes.json');
  final List<dynamic> data = jsonDecode(jsonStr);
  return data.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
});

// ── Filter state ─────────────────────────────────────────────────────────────

class RecipeFilter {
  final Difficulty? difficulty;
  final Cuisine cuisine;
  final String searchQuery;

  const RecipeFilter({
    this.difficulty,
    this.cuisine = Cuisine.any,
    this.searchQuery = '',
  });

  RecipeFilter copyWith({
    Difficulty? difficulty,
    bool clearDifficulty = false,
    Cuisine? cuisine,
    String? searchQuery,
  }) {
    return RecipeFilter(
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      cuisine: cuisine ?? this.cuisine,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class RecipeFilterNotifier extends Notifier<RecipeFilter> {
  @override
  RecipeFilter build() => const RecipeFilter();

  void setDifficulty(Difficulty? d) {
    state = state.copyWith(
      difficulty: d,
      clearDifficulty: d == null,
    );
  }

  void setCuisine(Cuisine c) => state = state.copyWith(cuisine: c);

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  void reset() => state = const RecipeFilter();
}

final recipeFilterProvider =
    NotifierProvider<RecipeFilterNotifier, RecipeFilter>(
  RecipeFilterNotifier.new,
);

// ── Matched & filtered recipes ───────────────────────────────────────────────

final matchedRecipesProvider = Provider<AsyncValue<List<Recipe>>>((ref) {
  final recipesAsync = ref.watch(allRecipesProvider);
  final pantry = ref.watch(pantryProvider);
  final filter = ref.watch(recipeFilterProvider);

  return recipesAsync.whenData((recipes) {
    // Score each recipe against the current pantry
    var scored = recipes.map((recipe) {
      if (pantry.isEmpty) return recipe.copyWith(matchScore: 0, matchedCount: 0);

      final matched = recipe.ingredients
          .where((ing) => pantry.any((p) => ing.name.toLowerCase().contains(p)))
          .length;
      final score = matched / recipe.ingredients.length;
      return recipe.copyWith(matchScore: score, matchedCount: matched);
    }).toList();

    // Apply search
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      scored = scored
          .where((r) =>
              r.title.toLowerCase().contains(q) ||
              r.tags.any((t) => t.contains(q)) ||
              r.ingredients.any((i) => i.name.contains(q)))
          .toList();
    }

    // Apply difficulty filter
    if (filter.difficulty != null) {
      scored = scored.where((r) => r.difficulty == filter.difficulty).toList();
    }

    // Apply cuisine filter
    if (filter.cuisine != Cuisine.any) {
      scored = scored.where((r) => r.cuisine == filter.cuisine).toList();
    }

    // Sort: matched recipes first (by score desc), then unmatched alphabetically
    scored.sort((a, b) {
      if (a.matchScore != b.matchScore) {
        return b.matchScore.compareTo(a.matchScore);
      }
      return a.title.compareTo(b.title);
    });

    return scored;
  });
});

// ── Convenience sub-providers ─────────────────────────────────────────────────

final easyRecipesProvider = Provider<AsyncValue<List<Recipe>>>((ref) {
  return ref.watch(matchedRecipesProvider).whenData(
        (recipes) => recipes.where((r) => r.isEasy).take(6).toList(),
      );
});

final topMatchesProvider = Provider<AsyncValue<List<Recipe>>>((ref) {
  return ref.watch(matchedRecipesProvider).whenData(
        (recipes) =>
            recipes.where((r) => r.matchScore > 0).take(10).toList(),
      );
});

// Saved recipe IDs
class SavedRecipesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }

  bool isSaved(String id) => state.contains(id);
}

final savedRecipesProvider =
    NotifierProvider<SavedRecipesNotifier, Set<String>>(
  SavedRecipesNotifier.new,
);


// Singleton service
final spoonacularServiceProvider = Provider((_) => SpoonacularService());

// Search query state
final apiSearchQueryProvider = StateProvider<String>((_) => '');

// Fetches results whenever query changes
final apiRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final query = ref.watch(apiSearchQueryProvider);
  if (query.isEmpty) return [];
  final service = ref.read(spoonacularServiceProvider);
  return service.searchRecipes(query);
});