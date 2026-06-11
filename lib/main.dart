import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MemoirApp(),
    ),
  );
}

class MemoirApp extends StatelessWidget {
  const MemoirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memoir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(
          child: Text('Memoir ✨'),
        ),
      ),
    );
  }
}
