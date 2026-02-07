import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ingredient.dart';
import '../providers/recipe_provider.dart';
import '../services/image_service.dart';
import 'recipe_detail_screen.dart';
import 'recipe_edit_screen.dart';

class MyRecipesScreen extends StatelessWidget {
  const MyRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final userRecipes = recipeProvider.userRecipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('나만의 레시피'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecipeEditScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('새 레시피'),
      ),
      body: userRecipes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    '나만의 레시피가 없습니다',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '나만의 이유식 레시피를 만들어보세요!',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RecipeEditScreen()),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('레시피 만들기'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: userRecipes.length,
              itemBuilder: (context, index) {
                final recipe = userRecipes[index];
                return Dismissible(
                  key: Key(recipe.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('레시피 삭제'),
                        content: Text("'${recipe.name}' 레시피를 삭제하시겠습니까?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) async {
                    await recipeProvider.deleteUserRecipe(recipe.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("'${recipe.name}' 레시피가 삭제되었습니다.")),
                      );
                    }
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.delete, color: Colors.white, size: 28),
                  ),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: _buildRecipeThumbnail(recipe),
                      title: Text(
                        recipe.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStageColor(recipe.stage)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  recipe.stage.shortName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getStageColor(recipe.stage),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${recipe.ingredientData.length}개 재료',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${recipe.cookingTimeMinutes}분',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RecipeEditScreen(recipe: recipe),
                              ),
                            );
                          } else if (value == 'view') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RecipeDetailScreen(recipe: recipe),
                              ),
                            );
                          } else if (value == 'share') {
                            _showShareDialog(context, recipe);
                          } else if (value == 'publish') {
                            _showPublishConfirm(context, recipe);
                          } else if (value == 'delete') {
                            _showDeleteConfirm(context, recipe);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility, size: 20),
                                SizedBox(width: 8),
                                Text('보기'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('편집'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share, size: 20),
                                SizedBox(width: 8),
                                Text('공유'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'publish',
                            child: Row(
                              children: [
                                Icon(Icons.publish, size: 20),
                                SizedBox(width: 8),
                                Text('게시판에 올리기'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('삭제', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(recipe: recipe),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showShareDialog(BuildContext context, recipe) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('레시피 공유'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "'${recipe.name}' 레시피를 공유할 이메일을 입력하세요.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: '받는 사람 이메일',
                hintText: 'example@email.com',
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('올바른 이메일을 입력해주세요.')),
                );
                return;
              }
              Navigator.pop(context);
              final recipeProvider = context.read<RecipeProvider>();
              final success = await recipeProvider.shareRecipe(recipe, email);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? '$email에게 레시피를 공유했습니다!' : '공유에 실패했습니다.'),
                  ),
                );
              }
            },
            child: const Text('공유'),
          ),
        ],
      ),
    );
  }

  void _showPublishConfirm(BuildContext context, recipe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시판에 올리기'),
        content: Text("'${recipe.name}' 레시피를 게시판에 공유하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('게시'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final recipeProvider = context.read<RecipeProvider>();
      final success = await recipeProvider.publishToBoard(recipe);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '레시피가 게시판에 공유되었습니다!' : '게시에 실패했습니다.'),
          ),
        );
      }
    }
  }

  void _showDeleteConfirm(BuildContext context, recipe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('레시피 삭제'),
        content: Text("'${recipe.name}' 레시피를 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final recipeProvider = context.read<RecipeProvider>();
      await recipeProvider.deleteUserRecipe(recipe.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("'${recipe.name}' 레시피가 삭제되었습니다.")),
        );
      }
    }
  }

  Widget _buildRecipeThumbnail(recipe) {
    final imageService = ImageService();

    // 로컬 이미지가 있으면 표시
    if (recipe.imageUrl != null && imageService.isLocalFile(recipe.imageUrl)) {
      if (!kIsWeb) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(recipe.imageUrl!),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(recipe),
          ),
        );
      }
    }

    // 네트워크 이미지가 있으면 표시
    if (recipe.imageUrl != null && recipe.imageUrl!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          recipe.imageUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(recipe),
        ),
      );
    }

    return _buildPlaceholder(recipe);
  }

  Widget _buildPlaceholder(recipe) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _getStageColor(recipe.stage).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.restaurant,
        color: _getStageColor(recipe.stage),
      ),
    );
  }

  Color _getStageColor(stage) {
    switch (stage.index) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
