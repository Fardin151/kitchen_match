import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recipe_provider.dart';
import '../widgets/shared_widgets.dart';
import 'recipe_detail_screen.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedRecipesProvider);
    final recipesAsync = ref.watch(allRecipesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved recipes')),
      body: recipesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        data: (all) {
          final saved = all.where((r) => savedIds.contains(r.id)).toList();
          if (saved.isEmpty) {
            return const EmptyState(
              emoji: '🔖',
              title: 'No saved recipes',
              subtitle: 'Tap the bookmark icon on any recipe to save it here',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: saved.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => RecipeCard(
              recipe: saved[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(recipe: saved[i])),
              ),
            ),
          );
        },
      ),
    );
  }
}
