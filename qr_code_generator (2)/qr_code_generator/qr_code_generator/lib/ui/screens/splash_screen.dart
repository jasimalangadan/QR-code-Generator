import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'generator_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _showText = false;
  bool _showLoader = false;

  @override
  void initState() {
    super.initState();

    // Premium custom animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Start splash animations
    _controller.forward();

    // Delayed steps for premium staggered feel
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showText = true;
        });
      }
    });

    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _showLoader = true;
        });
      }
    });

    // Auto navigate after 2.5 seconds
    Timer(const Duration(milliseconds: 2600), _navigateToHome);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (!mounted) return;

    // Premium Fade & Scale page transition to the main Generator Screen
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GeneratorScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeTransition = FadeTransition(
            opacity: animation,
            child: child,
          );

          return ScaleTransition(
            scale: Tween<double>(begin: 1.05, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: fadeTransition,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Premium Gradient Layout
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F0C20), // Premium cosmic dark purple
                  Color(0xFF231E47), // Luxurious mid-tone plum
                  Color(0xFF3B2E75), // Rich royal purple
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Glowing background circles for visual depth (wow factor)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryPurple.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFFE1306C,
                ).withValues(alpha: 0.08), // Soft pink glow
              ),
            ),
          ),

          // Central Animated Graphic & Logo Group
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Elegant Rounded Glassmorphic Icon Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 82,
                              height: 82,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Animated Text Elements (QR Makers + Subtitle)
                  AnimatedOpacity(
                    opacity: _showText ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOut,
                    child: AnimatedSlide(
                      offset: _showText ? Offset.zero : const Offset(0, 0.2),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOut,
                      child: const Column(
                        children: [
                          Text(
                            'QR Makers',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Crafting your brand identity...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFC3C5D8),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom loading section for staggered elegant appearance
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showLoader ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
