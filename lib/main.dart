import 'package:aquacatch/chat.dart';
import 'package:aquacatch/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart';
import 'firebase_options.dart';
import 'educational pages/rainwater_harvesting.dart';
import 'educational pages/artificial_recharge.dart';
import 'educational pages/rooftop_rainwaterharvesting.dart';
import 'educational pages/fresh_water.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
 
  
   // Load the correct env file
  if (const bool.fromEnvironment('dart.vm.product')) {
    // Production mode → load .env.production
    await dotenv.load(fileName: ".env.production");
  } else {
    // Development → load local .env
    await dotenv.load(fileName: ".env");
  }

  final apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception("GEMINI_API_KEY is not set!");
  }

  Gemini.init(apiKey: apiKey);
  runApp(const MyApp());
   print(dotenv.env['GEMINI_API_KEY']);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  static void toggleTheme(BuildContext context) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.toggleTheme();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AquaCatch',
      locale: _locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: lightTheme, // ✅ use from theme.dart
      darkTheme: darkTheme, // ✅ use from theme.dart
      themeMode: _themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) =>
            const MainNavigation(), // Changed from HomeScreen() to MainNavigation()
        '/rainwater_harvesting': (context) => const RainwaterEducationPage(),
        '/artificial_recharge': (context) => const ArtificialRechargePage(),
        '/rooftop_rainwaterharvesting': (context) =>
            const RooftopRainwaterHarvestingPage(),
        '/fresh_water': (context) => const WhyFreshWaterMattersPage(),
        '/chat': (context) => const ChatPage(), // <-- Register your chat screen
      },
    );
  }
}
