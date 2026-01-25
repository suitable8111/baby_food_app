import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../providers/recipe_provider.dart';
import '../widgets/nutrition_chart.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final isFavorite = recipeProvider.isFavorite(recipe.id);

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
              background: Container(
                color: _getStageColor(recipe.stage).withOpacity(0.3),
                child: Center(
                  child: Icon(
                    Icons.restaurant,
                    size: 80,
                    color: _getStageColor(recipe.stage),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () => recipeProvider.toggleFavorite(recipe.id),
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
                  _buildInfoRow(context),
                  const SizedBox(height: 24),

                  // 알레르기 경고
                  if (recipe.hasAllergens) ...[
                    _buildAllergenWarning(context),
                    const SizedBox(height: 24),
                  ],

                  // 재료
                  _buildSection(
                    context,
                    title: '재료',
                    icon: Icons.shopping_basket,
                    child: _buildIngredientsList(context),
                  ),
                  const SizedBox(height: 24),

                  // 영양 정보
                  _buildSection(
                    context,
                    title: '영양 정보',
                    icon: Icons.pie_chart,
                    child: Column(
                      children: [
                        NutritionPieChart(nutrition: recipe.totalNutrition),
                        const SizedBox(height: 16),
                        NutritionInfoCard(
                          nutrition: recipe.totalNutrition,
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

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context) {
    return Row(
      children: [
        _buildInfoChip(
          context,
          Icons.child_care,
          recipe.stage.shortName,
          _getStageColor(recipe.stage),
        ),
        const SizedBox(width: 8),
        _buildInfoChip(
          context,
          Icons.timer,
          '${recipe.cookingTimeMinutes}분',
          Colors.blue,
        ),
        const SizedBox(width: 8),
        _buildInfoChip(
          context,
          Icons.signal_cellular_alt,
          recipe.difficulty.displayName,
          Colors.orange,
        ),
        const SizedBox(width: 8),
        _buildInfoChip(
          context,
          Icons.local_fire_department,
          '${recipe.totalNutrition.calories.toStringAsFixed(0)} kcal',
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

  Widget _buildAllergenWarning(BuildContext context) {
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
                  '포함 재료: ${recipe.allergens.map((a) => a.allergenType ?? a.name).join(', ')}',
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

  Widget _buildIngredientsList(BuildContext context) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recipe.ingredients.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = recipe.ingredients[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(item.ingredient.category).withOpacity(0.2),
              child: Icon(
                _getCategoryIcon(item.ingredient.category),
                color: _getCategoryColor(item.ingredient.category),
                size: 20,
              ),
            ),
            title: Text(item.ingredient.name),
            trailing: Text(
              '${item.amount.toStringAsFixed(0)}${item.unit}',
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
