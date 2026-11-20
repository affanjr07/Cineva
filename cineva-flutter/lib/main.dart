import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/ai_screen.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/explore_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_list_screen.dart';
import 'screens/search_screen.dart';
import 'services/auth_service.dart';
import 'stores/bookmark_store.dart';
import 'stores/chat_store.dart';
import 'stores/search_history_store.dart';
import 'stores/watch_history_store.dart';
import 'theme/app_theme.dart';
import 'utils/routes.dart';
import 'widgets/cineva_nav_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await AuthService.instance.initialize();
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
      darkTheme: buildAppTheme(),
      themeMode: ThemeMode.dark,
      navigatorObservers: [cinevaRouteObserver],
      home: const AuthGate(authenticated: CinevaHome()),
    );
  }
}

class CinevaHome extends StatefulWidget {
  const CinevaHome({super.key});

  @override
  State<CinevaHome> createState() => _CinevaHomeState();
}

class _CinevaHomeState extends State<CinevaHome> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    BookmarkStore.instance.load();
    SearchHistoryStore.instance.load();
    ChatStore.instance.load();
    WatchHistoryStore.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            isActive: _index == 0,
            onOpenSearch: () => setState(() => _index = 2),
            onOpenMyList: () => setState(() => _index = 4),
          ),
          const ExploreScreen(),
          const SearchScreen(),
          const AiScreen(),
          MyListScreen(onExplore: () => setState(() => _index = 1)),
        ],
      ),
      bottomNavigationBar: CinevaNavBar(
        currentIndex: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}
