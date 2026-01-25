import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';

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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역 (플레이스홀더)
            Container(
              height: 120,
              width: double.infinity,
              color: _getStageColor(recipe.stage).withOpacity(0.2),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 48,
                      color: _getStageColor(recipe.stage),
                    ),
                  ),
                  // 단계 뱃지
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStageColor(recipe.stage),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recipe.stage.shortName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // 즐겨찾기 버튼
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: onFavoriteToggle,
                    ),
                  ),
                  // 알레르기 경고
                  if (recipe.hasAllergens)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '알레르기',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 정보 영역
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.timer,
                        '${recipe.cookingTimeMinutes}분',
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.signal_cellular_alt,
                        recipe.difficulty.displayName,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 영양소 요약
                  Text(
                    '${recipe.totalNutrition.calories.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
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
          FilterChip(
            label: const Text('전체'),
            selected: selectedStage == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...BabyFoodStage.values.map((stage) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(stage.shortName),
              selected: selectedStage == stage,
              onSelected: (_) => onSelected(stage),
              backgroundColor: _getStageColor(stage).withOpacity(0.1),
              selectedColor: _getStageColor(stage).withOpacity(0.3),
            ),
          )),
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
