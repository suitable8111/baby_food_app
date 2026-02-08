import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ingredient.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import '../services/image_service.dart';
import '../widgets/recipe_card.dart';
import 'recipe_list_screen.dart';
import 'recipe_detail_screen.dart';
import 'nutrition_calculator_screen.dart';
import 'auth_screen.dart';
import 'favorites_screen.dart';
import 'my_recipes_screen.dart';
import 'shared_recipes_screen.dart';
import 'board_screen.dart';
import 'profile_screen.dart';
import 'food_diary_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ====== Drawer ======
  Widget _buildDrawer(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated;
    final profile = authProvider.userProfile;
    final babyStage = profile?.babyStage;

    return Drawer(
      backgroundColor: const Color(0xFFF8FAF6),
      child: Column(
        children: [
          // 그라데이션 헤더
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6BBF59), Color(0xFF4A9E3F)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아바타
                GestureDetector(
                  onTap: isLoggedIn
                      ? () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          );
                        }
                      : null,
                  child: _buildDrawerAvatar(context, authProvider),
                ),
                const SizedBox(height: 16),
                // 이름 + 단계 뱃지
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isLoggedIn
                            ? (authProvider.displayName ?? '사용자')
                            : '로그인이 필요합니다',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLoggedIn && babyStage != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          babyStage.shortName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isLoggedIn
                      ? (profile?.babyName != null
                          ? '${profile!.babyName} ${profile.babyAgeText != null ? "(${profile.babyAgeText})" : ""}'
                          : authProvider.userEmail ?? '')
                      : '로그인하여 더 많은 기능을 사용하세요',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 메뉴
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              children: [
                _DrawerMenuItem(
                  icon: Icons.home_rounded,
                  label: '홈',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerMenuItem(
                  icon: Icons.restaurant_menu_rounded,
                  label: '레시피',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RecipeListScreen()));
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.pie_chart_rounded,
                  label: '영양소 계산',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NutritionCalculatorScreen()));
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Divider(color: Colors.grey.shade200, height: 1),
                ),

                _DrawerMenuItem(
                  icon: Icons.favorite_rounded,
                  label: '즐겨찾기',
                  iconColor: const Color(0xFFE57373),
                  onTap: () {
                    Navigator.pop(context);
                    if (!isLoggedIn) { _showLoginRequired(context); return; }
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.person_rounded,
                  label: '내 프로필',
                  iconColor: const Color(0xFF66BB6A),
                  onTap: () {
                    Navigator.pop(context);
                    if (!isLoggedIn) { _showLoginRequired(context); return; }
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.menu_book_rounded,
                  label: '나만의 레시피',
                  iconColor: const Color(0xFF42A5F5),
                  onTap: () {
                    Navigator.pop(context);
                    if (!isLoggedIn) { _showLoginRequired(context); return; }
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MyRecipesScreen()));
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.calendar_month_rounded,
                  label: '이유식 일지',
                  iconColor: const Color(0xFFFF7043),
                  onTap: () {
                    Navigator.pop(context);
                    if (!isLoggedIn) { _showLoginRequired(context); return; }
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FoodDiaryScreen()));
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.mail_rounded,
                  label: '레시피 공유함',
                  iconColor: const Color(0xFF26A69A),
                  trailing: isLoggedIn
                      ? Consumer<RecipeProvider>(
                          builder: (context, provider, _) {
                            final count = provider.pendingShareCount;
                            if (count == 0) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE57373),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isLoggedIn) { _showLoginRequired(context); return; }
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SharedRecipesScreen()));
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Divider(color: Colors.grey.shade200, height: 1),
                ),

                _DrawerMenuItem(
                  icon: Icons.forum_rounded,
                  label: '레시피 게시판',
                  iconColor: const Color(0xFF7E57C2),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const BoardScreen()));
                  },
                ),
              ],
            ),
          ),

          // 하단 로그인/로그아웃
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: [
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 4),
                if (isLoggedIn)
                  _DrawerMenuItem(
                    icon: Icons.logout_rounded,
                    label: '로그아웃',
                    iconColor: Colors.grey,
                    onTap: () async {
                      Navigator.pop(context);
                      await authProvider.signOut();
                      if (context.mounted) {
                        context.read<RecipeProvider>().onUserLogout();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('로그아웃되었습니다.')),
                        );
                      }
                    },
                  )
                else
                  _DrawerMenuItem(
                    icon: Icons.login_rounded,
                    label: '로그인',
                    iconColor: Theme.of(context).colorScheme.primary,
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()));
                      if (context.mounted &&
                          context.read<AuthProvider>().isAuthenticated) {
                        context.read<RecipeProvider>().onUserLogin();
                      }
                    },
                  ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
        ],
      ),
    );
  }

  Widget _buildDrawerAvatar(BuildContext context, AuthProvider authProvider) {
    final profile = authProvider.userProfile;
    final photoPath = profile?.babyPhotoPath;

    if (photoPath != null && !kIsWeb && ImageService().isLocalFile(photoPath)) {
      final file = File(photoPath);
      if (file.existsSync()) {
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
          ),
        );
      }
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
      ),
      child: Center(
        child: authProvider.isAuthenticated
            ? Text(
                (authProvider.displayName?.isNotEmpty == true
                        ? authProvider.displayName![0]
                        : authProvider.userEmail?[0] ?? 'U')
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.person_rounded, size: 28, color: Colors.white),
      ),
    );
  }

  void _showLoginRequired(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('로그인이 필요한 기능입니다.'),
        action: SnackBarAction(
          label: '로그인',
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            );
            if (context.mounted &&
                context.read<AuthProvider>().isAuthenticated) {
              context.read<RecipeProvider>().onUserLogin();
            }
          },
        ),
      ),
    );
  }

  // ====== Body ======
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('동백이 밥창고'),
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 히어로 배너
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7BC96A), Color(0xFF4A9E3F)],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.babyName != null
                              ? '${profile!.babyName}의 이유식'
                              : '우리 아기 이유식',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '단계별 레시피와 영양소를 확인하세요',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                        ),
                        if (profile?.babyStage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${profile!.babyAgeText ?? ''} | 이유식 ${profile.babyStage!.shortName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.child_care_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // 빠른 메뉴
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                '빠른 메뉴',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D2D2D),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickMenuCard(
                      icon: Icons.restaurant_menu_rounded,
                      title: '레시피',
                      subtitle: '단계별 이유식',
                      gradient: const [Color(0xFF66BB6A), Color(0xFF43A047)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RecipeListScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickMenuCard(
                      icon: Icons.pie_chart_rounded,
                      title: '영양소 계산',
                      subtitle: '커스텀 분석',
                      gradient: const [Color(0xFFFFA726), Color(0xFFF57C00)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NutritionCalculatorScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 단계별 레시피 섹션
            ...BabyFoodStage.values.map((stage) => _StageSection(stage: stage)),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ====== Drawer 메뉴 아이템 ======
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    this.iconColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.grey).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor ?? Colors.grey.shade700),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

// ====== 빠른 메뉴 카드 ======
class _QuickMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====== 단계별 섹션 ======
class _StageSection extends StatelessWidget {
  final BabyFoodStage stage;

  const _StageSection({required this.stage});

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final recipes = recipeProvider.getRecipesByStage(stage);

    if (recipes.isEmpty) return const SizedBox.shrink();

    final color = _getStageColor(stage);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      stage.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    recipeProvider.setStageFilter(stage);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RecipeListScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('더보기', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recipes.length > 5 ? 5 : recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  child: RecipeCard(
                    recipe: recipe,
                    isFavorite: recipeProvider.isFavorite(recipe.id),
                    onFavoriteToggle: () async {
                      final success =
                          await recipeProvider.toggleFavorite(recipe.id);
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('로그인이 필요한 기능입니다.'),
                            action: SnackBarAction(
                              label: '로그인',
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const AuthScreen()),
                                );
                                if (context.mounted &&
                                    context
                                        .read<AuthProvider>()
                                        .isAuthenticated) {
                                  context.read<RecipeProvider>().onUserLogin();
                                }
                              },
                            ),
                          ),
                        );
                      }
                    },
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipe: recipe),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStageColor(BabyFoodStage stage) {
    switch (stage) {
      case BabyFoodStage.early:
        return const Color(0xFF66BB6A);
      case BabyFoodStage.middle:
        return const Color(0xFFFFA726);
      case BabyFoodStage.late:
        return const Color(0xFF7E57C2);
    }
  }
}
