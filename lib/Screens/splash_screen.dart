import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nli_apps/Screens/Driver/DriverDashboard.dart';
import 'package:nli_apps/Screens/Station/StationDashboard.dart';
import 'package:nli_apps/Screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screen Imports
// ignore: depend_on_referenced_packages
import 'package:nli_apps/Screens/Public/dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _slideUp;

  // New animation controller for the continuous zoom effect
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Colors
  static const Color startBlue = Color(0xFF42A5F5);
  static const Color endBlue = Color(0xFF0D47A1);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // ১. লোগো এনিমেশন
    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    // Continuous zoom in/out (pulse) animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ২. কন্টেন্ট ফেড ইন
    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    // ৩. নিচের দিক থেকে টেক্সট উঠে আসা
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(milliseconds: 4000));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final userType = prefs.getString('userType');

    Widget nextScreen;
    if (token == null || token.isEmpty) {
      nextScreen = const LoginPage();
    } else {
      if (userType == 'USER') {
        nextScreen = const DriverDashboard();
      } else if (userType == 'AGENT') {
        nextScreen = const StationDashboard();
      } else {
        nextScreen = const Dashboard();
      }
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000),
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Screen dimensions for responsiveness
    final size = MediaQuery.of(context).size;
    final double titleSize = size.width * 0.06; // Responsive font
    final double sloganSize = size.width * 0.045;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [startBlue, endBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ১. এনিমেটেড লোগো
                ScaleTransition(
                  // Continuous pulse effect
                  scale: _pulseAnimation,
                  child: ScaleTransition(
                    // Initial entrance scale effect
                    scale: _logoScale,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icons/icon.png',
                          height: size.width * 0.3,
                          width: size.width * 0.3,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Icon(
                            Icons.security,
                            size: size.width * 0.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ২. এনিমেটেড টেক্সট কন্টেন্ট
                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            'WMS CWallet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleSize * 1.2,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  offset: const Offset(3, 3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // সুন্দর ডিভাইডার লাইন
                          Container(
                            height: 4,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Fueling Your Journey',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: sloganSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Smart Solutions for Petrol Stations',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: sloganSize * 0.75,
                              fontStyle: FontStyle.italic,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
