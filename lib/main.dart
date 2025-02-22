import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mathscribble_ai/screens/dashboardscreen/dashboard_screen.dart';
import 'package:mathscribble_ai/screens/math_canvasscreen/view/mathpractice_screen/math_practice_screen.dart';
import 'screens/dashboardscreen/model/recognition_model.dart';
import 'screens/onboardingscreen/onboarding_screen.dart';
import 'screens/splashscreen/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MathRecognitionApp());
}

class MathRecognitionApp extends StatelessWidget {
  const MathRecognitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Handwriting Recognition',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Rubik',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          titleTextStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/welcome': (context) => const DashboardScreen(),
        '/drawing': (context) {
          final model =
              ModalRoute.of(context)?.settings.arguments as RecognitionModel;
          return MathPracticeScreen(selectedModel: model);
        },
      },
    );
  }
}
