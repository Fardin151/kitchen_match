import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../theme/app_theme.dart';

// ── Difficulty badge ─────────────────────────────────────────────────────────

class DifficultyBadge extends StatelessWidget {
  final Difficulty difficulty;
  const DifficultyBadge(this.difficulty, {super.key});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (difficulty) {
      Difficulty.easy => (AppColors.greenLight, AppColors.green),
      Difficulty.medium => (AppColors.amberLight, AppColors.amber),
      Difficulty.hard => (AppColors.coralLight, AppColors.coral),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        difficulty.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}

// ── Match badge ───────────────────────────────────────────────────────────────

class MatchBadge extends StatelessWidget {
  final Recipe recipe;
  const MatchBadge(this.recipe, {super.key});

  @override
  Widget build(BuildContext context) {
    if (recipe.matchedCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${recipe.matchedCount}/${recipe.ingredients.length} matched',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.blue,
        ),
      ),
    );
  }
}

// ── Recipe card (vertical, full width) ────────────────────────────────────────

class RecipeCard extends ConsumerWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const RecipeCard({super.key, required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaved = ref.watch(
      savedRecipesProvider.select((s) => s.contains(recipe.id)),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroSection(recipe: recipe, isSaved: isSaved, ref: ref),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      DifficultyBadge(recipe.difficulty),
                      MatchBadge(recipe),
                      _TimeBadge(recipe.cookTimeMinutes),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final Recipe recipe;
  final bool isSaved;
  final WidgetRef ref;

  const _HeroSection({
    required this.recipe,
    required this.isSaved,
    required this.ref,
  });

  Color get _bgColor {
    switch (recipe.cuisine) {
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
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(recipe.imageEmoji, style: const TextStyle(fontSize: 52)),
          ),
          Positioned(
            top: 10,
            right: 12,
            child: GestureDetector(
              onTap: () => ref.read(savedRecipesProvider.notifier).toggle(recipe.id),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  size: 18,
                  color: isSaved ? AppColors.green : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final int minutes;
  const _TimeBadge(this.minutes);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(
          '$minutes min',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

// ── Horizontal recipe card (for carousels) ────────────────────────────────────

class RecipeCardHorizontal extends ConsumerWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const RecipeCardHorizontal({super.key, required this.recipe, required this.onTap});

  Color get _bgColor {
    switch (recipe.cuisine) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              alignment: Alignment.center,
              child: Text(recipe.imageEmoji, style: const TextStyle(fontSize: 36)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      DifficultyBadge(recipe.difficulty),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.cookTimeMinutes}m',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ingredient chip ────────────────────────────────────────────────────────────

class IngredientChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;

  const IngredientChip({super.key, required this.label, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close_rounded, size: 15, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.green,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
