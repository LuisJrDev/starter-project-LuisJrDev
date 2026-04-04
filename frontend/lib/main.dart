import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/theme/app_themes.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/auth_gate.dart';
import 'firebase_options.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await connectToEmulators();
  await initializeDependencies();

  runApp(const MyApp());
}

Future<void> connectToEmulators() async {
  if (kReleaseMode) return;

  const host = '10.0.2.2';

  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseStorage.instance.useStorageEmulator(host, 9199);
  FirebaseAuth.instance.useAuthEmulator(host, 9099);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => sl<AuthCubit>()..start(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme(),
        darkTheme: darkTheme(),
        themeMode: ThemeMode.dark,
        home: const AuthGate(),
      ),
    );
  }
}
