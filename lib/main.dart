import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'screens/feed_screen.dart';
import 'theme/tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  runApp(const ReelzApp());
}

class ReelzApp extends StatelessWidget {
  const ReelzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reelz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: RColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: RColors.brand,
          secondary: RColors.brand2,
          surface: RColors.bgSurface,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const FeedScreen(),
    );
  }
}
