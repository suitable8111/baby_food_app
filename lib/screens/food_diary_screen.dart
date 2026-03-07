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
import 'weekly_stats_screen.dart';

class FoodDiaryScreen extends StatefulWidget {
  const FoodDiaryScreen({super.key});

  @override
  State<FoodDiaryScreen> createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  double _slideDirection = 0.0; // 1.0 = 다음날(왼쪽으로), -1.0 = 이전날(오른쪽으로)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _moveDay(int days, DiaryProvider diaryProvider) {
    final newDay = _selectedDay.add(Duration(days: days));
    setState(() {
      _slideDirection = days > 0 ? 1.0 : -1.0;
      _selectedDay = newDay;
      _focusedDay = newDay;
    });
    diaryProvider.setSelectedDate(newDay);
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userId != null) {
      diaryProvider.loadEntries(authProvider.familyId, newDay);
    }
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _moveDay(-1, diaryProvider),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Icon(Icons.chevron_left_rounded, size: 22),
              ),
            ),
            GestureDetector(
              onTap: () => _showCalendarSheet(diaryProvider),
              child: Text(
                DateFormat('M월 d일 (E)', 'ko').format(_selectedDay),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            GestureDetector(
              onTap: () => _moveDay(1, diaryProvider),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Icon(Icons.chevron_right_rounded, size: 22),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showCalendarSheet(diaryProvider),
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: '날짜 선택',
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeeklyStatsScreen()),
            ),
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: '주간 통계',
          ),
        ],
      ),
      body: diaryProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onHorizontalDragEnd: (details) {
                final dx = details.primaryVelocity ?? 0;
                if (dx < -300) {
                  _moveDay(1, diaryProvider);
                } else if (dx > 300) {
                  _moveDay(-1, diaryProvider);
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                reverseDuration: const Duration(milliseconds: 280),
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    ...previousChildren,
                    ?currentChild,
                  ],
                ),
                transitionBuilder: (child, animation) {
                  final isEntering =
                      child.key == ValueKey(_selectedDay.toIso8601String());
                  final begin = isEntering
                      ? Offset(_slideDirection, 0)
                      : Offset(-_slideDirection, 0);
                  return ClipRect(
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: begin,
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
                child: ListView(
                  key: ValueKey(_selectedDay.toIso8601String()),
                  padding: const EdgeInsets.only(top: 12, bottom: 100),
                  children: [
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
                              color: const Color(0xFF6BBF59)
                                  .withValues(alpha: 0.12),
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
                    // 영양 요약 카드 (이유식 엔트리가 있을 때만)
                    if (selectedEntries.any((e) => e.entryType.isNutritionEntry))
                      _buildNutritionCard(
                          dayNutrition, babyAgeMonths, diaryProvider),
                    const SizedBox(height: 8),
                    // 타임라인
                    if (selectedEntries.isEmpty)
                      _buildEmptyState()
                    else
                      ...selectedEntries
                          .map((entry) => _buildTimelineItem(entry)),
                  ],
                ),
              ),
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

  // ====== 달력 바텀시트 ======
  void _showCalendarSheet(DiaryProvider diaryProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _buildCalendar(diaryProvider, onDaySelected: (_) {
              Navigator.pop(ctx);
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ====== 캘린더 ======
  Widget _buildCalendar(DiaryProvider diaryProvider,
      {void Function(DateTime)? onDaySelected}) {
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
        calendarFormat: onDaySelected != null
            ? CalendarFormat.month
            : _calendarFormat,
        availableCalendarFormats: onDaySelected != null
            ? const {
                CalendarFormat.month: '월',
                CalendarFormat.week: '주',
              }
            : const {CalendarFormat.week: '주'},
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) => diaryProvider.getEntriesForDate(day),
        onDaySelected: (selected, focused) {
          setState(() {
            _slideDirection = selected.isAfter(_selectedDay) ? 1.0 : -1.0;
            _selectedDay = selected;
            _focusedDay = focused;
          });
          diaryProvider.setSelectedDate(selected);
          onDaySelected?.call(selected);
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
          formatButtonVisible: onDaySelected != null,
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
            Icons.edit_note_rounded,
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
            '아래 버튼으로 기록을 추가해 보세요',
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
    final deleteLabel = _getEntryLabel(entry);

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
              // 아이콘 + 시간
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: entry.entryType.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      entry.entryType.icon,
                      color: entry.entryType.color,
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
                    _buildEntryInfo(entry),
                  ],
                ),
              ),
              // 수정 버튼
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 18, color: Colors.grey.shade400),
                onPressed: () =>
                    _showAddEntrySheet(context, entryToEdit: entry),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEntryLabel(FoodDiaryEntry entry) {
    switch (entry.entryType) {
      case EntryType.food:
        return entry.recipeName;
      case EntryType.breastMilk:
        if (entry.milkAmountMl == null) {
          return '${entry.entryType.displayName} (양 모름)';
        }
        return '${entry.entryType.displayName} ${entry.milkAmountMl}ml';
      case EntryType.formulaMilk:
      case EntryType.pumpedMilk:
      case EntryType.pumping:
      case EntryType.cowMilk:
      case EntryType.water:
        return '${entry.entryType.displayName} ${entry.milkAmountMl ?? 0}ml';
      case EntryType.snackFood:
        return entry.recipeName.isEmpty
            ? entry.entryType.displayName
            : entry.recipeName;
      case EntryType.diaper:
        return '${entry.entryType.displayName} (${entry.diaperType?.displayName ?? ''})';
      case EntryType.sleep:
      case EntryType.bath:
      case EntryType.play:
      case EntryType.tummyTime:
        final min = entry.durationMinutes ?? 0;
        return '${entry.entryType.displayName} $min분';
      case EntryType.temperature:
        return '${entry.entryType.displayName} ${entry.temperatureCelsius?.toStringAsFixed(1) ?? ''}°C';
      case EntryType.medication:
        return entry.recipeName.isEmpty
            ? entry.entryType.displayName
            : entry.recipeName;
      case EntryType.hospital:
      case EntryType.other:
        return entry.entryType.displayName;
    }
  }

  Widget _buildEntryInfo(FoodDiaryEntry entry) {
    switch (entry.entryType) {
      case EntryType.food:
        return _buildFoodEntryInfo(entry);
      case EntryType.formulaMilk:
      case EntryType.breastMilk:
      case EntryType.pumpedMilk:
      case EntryType.pumping:
      case EntryType.cowMilk:
      case EntryType.water:
        return _buildLiquidEntryInfo(entry);
      case EntryType.snackFood:
        return _buildSimpleEntryInfo(
          entry,
          subtitle: entry.recipeName.isEmpty ? null : entry.recipeName,
        );
      case EntryType.diaper:
        return _buildDiaperEntryInfo(entry);
      case EntryType.sleep:
      case EntryType.bath:
      case EntryType.play:
      case EntryType.tummyTime:
        return _buildDurationEntryInfo(entry);
      case EntryType.temperature:
        return _buildTemperatureEntryInfo(entry);
      case EntryType.medication:
        return _buildSimpleEntryInfo(
          entry,
          subtitle: entry.recipeName.isEmpty ? null : entry.recipeName,
        );
      case EntryType.hospital:
      case EntryType.other:
        return _buildSimpleEntryInfo(entry);
    }
  }

  Widget _buildTypeChip(EntryType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: type.color,
        ),
      ),
    );
  }

  Widget _buildFoodEntryInfo(FoodDiaryEntry entry) {
    final stageColor = _getStageColor(entry.recipeStage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildTypeChip(entry.entryType),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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

  Widget _buildLiquidEntryInfo(FoodDiaryEntry entry) {
    final mlText =
        entry.entryType == EntryType.breastMilk && entry.milkAmountMl == null
            ? '양 모름'
            : '${entry.milkAmountMl ?? 0} ml';
    final hasDuration = entry.entryType.isMilkFeedingEntry &&
        entry.durationMinutes != null &&
        entry.durationMinutes! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeChip(entry.entryType),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              mlText,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D2D2D),
              ),
            ),
            if (hasDuration) ...[
              Text(
                '  ·  ${entry.durationMinutes}분',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
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

  Widget _buildDiaperEntryInfo(FoodDiaryEntry entry) {
    final dtype = entry.diaperType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeChip(entry.entryType),
        const SizedBox(height: 6),
        if (dtype != null)
          Row(
            children: [
              Icon(dtype.icon, color: dtype.color, size: 16),
              const SizedBox(width: 4),
              Text(
                dtype.displayName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          )
        else
          const Text(
            '기저귀 교체',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D2D2D)),
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

  Widget _buildDurationEntryInfo(FoodDiaryEntry entry) {
    final min = entry.durationMinutes ?? 0;
    String durationStr;
    if (min >= 60) {
      final h = min ~/ 60;
      final m = min % 60;
      durationStr = m > 0 ? '$h시간 $m분' : '$h시간';
    } else {
      durationStr = '$min분';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeChip(entry.entryType),
        const SizedBox(height: 6),
        Text(
          durationStr,
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

  Widget _buildTemperatureEntryInfo(FoodDiaryEntry entry) {
    final temp = entry.temperatureCelsius;
    final isHigh = temp != null && temp >= 37.5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeChip(entry.entryType),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              temp != null ? '${temp.toStringAsFixed(1)}°C' : '-',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isHigh
                    ? const Color(0xFFE57373)
                    : const Color(0xFF2D2D2D),
              ),
            ),
            if (isHigh) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE57373).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '발열',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE57373),
                  ),
                ),
              ),
            ],
          ],
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

  Widget _buildSimpleEntryInfo(FoodDiaryEntry entry, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeChip(entry.entryType),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ],
        if (entry.memo != null && entry.memo!.isNotEmpty) ...[
          SizedBox(height: subtitle != null ? 4 : 6),
          Text(
            entry.memo!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  // ====== 기록 추가/수정 바텀시트 ======
  void _showAddEntrySheet(BuildContext outerContext,
      {FoodDiaryEntry? entryToEdit}) {
    final isEditing = entryToEdit != null;
    final recipeProviderForInit =
        isEditing ? outerContext.read<RecipeProvider>() : null;

    EntryType selectedEntryType =
        entryToEdit?.entryType ?? EntryType.formulaMilk;
    MealType selectedMealType = entryToEdit?.mealType ?? MealType.breakfast;
    TimeOfDay selectedTime = entryToEdit != null
        ? TimeOfDay.fromDateTime(entryToEdit.mealTime)
        : TimeOfDay.now();
    Recipe? selectedRecipe =
        (entryToEdit != null && entryToEdit.recipeId.isNotEmpty)
            ? recipeProviderForInit?.getRecipeById(entryToEdit.recipeId)
            : null;
    DiaperType? selectedDiaperType =
        entryToEdit?.diaperType ?? DiaperType.wet;

    final memoController =
        TextEditingController(text: entryToEdit?.memo ?? '');
    final mlController = TextEditingController(
        text: entryToEdit?.milkAmountMl?.toString() ?? '');
    final nameController = TextEditingController(
        text: (entryToEdit != null && entryToEdit.entryType != EntryType.food)
            ? entryToEdit.recipeName
            : '');
    final tempController = TextEditingController(
        text: entryToEdit?.temperatureCelsius?.toString() ?? '');
    final durationController = TextEditingController(
        text: entryToEdit?.durationMinutes?.toString() ?? '');

    String searchQuery = '';
    int? selectedMl = entryToEdit?.milkAmountMl;
    int? selectedDuration = entryToEdit?.durationMinutes;

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

            final type = selectedEntryType;

            bool canSave() {
              switch (type) {
                case EntryType.food:
                  return selectedRecipe != null;
                case EntryType.breastMilk:
                  return selectedMl != null &&
                      (selectedMl! > 0 || selectedMl == -1);
                case EntryType.formulaMilk:
                case EntryType.pumpedMilk:
                case EntryType.pumping:
                case EntryType.cowMilk:
                case EntryType.water:
                  return selectedMl != null && selectedMl! > 0;
                case EntryType.sleep:
                case EntryType.bath:
                case EntryType.play:
                case EntryType.tummyTime:
                  return selectedDuration != null && selectedDuration! > 0;
                case EntryType.temperature:
                  return tempController.text.trim().isNotEmpty &&
                      double.tryParse(tempController.text.trim()) != null;
                case EntryType.diaper:
                case EntryType.snackFood:
                case EntryType.medication:
                case EntryType.hospital:
                case EntryType.other:
                  return true;
              }
            }

            final keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;
            return GestureDetector(
              onTap: () => FocusScope.of(ctx).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Container(
              height: MediaQuery.of(ctx).size.height * 0.9,
              padding: EdgeInsets.only(bottom: keyboardHeight),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAF6),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
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
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        // ── 기록 유형 선택 ──
                        _buildEntryTypeGrid(
                          selectedEntryType,
                          (newType) => setSheetState(() {
                            selectedEntryType = newType;
                            selectedRecipe = null;
                            selectedMl = null;
                            selectedDuration = null;
                            selectedDiaperType = DiaperType.wet;
                            mlController.clear();
                            tempController.clear();
                            durationController.clear();
                            nameController.clear();
                          }),
                        ),

                        const SizedBox(height: 20),

                        // ── 시간 선택 ──
                        const Text('시간',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
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

                        // ── 유형별 입력 ──
                        if (type == EntryType.food) ...[
                          _buildMealTypeSection(
                              selectedMealType,
                              (m) =>
                                  setSheetState(() => selectedMealType = m)),
                          const SizedBox(height: 20),
                          _buildRecipePicker(
                            filtered: filtered,
                            selected: selectedRecipe,
                            onSelect: (r) =>
                                setSheetState(() => selectedRecipe = r),
                            onSearch: (q) =>
                                setSheetState(() => searchQuery = q),
                          ),
                        ],

                        if (type.isLiquidEntry) ...[
                          _buildMlSection(
                            entryType: type,
                            selectedMl: selectedMl,
                            mlController: mlController,
                            showUnknown: type == EntryType.breastMilk,
                            onSelectUnknown: () => setSheetState(() {
                              selectedMl = -1;
                              mlController.clear();
                            }),
                            onSelect: (ml) => setSheetState(() {
                              selectedMl = ml;
                              mlController.text = ml.toString();
                            }),
                            onChange: (v) => setSheetState(
                                () => selectedMl = int.tryParse(v)),
                          ),
                        ],

                        if (type.isMilkFeedingEntry) ...[
                          const SizedBox(height: 20),
                          _buildFeedingDurationSection(
                            entryType: type,
                            selected: selectedDuration,
                            controller: durationController,
                            onSelect: (d) => setSheetState(() {
                              selectedDuration = d;
                              durationController.text = d.toString();
                            }),
                            onChange: (v) => setSheetState(
                                () => selectedDuration = int.tryParse(v)),
                          ),
                        ],

                        if (type == EntryType.diaper) ...[
                          _buildDiaperSection(
                            selected: selectedDiaperType,
                            onSelect: (d) => setSheetState(
                                () => selectedDiaperType = d),
                          ),
                        ],

                        if (type.isDurationEntry) ...[
                          _buildDurationSection(
                            entryType: type,
                            selected: selectedDuration,
                            controller: durationController,
                            onSelect: (d) => setSheetState(() {
                              selectedDuration = d;
                              durationController.text = d.toString();
                            }),
                            onChange: (v) => setSheetState(
                                () => selectedDuration = int.tryParse(v)),
                          ),
                        ],

                        if (type == EntryType.temperature) ...[
                          _buildTemperatureSection(
                            controller: tempController,
                            onChange: (_) => setSheetState(() {}),
                          ),
                        ],

                        if (type == EntryType.snackFood ||
                            type == EntryType.medication) ...[
                          _buildNameSection(
                            type: type,
                            controller: nameController,
                            onChange: (_) => setSheetState(() {}),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ── 메모 ──
                        const Text('메모 (선택)',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
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
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── 저장 버튼 ──
                        FilledButton(
                          onPressed: !canSave()
                              ? null
                              : isEditing
                                  ? () => _updateEntry(
                                        sheetContext: ctx,
                                        original: entryToEdit,
                                        entryType: selectedEntryType,
                                        mealType: selectedMealType,
                                        time: selectedTime,
                                        recipe: selectedRecipe,
                                        milkAmountMl: selectedMl == -1
                                            ? null
                                            : selectedMl,
                                        diaperType: selectedDiaperType,
                                        durationMinutes: selectedDuration,
                                        temperatureCelsius: double.tryParse(
                                            tempController.text.trim()),
                                        name: nameController.text.trim(),
                                        memo: memoController.text.trim(),
                                      )
                                  : () => _saveEntry(
                                        sheetContext: ctx,
                                        entryType: selectedEntryType,
                                        mealType: selectedMealType,
                                        time: selectedTime,
                                        recipe: selectedRecipe,
                                        milkAmountMl: selectedMl == -1
                                            ? null
                                            : selectedMl,
                                        diaperType: selectedDiaperType,
                                        durationMinutes: selectedDuration,
                                        temperatureCelsius: double.tryParse(
                                            tempController.text.trim()),
                                        name: nameController.text.trim(),
                                        memo: memoController.text.trim(),
                                      ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7043),
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            isEditing ? '수정' : '저장',
                            style: const TextStyle(
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
            ), // Container
            ); // GestureDetector
          },
        );
      },
    );
  }

  // ── 기록 유형 그리드 ──
  static const _entryCategories = [
    {'label': '수유 / 음식', 'types': [
      EntryType.food, EntryType.formulaMilk, EntryType.breastMilk,
      EntryType.pumpedMilk, EntryType.pumping, EntryType.cowMilk,
      EntryType.water, EntryType.snackFood,
    ]},
    {'label': '돌봄', 'types': [
      EntryType.diaper, EntryType.bath, EntryType.hospital,
      EntryType.temperature, EntryType.medication,
    ]},
    {'label': '활동', 'types': [
      EntryType.sleep, EntryType.play, EntryType.tummyTime,
    ]},
    {'label': '기타', 'types': [EntryType.other]},
  ];

  Widget _buildEntryTypeGrid(
      EntryType selected, void Function(EntryType) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in _entryCategories) ...[
          Text(
            category['label'] as String,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (category['types'] as List<EntryType>).map((type) {
              final isSelected = selected == type;
              return GestureDetector(
                onTap: () => onSelect(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? type.color
                        : type.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: type.color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type.icon,
                        size: 16,
                        color: isSelected ? Colors.white : type.color,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        type.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : type.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  // ── 식사 유형 ──
  Widget _buildMealTypeSection(
      MealType selected, void Function(MealType) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('식사 유형',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: MealType.values.map((type) {
            final isSelected = selected == type;
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
                    onTap: () => onSelect(type),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Icon(type.icon,
                              color:
                                  isSelected ? Colors.white : type.color,
                              size: 22),
                          const SizedBox(height: 4),
                          Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected ? Colors.white : type.color,
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
      ],
    );
  }

  // ── 레시피 선택 ──
  Widget _buildRecipePicker({
    required List<Recipe> filtered,
    required Recipe? selected,
    required void Function(Recipe) onSelect,
    required void Function(String) onSearch,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('레시피 선택',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: '레시피 검색...',
            prefixIcon:
                const Icon(Icons.search_rounded, size: 20),
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
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: onSearch,
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text('레시피가 없습니다',
                        style: TextStyle(
                            color: Colors.grey.shade400)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, si) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (_, i) {
                    final recipe = filtered[i];
                    final isSelected = selected?.id == recipe.id;
                    final stageColor = _getStageColor(recipe.stage);
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
                          ? const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF6BBF59), size: 20)
                          : null,
                      onTap: () => onSelect(recipe),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── ml 입력 ──
  Widget _buildMlSection({
    required EntryType entryType,
    required int? selectedMl,
    required TextEditingController mlController,
    required void Function(int) onSelect,
    required void Function(String) onChange,
    bool showUnknown = false,
    VoidCallback? onSelectUnknown,
  }) {
    const presets = [60, 80, 100, 120, 150, 180, 200, 240];
    final isUnknown = selectedMl == -1;

    Widget buildChip({
      required String label,
      required bool isSelected,
      required VoidCallback onTap,
    }) {
      return Material(
        color: isSelected
            ? entryType.color
            : entryType.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : entryType.color,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${entryType.displayName} 양 (ml)',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (showUnknown)
              buildChip(
                label: '모름',
                isSelected: isUnknown,
                onTap: onSelectUnknown ?? () {},
              ),
            ...presets.map((ml) => buildChip(
                  label: '${ml}ml',
                  isSelected: !isUnknown && selectedMl == ml,
                  onTap: () => onSelect(ml),
                )),
          ],
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
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: onChange,
        ),
      ],
    );
  }

  // ── 수유 시간 입력 ──
  Widget _buildFeedingDurationSection({
    required EntryType entryType,
    required int? selected,
    required TextEditingController controller,
    required void Function(int) onSelect,
    required void Function(String) onChange,
  }) {
    const presets = [5, 10, 15, 20, 30, 45];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('수유 시간 (선택)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((min) {
            final isSelected = selected == min;
            return Material(
              color: isSelected
                  ? entryType.color
                  : entryType.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => onSelect(min),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Text(
                    '$min분',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : entryType.color,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '직접 입력 (분)',
            suffixText: '분',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: onChange,
        ),
      ],
    );
  }

  // ── 기저귀 선택 ──
  Widget _buildDiaperSection({
    required DiaperType? selected,
    required void Function(DiaperType) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('기저귀 종류',
            style:
                TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: DiaperType.values.map((d) {
            final isSelected = selected == d;
            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: d != DiaperType.dry ? 8 : 0),
                child: Material(
                  color: isSelected
                      ? d.color
                      : d.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onSelect(d),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Icon(d.icon,
                              color:
                                  isSelected ? Colors.white : d.color,
                              size: 20),
                          const SizedBox(height: 4),
                          Text(
                            d.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected ? Colors.white : d.color,
                            ),
                            textAlign: TextAlign.center,
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
      ],
    );
  }

  // ── 시간(분) 입력 ──
  Widget _buildDurationSection({
    required EntryType entryType,
    required int? selected,
    required TextEditingController controller,
    required void Function(int) onSelect,
    required void Function(String) onChange,
  }) {
    final presets = entryType == EntryType.sleep
        ? [30, 60, 90, 120, 150, 180]
        : [5, 10, 15, 20, 30, 45];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${entryType.displayName} 시간 (분)',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((min) {
            final isSelected = selected == min;
            String label;
            if (min >= 60) {
              final h = min ~/ 60;
              final m = min % 60;
              label = m > 0 ? '${h}h${m}m' : '${h}h';
            } else {
              label = '$min분';
            }
            return Material(
              color: isSelected
                  ? entryType.color
                  : entryType.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => onSelect(min),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : entryType.color,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '직접 입력 (분)',
            suffixText: '분',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: onChange,
        ),
      ],
    );
  }

  // ── 체온 입력 ──
  Widget _buildTemperatureSection({
    required TextEditingController controller,
    required void Function(String) onChange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('체온',
            style:
                TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '예: 36.5',
            suffixText: '°C',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: onChange,
        ),
      ],
    );
  }

  // ── 이름 입력 (간식/투약) ──
  Widget _buildNameSection({
    required EntryType type,
    required TextEditingController controller,
    required void Function(String) onChange,
  }) {
    final hint = type == EntryType.snackFood ? '간식 이름' : '약 이름 / 용량';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(type == EntryType.snackFood ? '간식 이름 (선택)' : '투약 정보 (선택)',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: onChange,
        ),
      ],
    );
  }

  // ====== 저장 ======
  Future<void> _saveEntry({
    required BuildContext sheetContext,
    required EntryType entryType,
    required MealType mealType,
    required TimeOfDay time,
    Recipe? recipe,
    int? milkAmountMl,
    DiaperType? diaperType,
    int? durationMinutes,
    double? temperatureCelsius,
    String name = '',
    required String memo,
  }) async {
    final authProvider = context.read<AuthProvider>();
    final recipeProvider = context.read<RecipeProvider>();
    final diaryProvider = context.read<DiaryProvider>();

    if (authProvider.userId == null) return;

    final dateOnly = DateTime(
        _selectedDay.year, _selectedDay.month, _selectedDay.day);
    final mealTime = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      time.hour,
      time.minute,
    );

    final isFood = entryType == EntryType.food;
    final nutrition = isFood
        ? recipeProvider.getRecipeNutrition(recipe!)
        : Nutrition.empty;

    final entry = FoodDiaryEntry(
      id: '',
      userId: authProvider.userId!,
      familyId: authProvider.familyId,
      authorName: authProvider.displayName,
      date: dateOnly,
      entryType: entryType,
      mealType: mealType,
      mealTime: mealTime,
      recipeId: isFood ? recipe!.id : '',
      recipeName: isFood
          ? recipe!.name
          : (name.isEmpty ? entryType.displayName : name),
      recipeStage: isFood ? recipe!.stage : BabyFoodStage.early,
      nutrition: nutrition,
      milkAmountMl: milkAmountMl,
      diaperType: diaperType,
      durationMinutes: durationMinutes,
      temperatureCelsius: temperatureCelsius,
      memo: memo.isEmpty ? null : memo,
    );

    final success = await diaryProvider.addEntry(entry);

    if (!sheetContext.mounted) return;
    Navigator.pop(sheetContext);

    if (!mounted) return;
    final label = _getEntryLabel(entry);
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

  // ====== 수정 ======
  Future<void> _updateEntry({
    required BuildContext sheetContext,
    required FoodDiaryEntry original,
    required EntryType entryType,
    required MealType mealType,
    required TimeOfDay time,
    Recipe? recipe,
    int? milkAmountMl,
    DiaperType? diaperType,
    int? durationMinutes,
    double? temperatureCelsius,
    String name = '',
    required String memo,
  }) async {
    final recipeProvider = context.read<RecipeProvider>();
    final diaryProvider = context.read<DiaryProvider>();

    final mealTime = DateTime(
      original.date.year,
      original.date.month,
      original.date.day,
      time.hour,
      time.minute,
    );

    final isFood = entryType == EntryType.food;
    final nutrition = isFood
        ? recipeProvider.getRecipeNutrition(recipe!)
        : Nutrition.empty;

    final updated = original.copyWith(
      entryType: entryType,
      mealType: mealType,
      mealTime: mealTime,
      recipeId: isFood ? recipe!.id : '',
      recipeName: isFood
          ? recipe!.name
          : (name.isEmpty ? entryType.displayName : name),
      recipeStage: isFood ? recipe!.stage : BabyFoodStage.early,
      nutrition: nutrition,
      milkAmountMl: milkAmountMl,
      diaperType: diaperType,
      durationMinutes: durationMinutes,
      temperatureCelsius: temperatureCelsius,
      memo: memo.isEmpty ? null : memo,
    );

    final success = await diaryProvider.updateEntry(updated);

    if (!sheetContext.mounted) return;
    Navigator.pop(sheetContext);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기록이 수정되었습니다')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('수정에 실패했습니다. 다시 시도해 주세요.'),
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
