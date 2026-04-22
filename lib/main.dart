import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/pantry_provider.dart';
import 'providers/shopping_list_provider.dart';
import 'screens/home_screen.dart';
import 'screens/browse_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/shopping_list_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

const _onboardingBox = 'prefs';
const _onboardingKey = 'hasSeenOnboarding';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await openPantryBox();
  await openShoppingListBox();
  await Hive.openBox<bool>(_onboardingBox);
  runApp(const ProviderScope(child: KitchenMatchApp()));
}

class KitchenMatchApp extends StatelessWidget {
  const KitchenMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KitchenMatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;
  bool _onboardingDone = false;

  static const _screens = [
    HomeScreen(),
    SavedScreen(),
    ShoppingListScreen(),
    BrowseScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final box = Hive.box<bool>(_onboardingBox);
    _onboardingDone = box.get(_onboardingKey, defaultValue: false)!;
  }

  void _completeOnboarding() {
    final box = Hive.box<bool>(_onboardingBox);
    box.put(_onboardingKey, true);
    setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_onboardingDone) {
      return OnboardingScreen(onDone: _completeOnboarding);
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(color: Color(0xFFE0DDD6), width: 0.5)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Kitchen',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_outline_rounded),
              selectedIcon: Icon(Icons.bookmark_rounded),
              label: 'Saved',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart_rounded),
              label: 'Shopping',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Browse',
            ),
          ],
        ),
      ),
    );
  }
}