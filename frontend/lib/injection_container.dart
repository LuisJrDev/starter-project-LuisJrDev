import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'features/journalist_articles/data/data_sources/remote/journalist_firestore_service.dart';
import 'features/journalist_articles/data/data_sources/remote/journalist_storage_service.dart';
import 'features/journalist_articles/data/repository/journalist_article_repository_impl.dart';
import 'features/journalist_articles/domain/repository/journalist_article_repository.dart';
import 'features/journalist_articles/domain/usecases/add_comment.dart';
import 'features/journalist_articles/domain/usecases/create_article.dart';
import 'features/journalist_articles/domain/usecases/delete_article.dart';
import 'features/journalist_articles/domain/usecases/get_articles.dart';
import 'features/journalist_articles/domain/usecases/get_published_articles.dart';
import 'features/journalist_articles/domain/usecases/is_liked.dart';
import 'features/journalist_articles/domain/usecases/new_article_id.dart';
import 'features/journalist_articles/domain/usecases/publish_article.dart';
import 'features/journalist_articles/domain/usecases/toggle_like.dart';
import 'features/journalist_articles/domain/usecases/update_article.dart';
import 'features/journalist_articles/domain/usecases/upload_thumbnail.dart';
import 'features/journalist_articles/domain/usecases/watch_articles.dart';
import 'features/journalist_articles/domain/usecases/watch_comments.dart';
import 'features/journalist_articles/domain/usecases/watch_my_published_articles.dart';
import 'features/journalist_articles/domain/usecases/watch_published_articles.dart';
import 'features/journalist_articles/presentation/bloc/journalist_article/create/create_article_cubit.dart';
import 'features/journalist_articles/presentation/bloc/journalist_article/list/article_list_cubit.dart';
import 'features/journalist_articles/presentation/bloc/journalist_article/list/my_published_article_list_cubit.dart';
import 'features/journalist_articles/presentation/bloc/journalist_article/list/published_article_list_cubit.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  final prefs = await SharedPreferences.getInstance();

  sl.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  sl.registerSingleton<FirebaseStorage>(FirebaseStorage.instance);

  sl.registerSingleton<JournalistFirestoreService>(
    JournalistFirestoreService(sl()),
  );

  sl.registerLazySingleton(
    () => JournalistStorageService(FirebaseStorage.instance),
  );

  sl.registerSingleton<JournalistArticleRepository>(
    JournalistArticleRepositoryImpl(sl(), sl()),
  );

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

  sl.registerLazySingleton(() => UpdateJournalistArticleUseCase(sl()));

  sl.registerFactory(
    () => CreateArticleCubit(
      sl<NewJournalistArticleIdUseCase>(),
      sl<UploadJournalistThumbnailUseCase>(),
      sl<CreateJournalistArticleUseCase>(),
      sl<UpdateJournalistArticleUseCase>(),
      sl<PublishJournalistArticleUseCase>(),
      sl<FirebaseAuth>(),
      sl<UserProfileFirestoreService>(),
    ),
  );

  sl.registerSingleton<NewJournalistArticleIdUseCase>(
    NewJournalistArticleIdUseCase(sl()),
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

  sl.registerSingleton<WatchCommentsUseCase>(WatchCommentsUseCase(sl()));
  sl.registerSingleton<AddCommentUseCase>(AddCommentUseCase(sl()));

  sl.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);

  sl.registerSingleton<FirebaseAuthService>(
    FirebaseAuthService(sl<FirebaseAuth>()),
  );

  sl.registerSingleton<IsArticleLikedUseCase>(IsArticleLikedUseCase(sl()));
  sl.registerSingleton<ToggleArticleLikeUseCase>(
    ToggleArticleLikeUseCase(sl()),
  );

  sl.registerSingleton<UserProfileFirestoreService>(
    UserProfileFirestoreService(sl<FirebaseFirestore>()),
  );

  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      sl<FirebaseAuthService>(),
      sl<UserProfileFirestoreService>(),
    ),
  );

  sl.registerSingleton<WatchAuthStateUseCase>(
    WatchAuthStateUseCase(sl<AuthRepository>()),
  );
  sl.registerSingleton<SignInUseCase>(SignInUseCase(sl<AuthRepository>()));
  sl.registerSingleton<SignUpUseCase>(SignUpUseCase(sl<AuthRepository>()));
  sl.registerSingleton<SignOutUseCase>(SignOutUseCase(sl<AuthRepository>()));

  sl.registerFactory<AuthCubit>(() => AuthCubit(sl(), sl(), sl(), sl()));
}
