# KitchenMatch

A Flutter app that recommends recipes based on the ingredients you already have at home.

---

## Features

### Pantry
Add ingredients you have at home and KitchenMatch scores every recipe against them — the more you have, the higher the match. Your pantry is saved locally with Hive and persists across app restarts.

### Recipe matching
20 built-in recipes across 6 cuisines (Italian, Asian, Mexican, Middle Eastern, Mediterranean, American). Each recipe shows a match percentage and highlights which ingredients you already have vs. what you still need.

### Servings scaler
On any recipe detail screen, tap `−` or `+` next to the servings count to scale all ingredient quantities up or down. Handles integers, decimals, fractions, and Unicode vulgar fractions (½ ¼ ¾ etc.). Non-numeric quantities like "to taste" pass through unchanged.

### Shopping list
Tap **Add missing items to shopping list** on any recipe to add everything you don't have in one tap. The shopping list screen lives in its own nav tab — tap an item to check it off, swipe left to delete, and use **Clear done** to remove checked items. The list is Hive-backed and survives restarts.

### Onboarding
On first launch, a screen lets you pick pantry staples from 30 common ingredients grouped into three categories (Pantry basics, Fridge staples, Spices & sauces). Selections are bulk-added to your pantry. Shown exactly once — skipping or completing it sets a flag in Hive that prevents it from appearing again.

### Browse & saved
Browse all recipes with filters for difficulty and cuisine. Bookmark any recipe to save it for later.

---

## Project structure

```
lib/
├── main.dart                        # App entry, Hive init, onboarding gate, nav shell
├── models/
│   └── recipe.dart                  # Recipe, RecipeIngredient, Difficulty, Cuisine
├── providers/
│   ├── pantry_provider.dart         # Hive-backed pantry (List<String>)
│   ├── recipe_provider.dart         # Recipe loading, filtering, scoring, saved IDs
│   └── shopping_list_provider.dart  # Hive-backed shopping list (List<ShoppingItem>)
├── screens/
│   ├── onboarding_screen.dart       # First-launch staple picker with inline SVG logo
│   ├── home_screen.dart             # Pantry input, easy recipes, best matches
│   ├── recipe_detail_screen.dart    # Ingredients tab (with scaler + add-to-list), steps tab
│   ├── shopping_list_screen.dart    # Shopping list with check-off and swipe-to-delete
│   ├── saved_screen.dart            # Bookmarked recipes
│   └── browse_screen.dart          # Filterable full recipe grid
├── theme/
│   └── app_theme.dart               # AppColors, AppTheme (Material 3, Plus Jakarta Sans)
└── widgets/
    └── shared_widgets.dart          # RecipeCard, IngredientChip, EmptyState, badges, etc.

assets/
└── recipes.json                     # 20 bundled recipes
```

---

## Local persistence

All persistence uses Hive, opened before `runApp` in `main()`:

| Box | Type | Key | Contents |
|---|---|---|---|
| `pantry` | `Box<String>` | auto | ingredient names |
| `shopping_list` | `Box<String>` | auto | `"0\|name"` / `"1\|name"` (checked flag + name) |
| `prefs` | `Box<bool>` | `hasSeenOnboarding` | onboarding completion flag |

---

## Getting started

```bash
flutter pub get
flutter run
```

Requires Flutter 3.x and Dart ≥ 3.0.0. No API keys needed for the bundled recipes. The app optionally integrates with the Spoonacular API for extended search — add your key to `lib/services/spoonacular_service.dart` if you want that enabled.

---

## Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `hive` / `hive_flutter` | Local persistence |
| `flutter_svg` | SVG rendering (logo) |
| `google_fonts` | Plus Jakarta Sans typeface |
| `cached_network_image` | Network recipe images |
| `shimmer` | Loading skeletons |
| `http` | Spoonacular API calls |
| `go_router` | Routing |
| `gap` | Spacing utility |
| `iconsax` | Icon set |
