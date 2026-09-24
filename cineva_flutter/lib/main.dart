import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/ai_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_list_screen.dart';
import 'screens/search_screen.dart';
import 'stores/bookmark_store.dart';
import 'stores/chat_store.dart';
import 'stores/search_history_store.dart';
import 'stores/watch_history_store.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const CinevaApp());
}

class CinevaApp extends StatelessWidget {
  const CinevaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cineva',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const CinevaHome(),
    );
  }
}

class CinevaHome extends StatefulWidget {
  const CinevaHome({super.key});

  @override
  State<CinevaHome> createState() => _CinevaHomeState();
}

class _CinevaHomeState extends State<CinevaHome> with TickerProviderStateMixin {
  int _index = 0;
  late final List<AnimationController> _dotControllers;

  static const _tabs = [
    HomeScreen(),
    ExploreScreen(),
    SearchScreen(),
    AiScreen(),
    MyListScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _dotControllers = List.generate(
      5,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380),
      ),
    );
    BookmarkStore.instance.load();
    SearchHistoryStore.instance.load();
    ChatStore.instance.load();
    WatchHistoryStore.instance.load();
  }

  @override
  void dispose() {
    for (final c in _dotControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabTap(int i) {
    if (i == _index) {
      _dotControllers[i].forward(from: 0);
      return;
    }
    setState(() => _index = i);
    _dotControllers[i].forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _navItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _navItem(1, Icons.explore_outlined, Icons.explore, 'Explore'),
              _navItem(2, Icons.search, Icons.search, 'Search'),
              _navItem(3, Icons.auto_awesome_outlined, Icons.auto_awesome, 'AI'),
              _navItem(4, Icons.bookmark_border, Icons.bookmark, 'My List'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final active = _index == index;
    final controller = _dotControllers[index];
    return Expanded(
      child: Semantics(
        selected: active,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onTabTap(index),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final t = controller.value;
              final scale = 1 + 0.18 * t;
              final dy = -3 * t;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: Offset(0, dy),
                    child: Transform.scale(
                      scale: scale,
                      child: Icon(
                        active ? activeIcon : icon,
                        size: 23,
                        color: active
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    width: active ? 20 : 4,
                    height: 3,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}