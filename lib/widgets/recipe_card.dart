import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../providers/recipe_provider.dart';
import '../services/image_service.dart';

/// 레시피 카드 위젯
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final hasAllergens = recipeProvider.recipeHasAllergens(recipe);
    final nutrition = recipeProvider.getRecipeNutrition(recipe);
    final stageColor = _getStageColor(recipe.stage);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      stageColor.withValues(alpha: 0.15),
                      stageColor.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildRecipeImage()),
                    // 단계 뱃지
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: stageColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          recipe.stage.shortName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    // 즐겨찾기
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onFavoriteToggle,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite
                                  ? const Color(0xFFE57373)
                                  : Colors.white.withValues(alpha: 0.9),
                              size: 22,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 알레르기
                    if (hasAllergens)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA726),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_rounded,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 3),
                              Text(
                                '알레르기',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // 정보 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D2D2D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _buildInfoTag(Icons.timer_outlined,
                            '${recipe.cookingTimeMinutes}분'),
                        const SizedBox(width: 6),
                        _buildInfoTag(Icons.local_fire_department_outlined,
                            '${nutrition.calories.toStringAsFixed(0)} kcal'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeImage() {
    final imageService = ImageService();

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

    if (recipe.imageUrl != null && recipe.imageUrl!.startsWith('http')) {
      return Image.network(
        recipe.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildAssetOrPlaceholder(),
      );
    }

    return _buildAssetOrPlaceholder();
  }

  Widget _buildAssetOrPlaceholder() {
    return Image.asset(
      'assets/images/recipes/${recipe.name}.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 40,
          color: _getStageColor(recipe.stage).withValues(alpha: 0.4),
        ),
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

/// 단계 선택 칩 위젯
class StageFilterChips extends StatelessWidget {
  final BabyFoodStage? selectedStage;
  final ValueChanged<BabyFoodStage?> onSelected;

  const StageFilterChips({
    super.key,
    this.selectedStage,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(context, null, '전체', Colors.grey),
          const SizedBox(width: 8),
          ...BabyFoodStage.values.map((stage) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildChip(
                    context, stage, stage.shortName, _getStageColor(stage)),
              )),
        ],
      ),
    );
  }

  Widget _buildChip(
      BuildContext context, BabyFoodStage? stage, String label, Color color) {
    final isSelected = selectedStage == stage;
    return Material(
      color: isSelected ? color : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => onSelected(stage),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
