# KitchenMatch 🧑‍🍳

A Flutter app that recommends recipes based on the ingredients you have at home.

## Features

- **Pantry manager** — Add and remove ingredients you have; persisted locally via Hive
- **Smart matching** — Recipes are scored and ranked by how many ingredients you already have
- **Easy filter** — Dedicated carousel of easy recipes surfaced on the home screen
- **Browse + filter** — Filter all 20 recipes by difficulty (Easy / Medium / Hard) and cuisine
- **Recipe detail** — Ingredient list with green/gray dots (have vs. missing), step-by-step cooking mode with progress
- **Save recipes** — Bookmark favourites to the Saved tab

## Project structure

```
lib/
├── main.dart                    # App entry, NavigationBar shell
├── models/
│   └── recipe.dart              # Recipe, RecipeIngredient, Difficulty, Cuisine
├── providers/
│   ├── pantry_provider.dart     # Hive-persisted ingredient list (Riverpod Notifier)
│   └── recipe_provider.dart    # Scoring logic, filters, saved IDs
├── screens/
│   ├── home_screen.dart         # Pantry + Easy carousel + Best Matches
│   ├── recipe_detail_screen.dart
│   ├── browse_screen.dart
│   └── saved_screen.dart
├── widgets/
│   └── shared_widgets.dart      # RecipeCard, IngredientChip, badges, EmptyState
└── theme/
    └── app_theme.dart           # Colors, MaterialTheme, typography
assets/
└── recipes.json                 # 20 built-in recipes
```

## Setup

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the app**
   ```bash
   flutter run
   ```

3. **Run on a specific device**
   ```bash
   flutter run -d chrome      # Web
   flutter run -d ios         # iOS simulator
   flutter run -d android     # Android emulator
   ```

## Extending the recipe database

Edit `assets/recipes.json` to add more recipes. Each recipe needs:

```json
{
  "id": "unique_id",
  "title": "Recipe Name",
  "description": "Short description.",
  "imageEmoji": "🍛",
  "ingredients": [
    { "name": "ingredient name", "quantity": "amount" }
  ],
  "steps": ["Step one.", "Step two."],
  "cookTimeMinutes": 20,
  "servings": 4,
  "difficulty": "easy",       // easy | medium | hard
  "cuisine": "asian",         // asian | italian | mexican | middleEastern | american | mediterranean | any
  "tags": ["tag1", "tag2"]
}
```

## Connecting to a real API (optional)

Replace the `allRecipesProvider` in `lib/providers/recipe_provider.dart` with a Dio call to the Spoonacular API:

```
GET https://api.spoonacular.com/recipes/findByIngredients
  ?ingredients=eggs,rice,garlic
  &number=10
  &apiKey=YOUR_KEY
```

## Tech stack

| Package | Use |
|---|---|
| `flutter_riverpod` | State management |
| `hive_flutter` | Local persistence (pantry) |
| `google_fonts` | Plus Jakarta Sans typography |
| `cached_network_image` | Remote recipe images |
