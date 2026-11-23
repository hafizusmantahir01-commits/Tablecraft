import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Needed before using plugins (shared_preferences) in main().
  WidgetsFlutterBinding.ensureInitialized();
  // Show the Nunito font licence on the "Open source licenses" page.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Nunito font'], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  await StorageService.instance.init();
  // Phones and tablets stay upright.
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  runApp(const TablecraftApp());
}

class TablecraftApp extends StatelessWidget {
  const TablecraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tablecraft',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      scrollBehavior: const _AllInputsScrollBehavior(),
      builder: (context, child) => ColoredBox(
        color: const Color(0xFF3B2A1A), // dark wood around the app on wide screens
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxAppWidth),
            child: child,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/// By default Flutter on the web does not scroll lists with a mouse drag.
/// We allow mouse and trackpad too, so the piece tray scrolls on a computer.
class _AllInputsScrollBehavior extends MaterialScrollBehavior {
  const _AllInputsScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
