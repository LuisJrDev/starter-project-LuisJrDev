import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/news_api_service.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/repository/article_repository_impl.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'core/device/device_id_service.dart';
import 'features/auth/data/data_sources/remote/firebase_auth_service.dart';
import 'features/auth/data/data_sources/remote/user_profile_firestore_service.dart';
import 'features/auth/data/repository/auth_repository_impl.dart';
import 'features/auth/domain/repository/auth_repository.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up.dart';
import 'features/auth/domain/usecases/watch_auth_state.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
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
import 'features/journalist_articles/domain/usecases/delete_article.dart';
import 'features/journalist_articles/domain/usecases/get_articles.dart';
import 'features/journalist_articles/domain/usecases/get_published_articles.dart';
import 'features/journalist_articles/domain/usecases/publish_article.dart';
import 'features/journalist_articles/domain/usecases/update_article.dart';
import 'features/journalist_articles/domain/usecases/upload_thumbnail.dart';
import 'features/journalist_articles/domain/usecases/watch_articles.dart';
import 'features/journalist_articles/domain/usecases/watch_my_published_articles.dart';
import 'features/journalist_articles/domain/usecases/watch_published_articles.dart';
import 'features/journalist_articles/presentation/bloc/journalist_article/create/create_article_cubit.dart';
import 'features/journalist_articles/presentation/bloc/journalist_article/list/article_list_cubit.dart';
import 'features/journalist_articles/presentation/bloc/journalist_article/list/my_published_article_list_cubit.dart';
import 'features/journalist_articles/presentation/bloc/journalist_article/list/published_article_list_cubit.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  final prefs = await SharedPreferences.getInstance();

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

  sl.registerLazySingleton(() => DeleteJournalistArticleUseCase(sl()));

  // Journalist feature - cubits
  sl.registerLazySingleton(() => UpdateJournalistArticleUseCase(sl()));
  sl.registerFactory(
    () => CreateArticleCubit(
      sl(),
      sl(),
      sl(),
      sl(),
      sl<FirebaseAuth>(),
      sl<UserProfileFirestoreService>(),
    ),
  );
  sl.registerFactory<ArticleListCubit>(() => ArticleListCubit(sl()));

  sl.registerSingleton<GetPublishedJournalistArticlesUseCase>(
    GetPublishedJournalistArticlesUseCase(sl()),
  );

  sl.registerSingleton<PublishJournalistArticleUseCase>(
    PublishJournalistArticleUseCase(sl()),
  );

  sl.registerFactory<PublishedArticleListCubit>(
    () => PublishedArticleListCubit(sl()),
  );

  sl.registerSingleton<WatchPublishedJournalistArticlesUseCase>(
    WatchPublishedJournalistArticlesUseCase(sl()),
  );

  sl.registerSingleton<WatchJournalistArticlesUseCase>(
    WatchJournalistArticlesUseCase(sl()),
  );

  sl.registerSingleton<WatchMyPublishedJournalistArticlesUseCase>(
    WatchMyPublishedJournalistArticlesUseCase(sl()),
  );

  sl.registerFactory<MyPublishedArticleListCubit>(
    () => MyPublishedArticleListCubit(sl()),
  );
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerSingleton<Uuid>(const Uuid());
  sl.registerSingleton<DeviceIdService>(DeviceIdService(sl(), sl()));

  // Firebase Auth instance
  sl.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);

  // Auth feature - data source
  sl.registerSingleton<FirebaseAuthService>(
    FirebaseAuthService(sl<FirebaseAuth>()),
  );

  // Auth feature - Firestore profile service  ✅ primero
  sl.registerSingleton<UserProfileFirestoreService>(
    UserProfileFirestoreService(sl<FirebaseFirestore>()),
  );

  // Auth feature - repository ✅ después
  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      sl<FirebaseAuthService>(),
      sl<UserProfileFirestoreService>(),
    ),
  );

  // Auth feature - usecases
  sl.registerSingleton<WatchAuthStateUseCase>(
    WatchAuthStateUseCase(sl<AuthRepository>()),
  );
  sl.registerSingleton<SignInUseCase>(SignInUseCase(sl<AuthRepository>()));
  sl.registerSingleton<SignUpUseCase>(SignUpUseCase(sl<AuthRepository>()));
  sl.registerSingleton<SignOutUseCase>(SignOutUseCase(sl<AuthRepository>()));

  // Auth feature - cubit
  sl.registerFactory<AuthCubit>(() => AuthCubit(sl(), sl(), sl(), sl()));
}
