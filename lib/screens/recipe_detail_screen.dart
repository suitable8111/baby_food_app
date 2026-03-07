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
            expandedHeight: 280,
            pinned: true,
            foregroundColor: Colors.white,
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
              title: Text(
                recipe.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: Colors.white,
                  shadows: [
                    Shadow(blurRadius: 10, color: Colors.black),
                    Shadow(blurRadius: 4, color: Colors.black87),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildBackgroundImage(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
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
                          Text('게시물 삭제',
                              style: TextStyle(color: Colors.red)),
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
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 기본 정보
                  _buildInfoRow(context, nutrition),
                  const SizedBox(height: 28),

                  // 알레르기 경고
                  if (hasAllergens) ...[
                    _buildAllergenWarning(context, allergens),
                    const SizedBox(height: 28),
                  ],

                  // 재료
                  _buildSection(
                    context,
                    title: '재료',
                    icon: Icons.shopping_basket_rounded,
                    child: _buildIngredientsList(context, recipeProvider),
                  ),
                  const SizedBox(height: 28),

                  // 영양 정보
                  _buildSection(
                    context,
                    title: '영양 정보',
                    icon: Icons.pie_chart_rounded,
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
                  const SizedBox(height: 28),

                  // 조리법
                  _buildSection(
                    context,
                    title: '조리법',
                    icon: Icons.menu_book_rounded,
                    child: _buildStepsList(context),
                  ),

                  // 팁
                  if (recipe.tip != null) ...[
                    const SizedBox(height: 28),
                    _buildTipCard(context),
                  ],

                  // 보관 정보
                  if (recipe.storageInfo != null) ...[
                    const SizedBox(height: 16),
                    _buildStorageInfo(context),
                  ],

                  const SizedBox(height: 28),

                  // 게시판 작성자 정보
                  if (boardRecipe != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.grey.shade200,
                            child: Icon(Icons.person_outline,
                                size: 16, color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '작성자: ${boardRecipe!.authorDisplayName ?? boardRecipe!.authorEmail.split('@').first}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
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

                  const SizedBox(height: 40),
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
          Icons.child_care_rounded,
          recipe.stage.shortName,
          _getStageColor(recipe.stage),
        ),
        _buildInfoChip(
          context,
          Icons.timer_rounded,
          '${recipe.cookingTimeMinutes}분',
          Colors.blue,
        ),
        _buildInfoChip(
          context,
          Icons.signal_cellular_alt_rounded,
          recipe.difficulty.displayName,
          Colors.orange,
        ),
        _buildInfoChip(
          context,
          Icons.local_fire_department_rounded,
          '${nutrition.calories.toStringAsFixed(0)} kcal',
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildInfoChip(
      BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergenWarning(
      BuildContext context, List<Ingredient> allergens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded,
                color: Colors.orange.shade700, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '알레르기 주의',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '포함 재료: ${allergens.map((a) => a.allergenType ?? a.name).join(', ')}',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }

  Widget _buildIngredientsList(
      BuildContext context, RecipeProvider recipeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recipe.ingredientData.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: Colors.grey.shade100,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final data = recipe.ingredientData[index];
          final ingredient =
              recipeProvider.getIngredientById(data.ingredientId);

          if (ingredient == null) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                '알 수 없는 재료: ${data.ingredientId}',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            );
          }

          final catColor = _getCategoryColor(ingredient.category);

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(ingredient.category),
                    color: catColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ingredient.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${data.amount.toStringAsFixed(0)}${data.unit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepsList(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Column(
      children: recipe.steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == recipe.steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 번호 + 연결선
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // 내용
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Text(
                    step,
                    style: TextStyle(
                      height: 1.65,
                      fontSize: 14.5,
                      color: Colors.grey.shade800,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTipCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.indigo.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lightbulb_rounded,
                color: Colors.blue.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '조리 팁',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.blue.shade800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  recipe.tip!,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13.5,
                    height: 1.55,
                  ),
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
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.kitchen_rounded, color: Colors.teal.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보관 정보',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.teal.shade800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  recipe.storageInfo!,
                  style: TextStyle(
                    color: Colors.teal.shade700,
                    fontSize: 13.5,
                    height: 1.55,
                  ),
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
          errorBuilder: (context, error, stackTrace) =>
              _buildAssetOrPlaceholder(),
        );
      }
    }

    // 2. 네트워크 이미지 URL이 있으면 표시
    if (recipe.imageUrl != null && recipe.imageUrl!.startsWith('http')) {
      return Image.network(
        recipe.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildAssetOrPlaceholder(),
      );
    }

    // 3. 기본 레시피는 asset 이미지 또는 플레이스홀더
    return _buildAssetOrPlaceholder();
  }

  Widget _buildAssetOrPlaceholder() {
    return Image.asset(
      'assets/images/recipes/${recipe.id}.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: _getStageColor(recipe.stage).withValues(alpha: 0.3),
        child: Center(
          child: Icon(
            Icons.restaurant_rounded,
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
              final success = await recipeProvider.shareRecipe(recipe, email);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '$email에게 레시피를 공유했습니다!'
                        : '공유에 실패했습니다.'),
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
