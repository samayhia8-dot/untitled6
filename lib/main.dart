import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/ notes/ cubit/notes_cubit.dart';
import 'features/ notes/data/notes_repository.dart';
import 'features/ notes/presentation/notes_page.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => NotesRepository(),
      child: BlocProvider(
        create: (context) =>
        NotesCubit(context.read<NotesRepository>())
          ..listenToNotes(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Notes CRUD',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3157A4),
            ),
            scaffoldBackgroundColor:
            const Color(0xFFF6F7FB),
          ),
          home: const NotesPage(),
        ),
      ),
    );
  }
}