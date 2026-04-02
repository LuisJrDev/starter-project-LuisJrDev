import 'package:flutter/material.dart';

import '../add_article/add_article_page.dart';
import '../my_articles/my_articles_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _index = 0;

  final _pages = const <Widget>[
    _FeedPlaceholderPage(),
    AddArticlePage(),
    MyArticlesPage(),
    _SettingsPlaceholderPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _FeedPlaceholderPage extends StatelessWidget {
  const _FeedPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: const Center(
        child: Text(
          'Next commit: TikTok-style vertical feed (published articles).',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _SettingsPlaceholderPage extends StatelessWidget {
  const _SettingsPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Text(
          'Next commits: Apple News reader settings.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
