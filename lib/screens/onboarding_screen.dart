import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pantry_provider.dart';
import '../theme/app_theme.dart';

/// Staple ingredients shown on the onboarding screen, grouped by category.
const _staples = {
  'Pantry basics': [
    ('🧄', 'garlic'),
    ('🧅', 'onion'),
    ('🍅', 'tomatoes'),
    ('🥚', 'eggs'),
    ('🥛', 'milk'),
    ('🧈', 'butter'),
    ('🫒', 'olive oil'),
    ('🍚', 'rice'),
    ('🍝', 'pasta'),
    ('🍞', 'bread'),
  ],
  'Fridge staples': [
    ('🧀', 'cheese'),
    ('🐔', 'chicken'),
    ('🥩', 'beef'),
    ('🐟', 'fish'),
    ('🥕', 'carrots'),
    ('🥦', 'broccoli'),
    ('🫑', 'bell pepper'),
    ('🌿', 'spinach'),
    ('🍋', 'lemon'),
    ('🥜', 'peanut butter'),
  ],
  'Spices & sauces': [
    ('🧂', 'salt'),
    ('🌶️', 'chili'),
    ('🟤', 'cumin'),
    ('🌿', 'oregano'),
    ('🍶', 'soy sauce'),
    ('🍯', 'honey'),
    ('🥫', 'canned tomatoes'),
    ('🫙', 'chickpeas'),
    ('🌰', 'flour'),
    ('🍬', 'sugar'),
  ],
};

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final Set<String> _selected = {};

  void _toggle(String ingredient) {
    setState(() {
      if (_selected.contains(ingredient)) {
        _selected.remove(ingredient);
      } else {
        _selected.add(ingredient);
      }
    });
  }

  void _finish() {
    final notifier = ref.read(pantryProvider.notifier);
    for (final ing in _selected) {
      notifier.addIngredient(ing);
    }
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('👋', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  const Text(
                    "What's in your kitchen?",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pick your staples and we\'ll find recipes you can make right now.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (_selected.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${_selected.length} ingredient${_selected.length == 1 ? '' : 's'} selected',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.cardBorder),

            // ── Scrollable staples ───────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                children: _staples.entries.map((entry) {
                  return _StapleGroup(
                    category: entry.key,
                    items: entry.value,
                    selected: _selected,
                    onToggle: _toggle,
                  );
                }).toList(),
              ),
            ),

            // ── Bottom CTA ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: AppColors.cream,
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 0.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _selected.isEmpty
                            ? "Skip for now →"
                            : "Let's cook! →",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (_selected.isEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'You can always add ingredients from the home screen',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StapleGroup extends StatelessWidget {
  final String category;
  final List<(String, String)> items;
  final Set<String> selected;
  final void Function(String) onToggle;

  const _StapleGroup({
    required this.category,
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Text(
            category.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final (emoji, name) = item;
            final isSelected = selected.contains(name);
            return GestureDetector(
              onTap: () => onToggle(name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.greenLight : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.green
                        : AppColors.cardBorder,
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.green
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check_rounded,
                          size: 14, color: AppColors.green),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}