import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class SpoonacularService {
  static const _apiKey = '09ba2b9f60bd4991b4bf247070b2e055';
  static const _base = 'https://api.spoonacular.com';

  // Search recipes by query (e.g. "pasta", "chicken")
  Future<List<Recipe>> searchRecipes(String query, {int number = 20}) async {
    final uri = Uri.parse('$_base/recipes/complexSearch').replace(
      queryParameters: {
        'apiKey': _apiKey,
        'query': query,
        'number': '$number',
        'addRecipeInformation': 'true',
        'fillIngredients': 'true',
        'addRecipeInstructions': 'true', // ← ensures steps are included
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('API error: ${response.statusCode}');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List;
    return results.map((r) => _mapToRecipe(r)).toList();
  }

  // Fetch full recipe details by Spoonacular ID (used when steps are missing)
  Future<Recipe> getRecipeDetails(String recipeId) async {
    // Strip the 'sp_' prefix we add locally
    final id = recipeId.replaceFirst('sp_', '');

    final uri = Uri.parse('$_base/recipes/$id/information').replace(
      queryParameters: {
        'apiKey': _apiKey,
        'includeNutrition': 'false',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('API error: ${response.statusCode}');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _mapToRecipe(data);
  }

  // Find recipes by ingredients you already have
  Future<List<Recipe>> findByIngredients(List<String> ingredients) async {
    final uri = Uri.parse('$_base/recipes/findByIngredients').replace(
      queryParameters: {
        'apiKey': _apiKey,
        'ingredients': ingredients.join(','),
        'number': '20',
        'ranking': '1',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('API error');

    final List results = jsonDecode(response.body);
    return results.map((r) => _mapByIngredients(r)).toList();
  }

  // Map full Spoonacular response → Recipe model
  Recipe _mapToRecipe(Map<String, dynamic> r) {
    final cuisines = r['cuisines'] as List? ?? [];

    return Recipe(
      id: 'sp_${r['id']}',
      title: r['title'] ?? '',
      description: r['summary'] != null
          ? _stripHtml(r['summary'])
          : 'A delicious recipe from Spoonacular.',
      imageEmoji: '🍽️',
      imageUrl: r['image'] as String?,
      ingredients: _parseIngredients(r['extendedIngredients']),
      steps: _parseSteps(r['analyzedInstructions']),
      cookTimeMinutes: r['readyInMinutes'] ?? 30,
      servings: r['servings'] ?? 4,
      difficulty: _parseDifficulty(r['readyInMinutes']),
      cuisine: _parseCuisine(cuisines),
      tags: List<String>.from(r['dishTypes'] ?? []),
    );
  }

  Recipe _mapByIngredients(Map<String, dynamic> r) {
    return Recipe(
      id: 'sp_${r['id']}',
      title: r['title'] ?? '',
      description: 'Found via ingredient match.',
      imageEmoji: '🍽️',
      imageUrl: r['image'] as String?,
      ingredients: _parseIngredients(r['usedIngredients']),
      steps: const [],
      cookTimeMinutes: 30,
      servings: 4,
      difficulty: Difficulty.medium,
      cuisine: Cuisine.any,
    );
  }

  List<RecipeIngredient> _parseIngredients(dynamic raw) {
    if (raw == null) return [];
    return (raw as List).map((i) => RecipeIngredient(
          name: i['name'] ?? '',
          quantity: '${i['amount'] ?? ''} ${i['unit'] ?? ''}'.trim(),
        )).toList();
  }

  List<String> _parseSteps(dynamic raw) {
    if (raw == null || (raw as List).isEmpty) return [];
    final steps = raw[0]['steps'] as List? ?? [];
    return steps.map((s) => s['step'] as String).toList();
  }

  Difficulty _parseDifficulty(int? minutes) {
    if (minutes == null) return Difficulty.medium;
    if (minutes <= 20) return Difficulty.easy;
    if (minutes <= 45) return Difficulty.medium;
    return Difficulty.hard;
  }

  Cuisine _parseCuisine(List cuisines) {
    if (cuisines.isEmpty) return Cuisine.any;
    final c = cuisines.first.toString().toLowerCase();
    if (c.contains('italian')) return Cuisine.italian;
    if (c.contains('asian') || c.contains('chinese') || c.contains('japanese')) {
      return Cuisine.asian;
    }
    if (c.contains('mexican')) return Cuisine.mexican;
    if (c.contains('middle eastern')) return Cuisine.middleEastern;
    if (c.contains('american')) return Cuisine.american;
    if (c.contains('mediterranean')) return Cuisine.mediterranean;
    return Cuisine.any;
  }

  String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}