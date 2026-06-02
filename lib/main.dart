import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'ads/ad_engine.dart';
import 'controllers/feed_controller.dart';
import 'controllers/settings_controller.dart';
import 'screens/main_shell.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/coin_service.dart';
import 'theme/tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: RColors.bg,
  ));
  runApp(const ReelzApp());
}

class ReelzApp extends StatelessWidget {
  const ReelzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()..init()),
        ChangeNotifierProvider(create: (_) => CoinService()..init()),
        ChangeNotifierProvider(create: (_) => AdEngine()),
        ChangeNotifierProvider(create: (_) => FeedController()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: MaterialApp(
        title: 'Reelz',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: RColors.bg,
          colorScheme: const ColorScheme.dark(
            primary: RColors.brand,
            secondary: RColors.brand2,
            surface: RColors.bgCard,
          ),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        home: const MainShell(),
      ),
    );
  }
}
