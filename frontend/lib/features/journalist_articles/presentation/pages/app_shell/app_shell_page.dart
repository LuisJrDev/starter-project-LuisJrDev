import 'package:flutter/material.dart';

import '../../../data/data_sources/local/saved_articles_local_store.dart';
import '../../controllers/saved_articles_controller.dart';
import '../add_article/add_article_page.dart';
import '../feed/article_feed_page.dart';
import '../profile/profile_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _index = 0;
  int _createKey = 0;
  // 0 Drafts, 1 Published
  int _profileInitialTabIndex = 0;

  final GlobalKey<ArticleFeedPageState> _feedKey = GlobalKey();

  // Bookmarks local (single instance for whole app)
  late final SavedArticlesController _saved = SavedArticlesController(
    SavedArticlesLocalStore(),
  );

  @override
  void initState() {
    super.initState();
    _saved.load();
  }

  @override
  void dispose() {
    _saved.dispose();
    super.dispose();
  }

  void _goToFeed({bool scrollToTop = false}) {
    setState(() => _index = 0);
    if (scrollToTop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _feedKey.currentState?.scrollToTop();
      });
    }
  }

  void _goToProfileDrafts() => setState(() {
    _profileInitialTabIndex = 0;
    _index = 2;
  });

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      ArticleFeedPage(key: _feedKey, saved: _saved),

      AddArticlePage(
        key: ValueKey('create-$_createKey'),
        onResult: (result) {
          if (result == AddArticleResult.published) {
            _goToFeed(scrollToTop: true);
          } else {
            _goToProfileDrafts();
          }
        },
      ),

      ProfilePage(
        key: ValueKey('profile-$_profileInitialTabIndex'),
        initialTabIndex: _profileInitialTabIndex,
        saved: _saved,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == _index && i == 0) {
            _goToFeed(scrollToTop: true);
            return;
          }

          setState(() {
            if (i == 1) _createKey++; // entra a Create => form fresh
            _index = i;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.smart_display_outlined),
            selectedIcon: Icon(Icons.smart_display),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
