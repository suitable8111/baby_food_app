import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/food_diary_entry.dart';
import '../models/ingredient.dart';
import '../models/nutrition.dart';
import '../models/recipe.dart';
import '../providers/diary_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';

class FoodDiaryScreen extends StatefulWidget {
  const FoodDiaryScreen({super.key});

  @override
  State<FoodDiaryScreen> createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final diaryProvider = context.read<DiaryProvider>();
    if (authProvider.userId != null) {
      diaryProvider.loadEntries(authProvider.familyId, _focusedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final diaryProvider = context.watch<DiaryProvider>();
    final authProvider = context.watch<AuthProvider>();
    final selectedEntries = diaryProvider.getEntriesForDate(_selectedDay);
    final dayNutrition = diaryProvider.getDayNutrition(_selectedDay);
    final babyAgeMonths = authProvider.userProfile?.babyAgeMonths ?? 6;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF6),
      appBar: AppBar(
        title: const Text('이유식 일지'),
      ),
      body: diaryProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // 캘린더
                _buildCalendar(diaryProvider),
                const SizedBox(height: 12),
                // 영양 요약 카드 (이유식 엔트리가 있을 때만)
                if (selectedEntries.any((e) => !e.isMilkEntry))
                  _buildNutritionCard(dayNutrition, babyAgeMonths, diaryProvider),
                const SizedBox(height: 8),
                // 타임라인 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('M월 d일 (E)', 'ko').format(_selectedDay),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6BBF59).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${selectedEntries.length}건',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6BBF59),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 타임라인
                if (selectedEntries.isEmpty)
                  _buildEmptyState()
                else
                  ...selectedEntries
                      .map((entry) => _buildTimelineItem(entry)),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntrySheet(context),
        backgroundColor: const Color(0xFFFF7043),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('기록 추가',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ====== 캘린더 ======
  Widget _buildCalendar(DiaryProvider diaryProvider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        locale: 'ko_KR',
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) {
          return diaryProvider.getEntriesForDate(day);
        },
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
          diaryProvider.setSelectedDate(selected);
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          final authProvider = context.read<AuthProvider>();
          if (authProvider.userId != null) {
            context
                .read<DiaryProvider>()
                .loadEntries(authProvider.familyId, focusedDay);
          }
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: const Color(0xFF6BBF59).withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: Color(0xFF2D2D2D),
            fontWeight: FontWeight.w600,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF6BBF59),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          markerDecoration: const BoxDecoration(
            color: Color(0xFFFF7043),
            shape: BoxShape.circle,
          ),
          markerSize: 6,
          markersMaxCount: 3,
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: Color(0xFFE57373)),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF6BBF59)),
            borderRadius: BorderRadius.circular(12),
          ),
          formatButtonTextStyle: const TextStyle(
            color: Color(0xFF6BBF59),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
          leftChevronIcon: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFF6BBF59),
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF6BBF59),
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF888888),
          ),
          weekendStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE57373),
          ),
        ),
      ),
    );
  }

  // ====== 영양 요약 카드 ======
  Widget _buildNutritionCard(
      Nutrition nutrition, int babyAgeMonths, DiaryProvider diaryProvider) {
    final percentages =
        diaryProvider.getNutritionPercentages(_selectedDay, babyAgeMonths);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFFFF7043), size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                '오늘의 영양 섭취',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const Spacer(),
              Text(
                '${nutrition.calories.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF7043),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: _buildBarChart(percentages),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '일일 권장량 대비 (%)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> percentages) {
    final colors = [
      const Color(0xFFFF7043),
      const Color(0xFF42A5F5),
      const Color(0xFF66BB6A),
      const Color(0xFFFFA726),
      const Color(0xFF7E57C2),
      const Color(0xFFE57373),
    ];

    final entries = percentages.entries.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 120,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = entries[group.x.toInt()].key;
              return BarTooltipItem(
                '$label\n${rod.toY.toStringAsFixed(0)}%',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
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
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    entries[idx].key,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (value) {
            if (value == 100) {
              return FlLine(
                color: const Color(0xFFE57373).withValues(alpha: 0.5),
                strokeWidth: 1.5,
                dashArray: [5, 5],
              );
            }
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 0.5,
            );
          },
        ),
        barGroups: List.generate(entries.length, (i) {
          final pct = entries[i].value.clamp(0, 120);
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: pct.toDouble(),
                color: colors[i % colors.length],
                width: 24,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 120,
                  color: colors[i % colors.length].withValues(alpha: 0.08),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ====== 빈 상태 ======
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            '아직 기록이 없어요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '아래 버튼으로 이유식 기록을 추가해 보세요',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // ====== 타임라인 아이템 ======
  Widget _buildTimelineItem(FoodDiaryEntry entry) {
    final authProvider = context.read<AuthProvider>();
    final showAuthor = authProvider.hasPartner && entry.authorName != null;
    final timeStr = DateFormat('HH:mm').format(entry.mealTime);
    final isMilk = entry.isMilkEntry;
    final deleteLabel = isMilk
        ? '${entry.entryType.displayName} ${entry.milkAmountMl ?? 0}ml'
        : entry.recipeName;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE57373),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('기록 삭제'),
            content: Text('\'$deleteLabel\' 기록을 삭제할까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('삭제',
                    style: TextStyle(color: Color(0xFFE57373))),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<DiaryProvider>().deleteEntry(entry.id, entry.date);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\'$deleteLabel\' 기록이 삭제되었습니다')),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 시간 + 아이콘
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMilk
                          ? entry.entryType.color.withValues(alpha: 0.12)
                          : entry.mealType.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isMilk ? entry.entryType.icon : entry.mealType.icon,
                      color: isMilk ? entry.entryType.color : entry.mealType.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showAuthor)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          entry.authorName!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    isMilk
                        ? _buildMilkEntryInfo(entry)
                        : _buildFoodEntryInfo(entry),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilkEntryInfo(FoodDiaryEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: entry.entryType.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            entry.entryType.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: entry.entryType.color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${entry.entryType.displayName} ${entry.milkAmountMl ?? 0}ml',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
        if (entry.memo != null && entry.memo!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            entry.memo!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildFoodEntryInfo(FoodDiaryEntry entry) {
    final stageColor = _getStageColor(entry.recipeStage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: entry.mealType.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.mealType.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: entry.mealType.color,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: stageColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.recipeStage.shortName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: stageColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          entry.recipeName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${entry.nutrition.calories.toStringAsFixed(0)} kcal  |  단백질 ${entry.nutrition.protein.toStringAsFixed(1)}g',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        if (entry.memo != null && entry.memo!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            entry.memo!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  // ====== 기록 추가 바텀시트 ======
  void _showAddEntrySheet(BuildContext outerContext) {
    EntryType selectedEntryType = EntryType.food;
    MealType selectedMealType = MealType.breakfast;
    TimeOfDay selectedTime = TimeOfDay.now();
    Recipe? selectedRecipe;
    final memoController = TextEditingController();
    final mlController = TextEditingController();
    String searchQuery = '';
    int? selectedMl;

    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final recipeProvider = outerContext.read<RecipeProvider>();
            final allRecipes = recipeProvider.allRecipes;
            final filtered = searchQuery.isEmpty
                ? allRecipes
                : allRecipes
                    .where((r) => r.name
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase()))
                    .toList();

            final isMilk = selectedEntryType != EntryType.food;
            final canSave = isMilk
                ? (selectedMl != null && selectedMl! > 0)
                : selectedRecipe != null;

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAF6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // 핸들
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 헤더
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        const Text(
                          '기록 추가',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // 기록 유형 선택
                        const Text('기록 유형',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: EntryType.values.map((type) {
                            final isSelected = selectedEntryType == type;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    right: type != EntryType.breastMilk ? 8 : 0),
                                child: Material(
                                  color: isSelected
                                      ? type.color
                                      : type.color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () => setSheetState(() {
                                      selectedEntryType = type;
                                      selectedRecipe = null;
                                      selectedMl = null;
                                      mlController.clear();
                                    }),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Column(
                                        children: [
                                          Icon(type.icon,
                                              color: isSelected
                                                  ? Colors.white
                                                  : type.color,
                                              size: 22),
                                          const SizedBox(height: 4),
                                          Text(
                                            type.displayName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? Colors.white
                                                  : type.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // 식사 유형 선택 (이유식만)
                        if (!isMilk) ...[
                          const Text('식사 유형',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            children: MealType.values.map((type) {
                              final isSelected = selectedMealType == type;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      right: type != MealType.snack ? 8 : 0),
                                  child: Material(
                                    color: isSelected
                                        ? type.color
                                        : type.color.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () => setSheetState(
                                          () => selectedMealType = type),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        child: Column(
                                          children: [
                                            Icon(type.icon,
                                                color: isSelected
                                                    ? Colors.white
                                                    : type.color,
                                                size: 22),
                                            const SizedBox(height: 4),
                                            Text(
                                              type.displayName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white
                                                    : type.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // 시간 선택
                        const Text('먹은 시간',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: ctx,
                                initialTime: selectedTime,
                              );
                              if (time != null) {
                                setSheetState(() => selectedTime = time);
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      color: Colors.grey.shade600, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    selectedTime.format(ctx),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.chevron_right_rounded,
                                      color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 수유: ml 입력
                        if (isMilk) ...[
                          const Text('수유량 (ml)',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [60, 80, 100, 120, 150, 180, 200, 240]
                                .map((ml) {
                              final isSelected = selectedMl == ml;
                              return Material(
                                color: isSelected
                                    ? selectedEntryType.color
                                    : selectedEntryType.color
                                        .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  onTap: () => setSheetState(() {
                                    selectedMl = ml;
                                    mlController.text = ml.toString();
                                  }),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    child: Text(
                                      '${ml}ml',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : selectedEntryType.color,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: mlController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '직접 입력 (ml)',
                              suffixText: 'ml',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade200),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            onChanged: (v) {
                              final parsed = int.tryParse(v);
                              setSheetState(() => selectedMl = parsed);
                            },
                          ),
                        ],

                        // 이유식: 레시피 선택
                        if (!isMilk) ...[
                          const Text('레시피 선택',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: InputDecoration(
                              hintText: '레시피 검색...',
                              prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade200),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                            onChanged: (v) =>
                                setSheetState(() => searchQuery = v),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  Divider(height: 1, color: Colors.grey.shade100),
                              itemBuilder: (_, i) {
                                final recipe = filtered[i];
                                final isSelected =
                                    selectedRecipe?.id == recipe.id;
                                final stageColor =
                                    _getStageColor(recipe.stage);
                                return ListTile(
                                  dense: true,
                                  selected: isSelected,
                                  selectedTileColor: const Color(0xFF6BBF59)
                                      .withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        i == 0
                                            ? 14
                                            : i == filtered.length - 1
                                                ? 14
                                                : 0),
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: stageColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      recipe.stage.shortName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: stageColor,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    recipe.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF6BBF59),
                                          size: 20)
                                      : null,
                                  onTap: () => setSheetState(
                                      () => selectedRecipe = recipe),
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // 메모
                        const Text('메모 (선택)',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: memoController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: '메모를 입력하세요...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade200),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 저장 버튼
                        FilledButton(
                          onPressed: !canSave
                              ? null
                              : () => _saveEntry(
                                    sheetContext: ctx,
                                    entryType: selectedEntryType,
                                    mealType: selectedMealType,
                                    time: selectedTime,
                                    recipe: selectedRecipe,
                                    milkAmountMl: selectedMl,
                                    memo: memoController.text.trim(),
                                  ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7043),
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            '저장',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveEntry({
    required BuildContext sheetContext,
    required EntryType entryType,
    required MealType mealType,
    required TimeOfDay time,
    Recipe? recipe,
    int? milkAmountMl,
    required String memo,
  }) async {
    final authProvider = context.read<AuthProvider>();
    final recipeProvider = context.read<RecipeProvider>();
    final diaryProvider = context.read<DiaryProvider>();

    if (authProvider.userId == null) return;

    final dateOnly = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final mealTime = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      time.hour,
      time.minute,
    );

    final isMilk = entryType != EntryType.food;
    final nutrition = isMilk
        ? Nutrition.empty
        : recipeProvider.getRecipeNutrition(recipe!);

    final entry = FoodDiaryEntry(
      id: '',
      userId: authProvider.userId!,
      familyId: authProvider.familyId,
      authorName: authProvider.displayName,
      date: dateOnly,
      entryType: entryType,
      mealType: mealType,
      mealTime: mealTime,
      recipeId: isMilk ? '' : recipe!.id,
      recipeName: isMilk ? '' : recipe!.name,
      recipeStage: isMilk ? BabyFoodStage.early : recipe!.stage,
      nutrition: nutrition,
      milkAmountMl: milkAmountMl,
      memo: memo.isEmpty ? null : memo,
    );

    final success = await diaryProvider.addEntry(entry);

    if (!sheetContext.mounted) return;
    Navigator.pop(sheetContext);

    if (!mounted) return;
    final label = isMilk
        ? '${entryType.displayName} ${milkAmountMl}ml'
        : recipe!.name;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\'$label\' 기록이 추가되었습니다')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장에 실패했습니다. 다시 시도해 주세요.'),
          backgroundColor: Color(0xFFE57373),
        ),
      );
    }
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
