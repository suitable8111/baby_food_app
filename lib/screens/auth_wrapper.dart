import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/diary_provider.dart';
import 'auth_screen.dart';
import 'food_diary_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription? _linkSub;
  bool _pendingDiaryNavigation = false;
  String? _activeStreamFamilyId; // 스트림 중복 시작 방지

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();

    // 앱이 꺼진 상태에서 위젯 탭으로 시작된 경우 (cold start)
    final initialUri = await appLinks.getInitialLink();
    _handleLink(initialUri);

    // 앱이 실행 중일 때 위젯 탭 (warm start)
    _linkSub = appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri? uri) {
    if (uri == null) return;
    if (uri.host == 'diary') {
      setState(() => _pendingDiaryNavigation = true);
    }
  }

  void _navigateToDiary() {
    _pendingDiaryNavigation = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FoodDiaryScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final diaryProvider = context.read<DiaryProvider>();

    if (authProvider.status == AuthStatus.authenticated) {
      final babyName = authProvider.userProfile?.babyName;
      if (babyName != null && babyName.isNotEmpty) {
        diaryProvider.setBabyName(babyName);
      }
      // familyId가 바뀔 때만 스트림 재시작 (build 매번 호출 방지)
      final familyId = authProvider.familyId;
      if (familyId.isNotEmpty && familyId != _activeStreamFamilyId) {
        _activeStreamFamilyId = familyId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) diaryProvider.startTodayStream(familyId);
        });
      }
      if (_pendingDiaryNavigation) {
        _navigateToDiary();
      }
    } else {
      if (_activeStreamFamilyId != null) {
        _activeStreamFamilyId = null;
        diaryProvider.stopTodayStream();
      }
    }

    switch (authProvider.status) {
      case AuthStatus.initial:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        return const HomeScreen();
      default:
        return const AuthScreen(showBackButton: false);
    }
  }
}
