import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'recipe_detail_screen.dart';

// ── Main screen with two tabs ─────────────────────────────────────────────────

class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Browse recipes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Kitchen'),
              Tab(text: 'Discover'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LocalRecipesTab(),
            _ApiSearchTab(),
          ],
        ),
      ),
    );
  }
}

// ── Local recipes tab (your original browse logic) ────────────────────────────

class _LocalRecipesTab extends ConsumerWidget {
  const _LocalRecipesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(recipeFilterProvider);
    final recipesAsync = ref.watch(matchedRecipesProvider);

    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              // Difficulty filter
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: filter.difficulty == null,
                      onTap: () =>
                          ref.read(recipeFilterProvider.notifier).setDifficulty(null),
                    ),
                    const SizedBox(width: 8),
                    ...Difficulty.values.map((d) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: d.label,
                            selected: filter.difficulty == d,
                            onTap: () => ref
                                .read(recipeFilterProvider.notifier)
                                .setDifficulty(d),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Cuisine filter
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: Cuisine.values
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: c.label,
                              selected: filter.cuisine == c,
                              onTap: () => ref
                                  .read(recipeFilterProvider.notifier)
                                  .setCuisine(c),
                              color: AppColors.blueLight,
                              activeColor: AppColors.blue,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Recipe list
        Expanded(
          child: recipesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                const Center(child: Text('Something went wrong loading recipes.')),
            data: (recipes) {
              if (recipes.isEmpty) {
                return const EmptyState(
                  emoji: '🔍',
                  title: 'No recipes found',
                  subtitle: 'Try changing the filters',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: recipes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => RecipeCard(
                  recipe: recipes[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipe: recipes[i])),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── API search tab ────────────────────────────────────────────────────────────

class _ApiSearchTab extends ConsumerWidget {
  const _ApiSearchTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(apiSearchQueryProvider);
    final recipesAsync = ref.watch(apiRecipesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search millions of recipes...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) =>
                ref.read(apiSearchQueryProvider.notifier).state = v.trim(),
          ),
        ),
        Expanded(
          child: query.isEmpty
              ? const EmptyState(
                  emoji: '🌐',
                  title: 'Search the web',
                  subtitle: 'Find recipes beyond your kitchen',
                )
              : recipesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (recipes) => recipes.isEmpty
                      ? const EmptyState(
                          emoji: '😕',
                          title: 'No results',
                          subtitle: 'Try a different search',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: recipes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => RecipeCard(
                            recipe: recipes[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      RecipeDetailScreen(recipe: recipes[i])),
                            ),
                          ),
                        ),
                ),
        ),
      ],
    );
  }
}

// ── Filter chip widget ────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final Color activeColor;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.greenLight,
    this.activeColor = AppColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor.withOpacity(0.4) : AppColors.cardBorder,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            color: selected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}