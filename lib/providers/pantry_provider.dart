import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'pantry';

class PantryNotifier extends Notifier<List<String>> {
  late Box<String> _box;

  @override
  List<String> build() {
    _box = Hive.box<String>(_boxName);
    return _box.values.toList();
  }

  void addIngredient(String ingredient) {
    final cleaned = ingredient.trim().toLowerCase();
    if (cleaned.isEmpty || state.contains(cleaned)) return;
    _box.add(cleaned);
    state = [...state, cleaned];
  }

  void removeIngredient(String ingredient) {
    final idx = state.indexOf(ingredient);
    if (idx == -1) return;
    _box.deleteAt(idx);
    state = [...state]..removeAt(idx);
  }

  void clearAll() {
    _box.clear();
    state = [];
  }

  bool contains(String ingredient) => state.contains(ingredient.toLowerCase());
}

final pantryProvider = NotifierProvider<PantryNotifier, List<String>>(
  PantryNotifier.new,
);

// Open the Hive box — call this in main() before runApp
Future<void> openPantryBox() async {
  await Hive.openBox<String>(_boxName);
}
