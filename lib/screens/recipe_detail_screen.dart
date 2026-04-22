import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe.dart';
import '../providers/pantry_provider.dart';
import '../providers/recipe_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/spoonacular_service.dart';
import '../providers/shopping_list_provider.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _servings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _servings = widget.recipe.servings;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Quantity scaling ──────────────────────────────────────────────────────
  /// Tries to parse a leading numeric value (int, decimal, fraction, unicode
  /// vulgar fraction) from [qty], multiplies it by [factor], then re-assembles
  /// with the trailing unit/descriptor unchanged.
  ///
  /// Falls back to the original string when there is nothing numeric to scale
  /// (e.g. "to taste", "handful", "for brushing").
  String _scale(String qty, double factor) {
    if (factor == 1.0) return qty;

    // Map unicode vulgar fractions → decimal strings so the parser can read them
    const vulgar = {
      '½': '1/2', '⅓': '1/3', '⅔': '2/3',
      '¼': '1/4', '¾': '3/4', '⅕': '1/5',
      '⅖': '2/5', '⅗': '3/5', '⅘': '4/5',
      '⅙': '1/6', '⅚': '5/6', '⅛': '1/8',
      '⅜': '3/8', '⅝': '5/8', '⅞': '7/8',
    };
    String normalised = qty;
    vulgar.forEach((glyph, ascii) {
      normalised = normalised.replaceAll(glyph, ascii);
    });

    // Regex: optional leading fraction OR decimal, followed by optional unit
    final pattern = RegExp(
      r'^(\d+/\d+|\d+(?:\.\d+)?)'  // number (fraction or decimal)
      r'(.*)',                       // rest (unit + descriptor)
    );
    final m = pattern.firstMatch(normalised.trim());
    if (m == null) return qty; // nothing numeric — return original

    final rawNum = m.group(1)!;
    final rest = m.group(2) ?? '';

    double value;
    if (rawNum.contains('/')) {
      final parts = rawNum.split('/');
      value = double.parse(parts[0]) / double.parse(parts[1]);
    } else {
      value = double.parse(rawNum);
    }

    final scaled = value * factor;

    // Format: drop trailing zeros; keep up to 2 decimal places
    String formatted;
    if (scaled == scaled.roundToDouble()) {
      formatted = scaled.round().toString();
    } else {
      formatted = scaled.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }

    return '$formatted$rest';
  }

  Color get _heroBg {
    switch (widget.recipe.cuisine) {
      case Cuisine.asian:
        return const Color(0xFFFAC775);
      case Cuisine.italian:
        return const Color(0xFF9FE1CB);
      case Cuisine.mexican:
        return const Color(0xFFF0997B);
      case Cuisine.middleEastern:
        return const Color(0xFFB5D4F4);
      case Cuisine.mediterranean:
        return const Color(0xFFC0DD97);
      case Cuisine.american:
        return const Color(0xFFF4C0D1);
      default:
        return const Color(0xFFD3D1C7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaved = ref.watch(
      savedRecipesProvider.select((s) => s.contains(widget.recipe.id)),
    );
    final pantry = ref.watch(pantryProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Hero app bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _heroBg,
            surfaceTintColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () =>
                    ref.read(savedRecipesProvider.notifier).toggle(widget.recipe.id),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    color: isSaved ? AppColors.green : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: _heroBg,
                alignment: Alignment.center,
                child: Text(
                  widget.recipe.imageEmoji,
                  style: const TextStyle(fontSize: 90),
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.recipe.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Meta badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      DifficultyBadge(widget.recipe.difficulty),
                      if (widget.recipe.matchedCount > 0)
                        MatchBadge(widget.recipe),
                      _MetaBadge(
                        icon: Icons.access_time_rounded,
                        label: '${widget.recipe.cookTimeMinutes} min',
                      ),
                      _ServingsScaler(
                        servings: _servings,
                        onDecrement: _servings > 1
                            ? () => setState(() => _servings--)
                            : null,
                        onIncrement: _servings < 99
                            ? () => setState(() => _servings++)
                            : null,
                      ),
                      _MetaBadge(
                        icon: Icons.restaurant_rounded,
                        label: widget.recipe.cuisine.label,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Description
                  Text(
                    widget.recipe.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder, width: 0.5),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.green,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14),
                      indicator: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Ingredients'),
                        Tab(text: 'Steps'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Tab content ───────────────────────────────────────────────────
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 500, // Allow the tab view to take space
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _IngredientsTab(
                      recipe: widget.recipe,
                      pantry: pantry,
                      scaleFactor: _servings / widget.recipe.servings,
                      scaleQty: _scale,
                    ),
                    _StepsTab(recipe: widget.recipe),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _IngredientsTab extends ConsumerWidget {
  final Recipe recipe;
  final List<String> pantry;
  final double scaleFactor;
  final String Function(String qty, double factor) scaleQty;

  const _IngredientsTab({
    required this.recipe,
    required this.pantry,
    required this.scaleFactor,
    required this.scaleQty,
  });

  bool _have(RecipeIngredient ing) =>
      pantry.any((p) => ing.name.toLowerCase().contains(p));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final have = recipe.ingredients.where(_have).toList();
    final missing = recipe.ingredients.where((i) => !_have(i)).toList();

    void addMissingToCart() {
      if (missing.isEmpty) return;
      final added = ref
          .read(shoppingListProvider.notifier)
          .addAll(missing.map((i) => i.name).toList());
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'Already on your list!'
                : '$added item${added == 1 ? '' : 's'} added to shopping list',
          ),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          backgroundColor: AppColors.textPrimary,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (have.isNotEmpty) ...[
          _IngredientGroup(
            title: 'You have (${have.length})',
            ingredients: have,
            hasItem: true,
            scaleFactor: scaleFactor,
            scaleQty: scaleQty,
          ),
          const SizedBox(height: 16),
        ],
        if (missing.isNotEmpty) ...[
          _IngredientGroup(
            title: 'Still need (${missing.length})',
            ingredients: missing,
            hasItem: false,
            scaleFactor: scaleFactor,
            scaleQty: scaleQty,
          ),
          const SizedBox(height: 14),
          // ── Add missing → shopping list ─────────────────────────────────
          GestureDetector(
            onTap: addMissingToCart,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      size: 18, color: AppColors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add ${missing.length} missing item${missing.length == 1 ? '' : 's'} to shopping list',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColors.green),
                ],
              ),
            ),
          ),
        ],
        if (pantry.isEmpty)
          _IngredientGroup(
            title: 'All ingredients',
            ingredients: recipe.ingredients,
            hasItem: null,
            scaleFactor: scaleFactor,
            scaleQty: scaleQty,
          ),
      ],
    );
  }
}

class _IngredientGroup extends StatelessWidget {
  final String title;
  final List<RecipeIngredient> ingredients;
  final bool? hasItem; // null = neutral (no pantry)
  final double scaleFactor;
  final String Function(String qty, double factor) scaleQty;

  const _IngredientGroup({
    required this.title,
    required this.ingredients,
    required this.hasItem,
    required this.scaleFactor,
    required this.scaleQty,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        ...ingredients.map((ing) => _IngredientRow(
              ing: ing,
              hasItem: hasItem,
              scaledQty: scaleQty(ing.quantity, scaleFactor),
            )),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final RecipeIngredient ing;
  final bool? hasItem;
  final String scaledQty;
  const _IngredientRow({required this.ing, required this.hasItem, required this.scaledQty});

  @override
  Widget build(BuildContext context) {
    final dotColor = hasItem == null
        ? AppColors.textMuted
        : hasItem!
            ? AppColors.green
            : AppColors.cardBorder;
    final textColor = hasItem == false ? AppColors.textMuted : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ing.name,
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ),
          Text(
            scaledQty,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _StepsTab extends StatefulWidget {
  final Recipe recipe;
  const _StepsTab({required this.recipe});

  @override
  State<_StepsTab> createState() => _StepsTabState();
}

class _StepsTabState extends State<_StepsTab> {
  int _currentStep = 0;
  List<String>? _fetchedSteps;
  bool _loading = false;
  String? _error;

  bool get _isApiRecipe => widget.recipe.id.startsWith('sp_');

  @override
  void initState() {
    super.initState();
    if (_isApiRecipe && widget.recipe.steps.isEmpty) {
      _fetchSteps();
    }
  }

  Future<void> _fetchSteps() async {
    setState(() { _loading = true; _error = null; });
    try {
      final full = await SpoonacularService().getRecipeDetails(widget.recipe.id);
      if (mounted) {
        setState(() {
          _fetchedSteps = full.steps;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load steps. Check your connection.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _fetchedSteps ?? widget.recipe.steps;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😕', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _fetchSteps, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (steps.isEmpty) {
      return const Center(
        child: Text(
          'No steps available for this recipe.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            physics: const ClampingScrollPhysics(),
            itemCount: steps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final isDone = i < _currentStep;
              final isCurrent = i == _currentStep;
              return GestureDetector(
                onTap: () => setState(() => _currentStep = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.greenLight : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrent ? AppColors.green.withOpacity(0.3) : AppColors.cardBorder,
                      width: isCurrent ? 1 : 0.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppColors.green
                              : isCurrent
                                  ? AppColors.green
                                  : AppColors.cardBorder,
                          shape: BoxShape.circle,
                        ),
                        child: isDone
                            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                            : Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isCurrent ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          steps[i],
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            decorationColor: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _currentStep < steps.length - 1
                    ? () => setState(() => _currentStep++)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.greenLight,
                  disabledForegroundColor: AppColors.green,
                ),
                child: Text(
                  _currentStep < steps.length - 1 ? 'Next step' : '🎉 Done!',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Servings scaler badge ─────────────────────────────────────────────────────
class _ServingsScaler extends StatelessWidget {
  final int servings;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _ServingsScaler({
    required this.servings,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrement,
            child: Icon(
              Icons.remove_rounded,
              size: 16,
              color: onDecrement != null
                  ? AppColors.textSecondary
                  : AppColors.cardBorder,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.people_outline_rounded, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            '$servings serving${servings == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onIncrement,
            child: Icon(
              Icons.add_rounded,
              size: 16,
              color: onIncrement != null
                  ? AppColors.textSecondary
                  : AppColors.cardBorder,
            ),
          ),
        ],
      ),
    );
  }
}