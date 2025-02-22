import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Smart Math Recognition',
      description:
          'Transform your handwritten mathematical expressions into digital format instantly with our multiple advanced AI recognition.',
      image: 'assets/images/onboard1.png',
      backgroundColor: const Color(0xFFF0F3FF),
      iconData: Icons.auto_awesome,
      gradient: [Colors.blue.shade50, Colors.purple.shade50],
    ),
    OnboardingPage(
      title: 'Multiple Drawing Tools',
      description:
          'Choose from various grid types including square, coordinate, and isometric. Customize colors and stroke widths for precise math work.',
      image: 'assets/images/onboard22.png',
      backgroundColor: const Color(0xFFF0F3FF),
      iconData: Icons.grid_4x4,
      gradient: [Colors.purple.shade50, Colors.indigo.shade50],
    ),
    OnboardingPage(
      title: 'Step-by-Step Solutions',
      description:
          'Get detailed explanations for each step of your mathematical solutions, helping you understand the concepts better.',
      image: 'assets/images/onboard3.jpg',
      backgroundColor: const Color(0xFFF0F3FF),
      iconData: Icons.psychology,
      gradient: [Colors.indigo.shade50, Colors.blue.shade50],
    ),
    OnboardingPage(
      title: 'Track Your Progress',
      description:
          'Keep track of all your solved problems with a comprehensive history. Review and learn from your past calculations.',
      image: 'assets/images/onboard4.jpg',
      backgroundColor: const Color(0xFFF0F3FF),
      iconData: Icons.insights,
      gradient: [Colors.blue.shade50, Colors.purple.shade50],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          Positioned(
            top: 48,
            right: 16,
            child: TextButton(
              onPressed: _finishOnboarding,
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 16,
                  color: Color(0xFF3F51B5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildDot(index),
                  ),
                ),
                const SizedBox(height: 32),
                _buildButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: page.gradient,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            if (page.image.isNotEmpty)
              Container(
                height: 280,
                width: 280,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3F51B5).withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  page.image,
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3F51B5).withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  page.iconData,
                  size: 120,
                  color: const Color(0xFF3F51B5),
                ),
              ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                page.title,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                page.description,
                style: const TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 16,
                  color: Color(0xFF3F51B5),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? const Color(0xFF3F51B5)
            : const Color(0xFF3F51B5).withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _currentPage > 0
              ? TextButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text(
                    'Previous',
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 16,
                      color: Color(0xFF3F51B5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : const SizedBox(width: 80),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3F51B5).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _currentPage < _pages.length - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : _finishOnboarding,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentPage < _pages.length - 1
                            ? 'Next'
                            : 'Get Started',
                        style: const TextStyle(
                          fontFamily: 'OpenSans',
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
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

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  final Color backgroundColor;
  final IconData iconData;
  final List<Color> gradient;

  OnboardingPage({
    required this.title,
    required this.description,
    this.image = '',
    required this.backgroundColor,
    required this.iconData,
    required this.gradient,
  });
}
