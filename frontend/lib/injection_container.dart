import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/news_api_service.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/repository/article_repository_impl.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'features/daily_news/data/data_sources/local/app_database.dart';
import 'features/daily_news/domain/usecases/get_saved_article.dart';
import 'features/daily_news/domain/usecases/remove_article.dart';
import 'features/daily_news/domain/usecases/save_article.dart';
import 'features/daily_news/presentation/bloc/article/local/local_article_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'features/journalist_articles/data/data_sources/remote/journalist_firestore_service.dart';
import 'features/journalist_articles/data/data_sources/remote/journalist_storage_service.dart';
import 'features/journalist_articles/data/repository/journalist_article_repository_impl.dart';
import 'features/journalist_articles/domain/repository/journalist_article_repository.dart';
import 'features/journalist_articles/domain/usecases/create_article.dart';
import 'features/journalist_articles/domain/usecases/get_articles.dart';
import 'features/journalist_articles/domain/usecases/upload_thumbnail.dart';
import 'features/journalist_articles/presentation/bloc/journalist_article/create/create_article_cubit.dart';
import 'features/journalist_articles/presentation/bloc/journalist_article/list/article_list_cubit.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  final database = await $FloorAppDatabase
      .databaseBuilder('app_database.db')
      .build();
  sl.registerSingleton<AppDatabase>(database);

  // Dio
  sl.registerSingleton<Dio>(Dio());

  // Dependencies
  sl.registerSingleton<NewsApiService>(NewsApiService(sl()));

  sl.registerSingleton<ArticleRepository>(ArticleRepositoryImpl(sl(), sl()));

  //UseCases
  sl.registerSingleton<GetArticleUseCase>(GetArticleUseCase(sl()));

  sl.registerSingleton<GetSavedArticleUseCase>(GetSavedArticleUseCase(sl()));

  sl.registerSingleton<SaveArticleUseCase>(SaveArticleUseCase(sl()));

  sl.registerSingleton<RemoveArticleUseCase>(RemoveArticleUseCase(sl()));

  //Blocs
  sl.registerFactory<RemoteArticlesBloc>(() => RemoteArticlesBloc(sl()));

  sl.registerFactory<LocalArticleBloc>(
    () => LocalArticleBloc(sl(), sl(), sl()),
  );

  // Firebase instances
  sl.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  sl.registerSingleton<FirebaseStorage>(FirebaseStorage.instance);

  // Journalist feature - data sources
  sl.registerSingleton<JournalistFirestoreService>(
    JournalistFirestoreService(sl()),
  );
  sl.registerSingleton<JournalistStorageService>(
    JournalistStorageService(sl()),
  );

  // Journalist feature - repository
  sl.registerSingleton<JournalistArticleRepository>(
    JournalistArticleRepositoryImpl(sl(), sl()),
  );

  // Journalist feature - usecases
  sl.registerSingleton<GetJournalistArticlesUseCase>(
    GetJournalistArticlesUseCase(sl()),
  );
  sl.registerSingleton<UploadJournalistThumbnailUseCase>(
    UploadJournalistThumbnailUseCase(sl()),
  );
  sl.registerSingleton<CreateJournalistArticleUseCase>(
    CreateJournalistArticleUseCase(sl()),
  );

  // Journalist feature - cubits
  sl.registerFactory<CreateArticleCubit>(
    () => CreateArticleCubit(sl(), sl(), sl()),
  );
  sl.registerFactory<ArticleListCubit>(() => ArticleListCubit(sl()));
}
