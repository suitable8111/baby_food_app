import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'providers/recipe_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase 초기화 실패: $e');
  }

  runApp(const BabyFoodApp());
}

class BabyFoodApp extends StatelessWidget {
  const BabyFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    // FirebaseService 인스턴스 생성
    final firebaseService = FirebaseService();

    return MultiProvider(
      providers: [
        // FirebaseService를 Provider로 제공
        Provider<FirebaseService>.value(value: firebaseService),

        // AuthProvider
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(firebaseService),
        ),

        // RecipeProvider - FirebaseService 주입
        ChangeNotifierProvider<RecipeProvider>(
          create: (_) => RecipeProvider(firebaseService),
        ),
      ],
      child: MaterialApp(
        title: '동백이 밥창고',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
          Locale('en', 'US'),
        ],
        locale: const Locale('ko', 'KR'),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Pretendard',
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
