import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'controllers/settings_controller.dart';
import 'ads/ad_engine.dart';
import 'screens/feed_screen.dart';
import 'theme/tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  ));

  // Create AdEngine and fire cold-open trigger
  final adEngine = AdEngine()..onAppStart();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider<AdEngine>.value(value: adEngine),
      ],
      child: const ReelzApp(),
    ),
  );
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
        // Slider theme — applied globally
        sliderTheme: SliderThemeData(
          trackHeight: 2.5,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          activeTrackColor: RColors.brand,
          inactiveTrackColor: RColors.glassMd,
          thumbColor: Colors.white,
          overlayColor: RColors.brand.withOpacity(0.18),
        ),
        // Switch theme
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? Colors.white : RColors.text3),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? RColors.brand.withOpacity(0.7)
                  : RColors.glass),
          trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? Colors.transparent
                  : RColors.glassBorderMd),
        ),
      ),
      home: const FeedScreen(),
    );
  }
}
