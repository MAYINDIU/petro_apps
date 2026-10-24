import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:petro_app/Screens/splash_screen.dart';

// Define color constants
const kPrimaryColor = Color(0xFF1E40AF);
const kAccentColor = Color(0xFF3B82F6);
const kSecondaryColor = Color(0xFF004D40);
const kTextColor = Color(0xFF212121);

// Width of the centered app frame when running on a wide screen (browser).
const double kAppFrameWidth = 460;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimaryColor,
        primary: kPrimaryColor,
        secondary: kAccentColor,
      ),
      primaryColor: kPrimaryColor,
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WMS CWallet',
      builder: (context, child) => _WebFrame(child: child),
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      home: const SplashScreen(), // Set SplashScreen as initial screen
    );
  }
}

/// On wide screens (desktop browsers) shows the mobile app inside a centered,
/// phone-width frame on a branded background, so every screen keeps its
/// mobile layout (drawer, grids, forms) instead of stretching edge to edge.
class _WebFrame extends StatelessWidget {
  final Widget? child;
  const _WebFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= kAppFrameWidth + 80 || child == null) {
      return child ?? const SizedBox.shrink();
    }

    final frameHeight = (media.size.height - 48).clamp(560.0, 940.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2A6B), kPrimaryColor, kAccentColor],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _blob(320, Colors.white.withOpacity(0.06)),
          ),
          Positioned(
            bottom: -140,
            right: -100,
            child: _blob(380, Colors.white.withOpacity(0.05)),
          ),
          Center(
            child: Container(
              width: kAppFrameWidth,
              height: frameHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 40,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: MediaQuery(
                  data: media.copyWith(size: Size(kAppFrameWidth, frameHeight)),
                  child: child!,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
