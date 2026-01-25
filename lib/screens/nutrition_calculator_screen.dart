import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ingredient.dart';
import '../providers/nutrition_provider.dart';
import '../widgets/ingredient_selector.dart';
import '../widgets/nutrition_chart.dart';

class NutritionCalculatorScreen extends StatelessWidget {
  const NutritionCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NutritionProvider(),
      child: const _NutritionCalculatorContent(),
    );
  }
}

class _NutritionCalculatorContent extends StatelessWidget {
  const _NutritionCalculatorContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('영양소 계산기'),
        actions: [
          if (provider.selectedIngredients.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearConfirmDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // 아기 월령 설정
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                const Icon(Icons.child_care),
                const SizedBox(width: 12),
                const Text('아기 월령: '),
                Expanded(
                  child: Slider(
                    value: provider.babyAgeMonths.toDouble(),
                    min: 4,
                    max: 24,
                    divisions: 20,
                    label: '${provider.babyAgeMonths}개월',
                    onChanged: (value) => provider.setBabyAge(value.toInt()),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStageColor(provider.currentStage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    provider.currentStage.shortName,
                    style: TextStyle(
                      color: _getStageColor(provider.currentStage),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 알레르기 경고
          if (provider.hasAllergenWarning)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '알레르기 재료 포함: ${provider.allergenIngredients.map((i) => i.allergenType ?? i.name).join(', ')}',
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // 메인 콘텐츠
          Expanded(
            child: provider.selectedIngredients.isEmpty
                ? _buildEmptyState(context)
                : _buildCalculatorContent(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddIngredientDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('재료 추가'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calculate_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '재료를 추가하여\n영양소를 계산해보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _showAddIngredientDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('재료 추가하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorContent(BuildContext context) {
    final provider = context.watch<NutritionProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 선택된 재료 목록
          Text(
            '선택된 재료',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...provider.selectedIngredients.map((item) => IngredientTile(
            ingredient: item.ingredient,
            amount: item.amount,
            onAmountChanged: (newAmount) =>
                provider.updateIngredientAmount(item.ingredient.id, newAmount),
            onRemove: () => provider.removeIngredient(item.ingredient.id),
          )),

          const SizedBox(height: 24),

          // 총 영양소 정보
          Text(
            '총 영양소',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          NutritionInfoCard(
            nutrition: provider.totalNutrition,
            title: '합계',
          ),

          const SizedBox(height: 24),

          // 영양소 비율 차트
          Text(
            '탄수화물 / 단백질 / 지방 비율',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: NutritionPieChart(nutrition: provider.totalNutrition),
            ),
          ),

          const SizedBox(height: 24),

          // 일일 권장량 대비
          Text(
            '일일 권장량 대비 (${provider.babyAgeMonths}개월 기준)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: NutritionBarChart(percentages: provider.nutritionPercentages),
            ),
          ),
          const SizedBox(height: 8),
          _buildLegend(),

          const SizedBox(height: 100), // FAB 공간
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      children: [
        _legendItem(Colors.red.shade400, '50% 미만'),
        _legendItem(Colors.orange.shade400, '50-80%'),
        _legendItem(Colors.green.shade400, '80-120%'),
        _legendItem(Colors.blue.shade400, '120% 초과'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  void _showAddIngredientDialog(BuildContext context) async {
    final provider = context.read<NutritionProvider>();
    final ingredient = await showDialog<Ingredient>(
      context: context,
      builder: (context) => IngredientPickerDialog(
        ingredients: provider.availableIngredients,
        title: '재료 추가',
      ),
    );

    if (ingredient != null) {
      provider.addIngredient(ingredient);
    }
  }

  void _showClearConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 삭제'),
        content: const Text('선택한 모든 재료를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<NutritionProvider>().clearAll();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
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
