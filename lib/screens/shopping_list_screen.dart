import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shopping_list_provider.dart';
import '../theme/app_theme.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _showInput = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      ref.read(shoppingListProvider.notifier).addItem(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(shoppingListProvider);
    final unchecked = items.where((i) => !i.checked).toList();
    final checked = items.where((i) => i.checked).toList();
    final hasChecked = checked.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── App bar ───────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.cream,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 90,
            collapsedHeight: 60,
            actions: [
              if (hasChecked)
                TextButton(
                  onPressed: () =>
                      ref.read(shoppingListProvider.notifier).clearChecked(),
                  child: const Text(
                    'Clear done',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (items.isNotEmpty && !hasChecked)
                TextButton(
                  onPressed: () =>
                      ref.read(shoppingListProvider.notifier).clearAll(),
                  child: const Text(
                    'Clear all',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Shopping list',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Tap an item to check it off',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // ── Add item bar ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _showInput
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focus,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'e.g. olive oil, lemons...',
                              prefixIcon:
                                  Icon(Icons.add_shopping_cart_rounded, size: 18),
                            ),
                            onSubmitted: (_) => _add(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _add,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _showInput = false),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.cardBorder, width: 0.5),
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 20, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: () {
                        setState(() => _showInput = true);
                        Future.delayed(
                          const Duration(milliseconds: 80),
                          () => _focus.requestFocus(),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.cardBorder, width: 0.5),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_rounded,
                                size: 18, color: AppColors.textMuted),
                            SizedBox(width: 10),
                            Text(
                              'Add item...',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          // ── Empty state ───────────────────────────────────────────────────
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🛒', style: TextStyle(fontSize: 52)),
                    const SizedBox(height: 16),
                    const Text(
                      'Your list is empty',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Add items above, or tap "Add missing"\non any recipe to fill it instantly',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

          // ── Unchecked items ───────────────────────────────────────────────
          if (unchecked.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: unchecked.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final globalIndex = items.indexOf(unchecked[i]);
                  return _ShoppingItemTile(
                    item: unchecked[i],
                    onToggle: () => ref
                        .read(shoppingListProvider.notifier)
                        .toggleItem(globalIndex),
                    onDelete: () => ref
                        .read(shoppingListProvider.notifier)
                        .removeItem(globalIndex),
                  );
                },
              ),
            ),

          // ── Checked items ─────────────────────────────────────────────────
          if (hasChecked) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Text(
                  'IN THE CART (${checked.length})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: checked.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final globalIndex = items.indexOf(checked[i]);
                  return _ShoppingItemTile(
                    item: checked[i],
                    onToggle: () => ref
                        .read(shoppingListProvider.notifier)
                        .toggleItem(globalIndex),
                    onDelete: () => ref
                        .read(shoppingListProvider.notifier)
                        .removeItem(globalIndex),
                  );
                },
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ShoppingItemTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.name),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFD85A30), size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: item.checked ? const Color(0xFFF5F5F3) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color:
                      item.checked ? AppColors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: item.checked
                        ? AppColors.green
                        : AppColors.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: item.checked
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: item.checked
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    decoration:
                        item.checked ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}