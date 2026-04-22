import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _shoppingBoxName = 'shopping_list';

class ShoppingItem {
  final String name;
  final bool checked;

  const ShoppingItem({required this.name, this.checked = false});

  ShoppingItem copyWith({bool? checked}) =>
      ShoppingItem(name: name, checked: checked ?? this.checked);

  // Simple string encoding: "0|tomatoes" / "1|tomatoes"
  String encode() => '${checked ? 1 : 0}|$name';

  static ShoppingItem decode(String raw) {
    final sep = raw.indexOf('|');
    if (sep == -1) return ShoppingItem(name: raw);
    return ShoppingItem(
      checked: raw.substring(0, sep) == '1',
      name: raw.substring(sep + 1),
    );
  }
}

class ShoppingListNotifier extends Notifier<List<ShoppingItem>> {
  late Box<String> _box;

  @override
  List<ShoppingItem> build() {
    _box = Hive.box<String>(_shoppingBoxName);
    return _box.values.map(ShoppingItem.decode).toList();
  }

  void addItem(String name) {
    final cleaned = name.trim().toLowerCase();
    if (cleaned.isEmpty) return;
    if (state.any((i) => i.name == cleaned)) return;
    final item = ShoppingItem(name: cleaned);
    _box.add(item.encode());
    state = [...state, item];
  }

  /// Adds multiple items at once (used by "Add missing" from recipe detail).
  /// Returns the count of newly added items (skips duplicates).
  int addAll(List<String> names) {
    int added = 0;
    final updated = [...state];
    for (final name in names) {
      final cleaned = name.trim().toLowerCase();
      if (cleaned.isEmpty) continue;
      if (updated.any((i) => i.name == cleaned)) continue;
      final item = ShoppingItem(name: cleaned);
      _box.add(item.encode());
      updated.add(item);
      added++;
    }
    state = updated;
    return added;
  }

  void toggleItem(int index) {
    final updated = [...state];
    updated[index] = updated[index].copyWith(checked: !updated[index].checked);
    _box.putAt(index, updated[index].encode());
    state = updated;
  }

  void removeItem(int index) {
    _box.deleteAt(index);
    final updated = [...state]..removeAt(index);
    state = updated;
  }

  void clearChecked() {
    // Remove checked items from back to front to keep indices stable
    final indices = <int>[];
    for (int i = state.length - 1; i >= 0; i--) {
      if (state[i].checked) indices.add(i);
    }
    for (final i in indices) {
      _box.deleteAt(i);
    }
    state = state.where((i) => !i.checked).toList();
  }

  void clearAll() {
    _box.clear();
    state = [];
  }
}

final shoppingListProvider =
    NotifierProvider<ShoppingListNotifier, List<ShoppingItem>>(
  ShoppingListNotifier.new,
);

Future<void> openShoppingListBox() async {
  await Hive.openBox<String>(_shoppingBoxName);
}