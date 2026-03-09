import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/diary_provider.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // 아기 이름을 DiaryProvider에 동기화 (위젯 표시용)
    final babyName = authProvider.userProfile?.babyName;
    if (babyName != null && babyName.isNotEmpty) {
      context.read<DiaryProvider>().setBabyName(babyName);
    }

    switch (authProvider.status) {
      case AuthStatus.initial:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      case AuthStatus.authenticated:
        return const HomeScreen();
      default:
        return const AuthScreen(showBackButton: false);
    }
  }
}
