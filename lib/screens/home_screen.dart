import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ingredient.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/recipe_card.dart';
import 'recipe_list_screen.dart';
import 'recipe_detail_screen.dart';
import 'nutrition_calculator_screen.dart';
import 'auth_screen.dart';
import 'favorites_screen.dart';
import 'my_recipes_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildDrawer(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated;

    return Drawer(
      child: Column(
        children: [
          // 헤더 - 사용자 정보 또는 로그인 안내
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: isLoggedIn
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
            ),
            accountName: Text(
              isLoggedIn ? (authProvider.displayName ?? '사용자') : '로그인이 필요합니다',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              isLoggedIn ? (authProvider.userEmail ?? '') : '로그인하여 더 많은 기능을 사용하세요',
            ),
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
        title: const Text('이유식 분석'),
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
