import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/pos/pos_screen.dart';
import 'features/splash/splash_screen.dart';

/// Widget raíz de la aplicación.
class BobVentasApp extends StatelessWidget {
  const BobVentasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bob Ventas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
