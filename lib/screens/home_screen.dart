import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe.dart';
import '../providers/pantry_provider.dart';
import '../providers/recipe_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'recipe_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _showIngredientInput = false;
  final _ingredientController = TextEditingController();
  final _inputFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _ingredientController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final text = _ingredientController.text.trim();
    if (text.isNotEmpty) {
      ref.read(pantryProvider.notifier).addIngredient(text);
      _ingredientController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pantry = ref.watch(pantryProvider);
    final easyAsync = ref.watch(easyRecipesProvider);
    final topAsync = ref.watch(topMatchesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Ingredient input ──────────────────────────────────────
                  _IngredientInputBar(
                    controller: _ingredientController,
                    focusNode: _inputFocus,
                    isVisible: _showIngredientInput,
                    onToggle: () {
                      setState(() => _showIngredientInput = !_showIngredientInput);
                      if (_showIngredientInput) {
                        Future.delayed(
                          const Duration(milliseconds: 100),
                          () => _inputFocus.requestFocus(),
                        );
                      }
                    },
                    onSubmit: _addIngredient,
                  ),
                  const SizedBox(height: 16),

                  // ── Pantry chips ──────────────────────────────────────────
                  if (pantry.isNotEmpty) ...[
                    SectionHeader(
                      title: 'YOUR INGREDIENTS (${pantry.length})',
                      actionLabel: 'Clear all',
                      onAction: () => ref.read(pantryProvider.notifier).clearAll(),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pantry
                          .map((ing) => IngredientChip(
                                label: ing,
                                onDelete: () =>
                                    ref.read(pantryProvider.notifier).removeIngredient(ing),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    _EmptyPantryBanner(
                      onAdd: () {
                        setState(() => _showIngredientInput = true);
                        Future.delayed(
                          const Duration(milliseconds: 100),
                          () => _inputFocus.requestFocus(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Easy to make ──────────────────────────────────────────
                  const SectionHeader(title: 'EASY TO MAKE'),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Easy horizontal carousel
          SliverToBoxAdapter(
            child: easyAsync.when(
              loading: () => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => const SizedBox.shrink(),
              data: (recipes) {
                if (recipes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'No easy recipes yet — add more ingredients!',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  );
                }
                return SizedBox(
                  height: 185,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: recipes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => RecipeCardHorizontal(
                      recipe: recipes[i],
                      onTap: () => _openDetail(recipes[i]),
                    ),
                  ),
                );
              },
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
              child: SectionHeader(
                title: 'BEST MATCHES',
                actionLabel: pantry.isEmpty ? null : 'See all',
                onAction: () {},
              ),
            ),
          ),

          // Best matches vertical list
          topAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (recipes) {
              if (recipes.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: EmptyState(
                      emoji: '🥄',
                      title: pantry.isEmpty
                          ? 'Your pantry is empty'
                          : 'No matches yet',
                      subtitle: pantry.isEmpty
                          ? 'Add ingredients to see matching recipes'
                          : 'Try adding more ingredients',
                    ),
                  ),
                );
              }
              return SliverList.separated(
                itemCount: recipes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RecipeCard(
                    recipe: recipes[i],
                    onTap: () => _openDetail(recipes[i]),
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      expandedHeight: 90,
      collapsedHeight: 60,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "What's in your kitchen?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Add ingredients to find matching recipes',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _IngredientInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isVisible;
  final VoidCallback onToggle;
  final VoidCallback onSubmit;

  const _IngredientInputBar({
    required this.controller,
    required this.focusNode,
    required this.isVisible,
    required this.onToggle,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
              SizedBox(width: 10),
              Text(
                'Add ingredient...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. eggs, tomatoes, garlic',
              prefixIcon: Icon(Icons.search_rounded, size: 18),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSubmit,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder, width: 0.5),
            ),
            child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _EmptyPantryBanner extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyPantryBanner({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.green.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        children: [
          const Text('🧑‍🍳', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your pantry is empty',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add ingredients you have at home to discover matching recipes',
                  style: TextStyle(fontSize: 12, color: AppColors.greenMid, height: 1.4),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Add ingredients',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
