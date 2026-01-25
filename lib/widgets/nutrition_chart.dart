import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/nutrition.dart';

/// 영양소 막대 차트 위젯
class NutritionBarChart extends StatelessWidget {
  final Map<String, double> percentages;

  const NutritionBarChart({
    super.key,
    required this.percentages,
  });

  @override
  Widget build(BuildContext context) {
    final entries = percentages.entries.toList();

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 150,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${entries[group.x.toInt()].key}\n${rod.toY.toStringAsFixed(1)}%',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= entries.length) return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      entries[value.toInt()].key,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: const TextStyle(fontSize: 10),
                  );
                },
                reservedSize: 40,
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 50,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: value == 100 ? Colors.green : Colors.grey.shade300,
                strokeWidth: value == 100 ? 2 : 1,
                dashArray: value == 100 ? null : [5, 5],
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((entry) {
            final index = entry.key;
            final percentage = entry.value.value.clamp(0, 150).toDouble();
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: percentage,
                  color: _getColorForPercentage(percentage),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage < 50) return Colors.red.shade400;
    if (percentage < 80) return Colors.orange.shade400;
    if (percentage <= 120) return Colors.green.shade400;
    return Colors.blue.shade400;
  }
}

/// 영양소 상세 정보 카드
class NutritionInfoCard extends StatelessWidget {
  final Nutrition nutrition;
  final String title;

  const NutritionInfoCard({
    super.key,
    required this.nutrition,
    this.title = '영양 정보',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildNutritionRow('칼로리', '${nutrition.calories.toStringAsFixed(1)} kcal'),
            _buildNutritionRow('탄수화물', '${nutrition.carbohydrates.toStringAsFixed(1)} g'),
            _buildNutritionRow('단백질', '${nutrition.protein.toStringAsFixed(1)} g'),
            _buildNutritionRow('지방', '${nutrition.fat.toStringAsFixed(1)} g'),
            _buildNutritionRow('식이섬유', '${nutrition.fiber.toStringAsFixed(1)} g'),
            const Divider(),
            _buildNutritionRow('비타민 A', '${nutrition.vitaminA.toStringAsFixed(1)} μg'),
            _buildNutritionRow('비타민 C', '${nutrition.vitaminC.toStringAsFixed(1)} mg'),
            _buildNutritionRow('비타민 D', '${nutrition.vitaminD.toStringAsFixed(1)} μg'),
            const Divider(),
            _buildNutritionRow('칼슘', '${nutrition.calcium.toStringAsFixed(1)} mg'),
            _buildNutritionRow('철분', '${nutrition.iron.toStringAsFixed(1)} mg'),
            _buildNutritionRow('아연', '${nutrition.zinc.toStringAsFixed(1)} mg'),
            _buildNutritionRow('나트륨', '${nutrition.sodium.toStringAsFixed(1)} mg'),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// 영양소 원형 차트 (파이차트)
class NutritionPieChart extends StatelessWidget {
  final Nutrition nutrition;

  const NutritionPieChart({
    super.key,
    required this.nutrition,
  });

  @override
  Widget build(BuildContext context) {
    final total = nutrition.carbohydrates + nutrition.protein + nutrition.fat;
    if (total == 0) {
      return const Center(child: Text('영양소 정보가 없습니다'));
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              value: nutrition.carbohydrates,
              color: Colors.amber,
              title: '탄수화물\n${(nutrition.carbohydrates / total * 100).toStringAsFixed(1)}%',
              titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
              radius: 80,
            ),
            PieChartSectionData(
              value: nutrition.protein,
              color: Colors.redAccent,
              title: '단백질\n${(nutrition.protein / total * 100).toStringAsFixed(1)}%',
              titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
              radius: 80,
            ),
            PieChartSectionData(
              value: nutrition.fat,
              color: Colors.blue,
              title: '지방\n${(nutrition.fat / total * 100).toStringAsFixed(1)}%',
              titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
              radius: 80,
            ),
          ],
        ),
      ),
    );
  }
}
