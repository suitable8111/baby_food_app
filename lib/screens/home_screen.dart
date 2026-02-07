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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildDrawer(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated;
    final profile = authProvider.userProfile;
    final babyStage = profile?.babyStage;

    return Drawer(
      child: Column(
        children: [
          // 헤더 - 사용자 정보 또는 로그인 안내
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            currentAccountPicture: _buildDrawerAvatar(context, authProvider),
            accountName: Row(
              children: [
                Text(
                  isLoggedIn ? (authProvider.displayName ?? '사용자') : '로그인이 필요합니다',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (isLoggedIn && babyStage != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStageColorForDrawer(babyStage),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      babyStage.shortName,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            accountEmail: Text(
              isLoggedIn
                  ? (profile?.babyName != null
                      ? '${profile!.babyName} ${profile.babyAgeText != null ? "(${profile.babyAgeText})" : ""}'
                      : authProvider.userEmail ?? '')
                  : '로그인하여 더 많은 기능을 사용하세요',
            ),
            onDetailsPressed: isLoggedIn
                ? () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()),
                    );
                  }
                : null,
          ),

          // 메뉴 항목
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('홈'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('레시피'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecipeListScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calculate),
            title: const Text('영양소 계산'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NutritionCalculatorScreen()),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: const Text('즐겨찾기'),
            onTap: () {
              Navigator.pop(context);
              if (!isLoggedIn) {
                _showLoginRequired(context);
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.green),
            title: const Text('내 프로필'),
            onTap: () {
              Navigator.pop(context);
              if (!isLoggedIn) {
                _showLoginRequired(context);
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.book, color: Colors.blue),
            title: const Text('나만의 레시피'),
            onTap: () {
              Navigator.pop(context);
              if (!isLoggedIn) {
                _showLoginRequired(context);
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyRecipesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.mail, color: Colors.teal),
            title: Row(
              children: [
                const Text('레시피 공유함'),
                if (isLoggedIn)
                  Consumer<RecipeProvider>(
                    builder: (context, provider, _) {
                      final count = provider.pendingShareCount;
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            onTap: () {
              Navigator.pop(context);
              if (!isLoggedIn) {
                _showLoginRequired(context);
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SharedRecipesScreen()),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.forum, color: Colors.deepPurple),
            title: const Text('레시피 게시판'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BoardScreen()),
              );
            },
          ),

          const Spacer(),

          // 하단: 로그인/로그아웃
          const Divider(),
          if (isLoggedIn)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
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
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('로그인'),
              onTap: () async {
                Navigator.pop(context);
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDrawerAvatar(BuildContext context, AuthProvider authProvider) {
    final profile = authProvider.userProfile;
    final photoPath = profile?.babyPhotoPath;

    // 아기 사진이 있으면 사진 표시
    if (photoPath != null && !kIsWeb && ImageService().isLocalFile(photoPath)) {
      final file = File(photoPath);
      if (file.existsSync()) {
        return CircleAvatar(
          backgroundColor: Colors.white,
          backgroundImage: FileImage(file),
        );
      }
    }

    // 기본 아바타
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: authProvider.isAuthenticated
          ? Text(
              (authProvider.displayName?.isNotEmpty == true
                      ? authProvider.displayName![0]
                      : authProvider.userEmail?[0] ?? 'U')
                  .toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Icon(
              Icons.person,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
    );
  }

  Color _getStageColorForDrawer(BabyFoodStage stage) {
    switch (stage) {
      case BabyFoodStage.early:
        return Colors.green.shade300;
      case BabyFoodStage.middle:
        return Colors.orange.shade300;
      case BabyFoodStage.late:
        return Colors.purple.shade300;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('동백이 밥창고'),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 배너
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '우리 아기 이유식',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '단계별 레시피와 영양소를 확인하세요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),

            // 빠른 메뉴
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '빠른 메뉴',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickMenuCard(
                          icon: Icons.restaurant_menu,
                          title: '레시피',
                          subtitle: '단계별 이유식',
                          color: Colors.green,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RecipeListScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickMenuCard(
                          icon: Icons.calculate,
                          title: '영양소 계산',
                          subtitle: '커스텀 분석',
                          color: Colors.orange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const NutritionCalculatorScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 단계별 레시피 섹션
            ...BabyFoodStage.values
                .map((stage) => _StageSection(stage: stage)),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
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

class _StageSection extends StatelessWidget {
  final BabyFoodStage stage;

  const _StageSection({required this.stage});

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final recipes = recipeProvider.getRecipesByStage(stage);

    if (recipes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _getStageColor(stage),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stage.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  recipeProvider.setStageFilter(stage);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecipeListScreen(),
                    ),
                  );
                },
                child: const Text('더보기'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recipes.length > 5 ? 5 : recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Container(
                  width: 200,
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
                                  context
                                      .read<RecipeProvider>()
                                      .onUserLogin();
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
        return Colors.green;
      case BabyFoodStage.middle:
        return Colors.orange;
      case BabyFoodStage.late:
        return Colors.purple;
    }
  }
}
