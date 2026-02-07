import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';
import 'auth_screen.dart';

class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('이유식 레시피'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 섹션
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StageFilterChips(
                  selectedStage: recipeProvider.selectedStage,
                  onSelected: recipeProvider.setStageFilter,
                ),
                if (recipeProvider.searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Chip(
                    label: Text('검색: ${recipeProvider.searchQuery}'),
                    onDeleted: () => recipeProvider.setSearchQuery(''),
                  ),
                ],
              ],
            ),
          ),

          // 레시피 그리드
          Expanded(
            child: recipeProvider.filteredRecipes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('레시피가 없습니다'),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: recipeProvider.filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipeProvider.filteredRecipes[index];
                      return RecipeCard(
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final recipeProvider = context.read<RecipeProvider>();
    final controller = TextEditingController(text: recipeProvider.searchQuery);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('레시피 검색'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '레시피 또는 재료명 입력',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            recipeProvider.setSearchQuery(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              recipeProvider.setSearchQuery(controller.text);
              Navigator.pop(context);
            },
            child: const Text('검색'),
          ),
        ],
      ),
    );
  }
}
