import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../models/nutrition.dart';

/// 재료 선택 항목 타일
class IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final double? amount;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final ValueChanged<double>? onAmountChanged;

  const IngredientTile({
    super.key,
    required this.ingredient,
    this.amount,
    this.onTap,
    this.onRemove,
    this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(ingredient.category).withOpacity(0.2),
          child: Icon(
            _getCategoryIcon(ingredient.category),
            color: _getCategoryColor(ingredient.category),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(ingredient.name)),
            if (ingredient.isAllergen)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ingredient.allergenType ?? '알레르기',
                  style: TextStyle(fontSize: 10, color: Colors.orange.shade800),
                ),
              ),
          ],
        ),
        subtitle: amount != null
            ? Text('${amount!.toStringAsFixed(0)}g')
            : Text(ingredient.category.displayName),
        trailing: amount != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (amount! > 5) {
                        onAmountChanged?.call(amount! - 5);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => onAmountChanged?.call(amount! + 5),
                  ),
                  if (onRemove != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: onRemove,
                    ),
                ],
              )
            : const Icon(Icons.add),
      ),
    );
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

/// 재료 선택 다이얼로그
class IngredientPickerDialog extends StatefulWidget {
  final List<Ingredient> ingredients;
  final String title;

  const IngredientPickerDialog({
    super.key,
    required this.ingredients,
    this.title = '재료 선택',
  });

  @override
  State<IngredientPickerDialog> createState() => _IngredientPickerDialogState();
}

class _IngredientPickerDialogState extends State<IngredientPickerDialog> {
  String _searchQuery = '';
  IngredientCategory? _selectedCategory;

  List<Ingredient> get filteredIngredients {
    var result = widget.ingredients;

    if (_selectedCategory != null) {
      result = result.where((i) => i.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((i) =>
        i.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // 검색
            TextField(
              decoration: const InputDecoration(
                hintText: '재료 검색...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 12),
            // 카테고리 필터
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('전체'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  ...IngredientCategory.values.map((category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.displayName),
                      selected: _selectedCategory == category,
                      onSelected: (_) => setState(() => _selectedCategory = category),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 재료 목록
            Expanded(
              child: ListView.builder(
                itemCount: filteredIngredients.length,
                itemBuilder: (context, index) {
                  final ingredient = filteredIngredients[index];
                  return IngredientTile(
                    ingredient: ingredient,
                    onTap: () => Navigator.of(context).pop(ingredient),
                  );
                },
              ),
            ),
            // 닫기 버튼
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 영양소 변화량 표시 위젯
class NutritionChangeIndicator extends StatelessWidget {
  final String nutrientName;
  final double change;
  final String unit;

  const NutritionChangeIndicator({
    super.key,
    required this.nutrientName,
    required this.change,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            color: isPositive ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$nutrientName: ${isPositive ? '+' : ''}${change.toStringAsFixed(1)}$unit',
            style: TextStyle(
              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
