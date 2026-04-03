import 'package:flutter/material.dart';

import '../../controllers/saved_articles_controller.dart';
import '../../widgets/my_articles_section.dart';

class ProfilePage extends StatelessWidget {
  final int initialTabIndex;

  final SavedArticlesController saved;

  const ProfilePage({super.key, this.initialTabIndex = 0, required this.saved});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Juan',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Journalist • Drafts & Published articles',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: MyArticlesSection(
              initialTabIndex: initialTabIndex,
              saved: saved,
            ),
          ),
        ],
      ),
    );
  }
}
