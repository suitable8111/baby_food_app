import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/board_recipe.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/nutrition_chart.dart';
import '../services/image_service.dart';
import 'recipe_edit_screen.dart';
import 'auth_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  final BoardRecipe? boardRecipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.boardRecipe,
  });

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final isFavorite = recipeProvider.isFavorite(recipe.id);
    final nutrition = recipeProvider.getRecipeNutrition(recipe);
    final hasAllergens = recipeProvider.recipeHasAllergens(recipe);
    final allergens = recipeProvider.getRecipeAllergens(recipe);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 앱바
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.name,
                style: const TextStyle(
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              background: _buildBackgroundImage(),
            ),
            actions: [
              // 즐겨찾기
              if (boardRecipe == null)
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () async {
                    final success =
                        await recipeProvider.toggleFavorite(recipe.id);
                    if (!success && context.mounted) {
                      _showLoginRequired(context);
                    }
                  },
                ),
              // 게시판 레시피 즐겨찾기
              if (boardRecipe != null)
                IconButton(
                  icon: Icon(
                    recipeProvider.isBoardFavorite(boardRecipe!.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: recipeProvider.isBoardFavorite(boardRecipe!.id)
                        ? Colors.red
                        : Colors.white,
                  ),
                  onPressed: () async {
                    final authProvider = context.read<AuthProvider>();
                    if (!authProvider.isAuthenticated) {
                      _showLoginRequired(context);
                      return;
                    }
                    await recipeProvider.toggleBoardFavorite(boardRecipe!.id);
                  },
                ),
              // 공유 버튼 (로그인 필요)
              if (boardRecipe == null)
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _showShareDialog(context),
                ),
              // 사용자 레시피인 경우 편집 버튼
              if (recipe.userId != null && boardRecipe == null)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeEditScreen(recipe: recipe),
                      ),
                    );
                  },
                ),
              // 게시판 레시피 관리 메뉴 (작성자 또는 관리자)
              if (boardRecipe != null &&
                  recipeProvider.canEditBoardRecipe(boardRecipe!))
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('게시물 삭제'),
                          content: const Text('이 게시물을 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('삭제'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await recipeProvider
                            .deleteBoardRecipe(boardRecipe!.id);
                        if (context.mounted) Navigator.pop(context);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('게시물 삭제', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // 콘텐츠
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 기본 정보
                  _buildInfoRow(context, nutrition),
                  const SizedBox(height: 24),

                  // 알레르기 경고
                  if (hasAllergens) ...[
                    _buildAllergenWarning(context, allergens),
                    const SizedBox(height: 24),
                  ],

                  // 재료
                  _buildSection(
                    context,
                    title: '재료',
                    icon: Icons.shopping_basket,
                    child: _buildIngredientsList(context, recipeProvider),
                  ),
                  const SizedBox(height: 24),

                  // 영양 정보
                  _buildSection(
                    context,
                    title: '영양 정보',
                    icon: Icons.pie_chart,
                    child: Column(
                      children: [
                        NutritionPieChart(nutrition: nutrition),
                        const SizedBox(height: 16),
                        NutritionInfoCard(
                          nutrition: nutrition,
                          title: '총 영양소',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 조리법
                  _buildSection(
                    context,
                    title: '조리법',
                    icon: Icons.menu_book,
                    child: _buildStepsList(context),
                  ),

                  // 팁
                  if (recipe.tip != null) ...[
                    const SizedBox(height: 24),
                    _buildTipCard(context),
                  ],

                  // 보관 정보
                  if (recipe.storageInfo != null) ...[
                    const SizedBox(height: 16),
                    _buildStorageInfo(context),
                  ],

                  const SizedBox(height: 24),

                  // 게시판 작성자 정보
                  if (boardRecipe != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '작성자: ${boardRecipe!.authorDisplayName ?? boardRecipe!.authorEmail.split('@').first}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final authProvider = context.read<AuthProvider>();
                          if (!authProvider.isAuthenticated) {
                            _showLoginRequired(context);
                            return;
                          }
                          final id = await recipeProvider
                              .saveBoardRecipeToMyRecipes(boardRecipe!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(id != null
                                    ? '내 레시피에 저장되었습니다!'
                                    : '저장에 실패했습니다.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.save_alt),
                        label: const Text('내 레시피로 저장'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],

                  // 나만의 레시피로 저장 버튼 (기본 레시피인 경우)
                  if (recipe.userId == null && boardRecipe == null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final authProvider = context.read<AuthProvider>();
                          if (!authProvider.isAuthenticated) {
                            _showLoginRequired(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeEditScreen(recipe: recipe),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_note),
                        label: const Text('나만의 레시피로 저장'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, nutrition) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildInfoChip(
          context,
          Icons.child_care,
          recipe.stage.shortName,
          _getStageColor(recipe.stage),
        ),
        _buildInfoChip(
          context,
          Icons.timer,
          '${recipe.cookingTimeMinutes}분',
          Colors.blue,
        ),
        _buildInfoChip(
          context,
          Icons.signal_cellular_alt,
          recipe.difficulty.displayName,
          Colors.orange,
        ),
        _buildInfoChip(
          context,
          Icons.local_fire_department,
          '${nutrition.calories.toStringAsFixed(0)} kcal',
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergenWarning(BuildContext context, List<Ingredient> allergens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '알레르기 주의',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                Text(
                  '포함 재료: ${allergens.map((a) => a.allergenType ?? a.name).join(', ')}',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildIngredientsList(BuildContext context, RecipeProvider recipeProvider) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recipe.ingredientData.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final data = recipe.ingredientData[index];
          final ingredient = recipeProvider.getIngredientById(data.ingredientId);

          if (ingredient == null) {
            return ListTile(
              title: Text('알 수 없는 재료: ${data.ingredientId}'),
              trailing: Text('${data.amount.toStringAsFixed(0)}${data.unit}'),
            );
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(ingredient.category).withOpacity(0.2),
              child: Icon(
                _getCategoryIcon(ingredient.category),
                color: _getCategoryColor(ingredient.category),
                size: 20,
              ),
            ),
            title: Text(ingredient.name),
            trailing: Text(
              '${data.amount.toStringAsFixed(0)}${data.unit}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepsList(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: recipe.steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '조리 팁',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.tip!,
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.kitchen, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보관 정보',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  recipe.storageInfo!,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    final imageService = ImageService();

    // 1. 사용자 레시피의 로컬 이미지가 있으면 표시
    if (recipe.imageUrl != null && imageService.isLocalFile(recipe.imageUrl)) {
      if (!kIsWeb) {
        return Image.file(
          File(recipe.imageUrl!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildAssetOrPlaceholder(),
        );
      }
    }

    // 2. 네트워크 이미지 URL이 있으면 표시
    if (recipe.imageUrl != null && recipe.imageUrl!.startsWith('http')) {
      return Image.network(
        recipe.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildAssetOrPlaceholder(),
      );
    }

    // 3. 기본 레시피는 asset 이미지 또는 플레이스홀더
    return _buildAssetOrPlaceholder();
  }

  Widget _buildAssetOrPlaceholder() {
    return Image.asset(
      'assets/images/recipes/${recipe.name}.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: _getStageColor(recipe.stage).withOpacity(0.3),
        child: Center(
          child: Icon(
            Icons.restaurant,
            size: 80,
            color: _getStageColor(recipe.stage),
          ),
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showLoginRequired(context);
      return;
    }

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
              final success =
                  await recipeProvider.shareRecipe(recipe, email);
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

  Color _getCategoryColor(IngredientCategory category) {
    switch (category) {
      case IngredientCategory.grain:
        return Colors.amber;
      case IngredientCategory.vegetable:
        return Colors.green;
      case IngredientCategory.fruit:
        return Colors.orange;
      case IngredientCategory.protein:
        return Colors.red;
      case IngredientCategory.dairy:
        return Colors.blue;
      case IngredientCategory.other:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(IngredientCategory category) {
    switch (category) {
      case IngredientCategory.grain:
        return Icons.grass;
      case IngredientCategory.vegetable:
        return Icons.eco;
      case IngredientCategory.fruit:
        return Icons.apple;
      case IngredientCategory.protein:
        return Icons.egg;
      case IngredientCategory.dairy:
        return Icons.water_drop;
      case IngredientCategory.other:
        return Icons.category;
    }
  }
}
