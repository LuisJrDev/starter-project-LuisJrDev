import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../injection_container.dart';
import '../../bloc/journalist_article/list/article_list_cubit.dart';
import '../../bloc/journalist_article/list/article_list_state.dart';

class MyArticlesPage extends StatelessWidget {
  const MyArticlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ArticleListCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('My Articles')),
        body: BlocBuilder<ArticleListCubit, ArticleListState>(
          builder: (context, state) {
            if (state is ArticleListLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ArticleListError) {
              return Center(child: Text(state.message));
            }
            if (state is ArticleListLoaded) {
              if (state.articles.isEmpty) {
                return const Center(child: Text('No articles yet'));
              }
              return ListView.separated(
                itemCount: state.articles.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final a = state.articles[index];
                  return ListTile(
                    title: Text(a.title),
                    subtitle: Text('${a.status} • ${a.authorName}'),
                  );
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
