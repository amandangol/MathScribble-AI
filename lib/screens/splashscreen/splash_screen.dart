import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _titleOpacityAnimation;
  late Animation<double> _taglineOpacityAnimation;
  late Animation<double> _progressOpacityAnimation;
  late Animation<double> _backgroundScaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Logo animations
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Title animations
    _titleSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _titleOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    // Tagline and progress animations
    _taglineOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.easeInOut),
      ),
    );

    _progressOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Background animation
    _backgroundScaleAnimation = Tween<double>(begin: 1.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    // Navigate after animation completes
    Future.delayed(const Duration(milliseconds: 4000), () {
      _checkFirstLaunch();
    });
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (!mounted) return;

    if (isFirstLaunch) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.purple.shade50,
                  Colors.white,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
            child: Transform.scale(
              scale: _backgroundScaleAnimation.value,
              child: Stack(
                children: [
                  // Background mathematical symbols
                  ..._buildBackgroundSymbols(),

                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Opacity(
                          opacity: _logoOpacityAnimation.value,
                          child: Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3F51B5)
                                        .withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                "assets/images/mathlogo.png",
                                height: 100,
                                color: const Color(0xFF3F51B5),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Title
                        Transform.translate(
                          offset: Offset(0, _titleSlideAnimation.value),
                          child: Opacity(
                            opacity: _titleOpacityAnimation.value,
                            child: const Text(
                              'MathScribe AI',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tagline
                        Opacity(
                          opacity: _taglineOpacityAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF3F51B5).withOpacity(0.1),
                              ),
                            ),
                            child: const Text(
                              'Draw • Recognize • Learn',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18,
                                color: Color(0xFF3F51B5),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Progress Indicator
                        Opacity(
                          opacity: _progressOpacityAnimation.value,
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF3F51B5),
                              ),
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildBackgroundSymbols() {
    return [
      Positioned(
        top: 100,
        left: 40,
        child: _buildMathSymbol('∑', 0.2),
      ),
      Positioned(
        top: 200,
        right: 60,
        child: _buildMathSymbol('∫', 0.3),
      ),
      Positioned(
        bottom: 150,
        left: 80,
        child: _buildMathSymbol('π', 0.4),
      ),
      Positioned(
        bottom: 200,
        right: 40,
        child: _buildMathSymbol('θ', 0.5),
      ),
    ];
  }

  Widget _buildMathSymbol(String symbol, double delay) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, delay + 0.3, curve: Curves.easeInOut),
      ),
    );

    return Opacity(
      opacity: animation.value,
      child: Text(
        symbol,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 48,
          color: const Color(0xFF3F51B5).withOpacity(0.1),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
