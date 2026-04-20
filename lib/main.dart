import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'screens/for_you_feed.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const ViralApp());
}

class ViralApp extends StatelessWidget {
  const ViralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viral',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const ForYouFeed(),
    );
  }
}
