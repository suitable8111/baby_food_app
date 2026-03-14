import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/diary_provider.dart';
import '../providers/auth_provider.dart';

class WeeklyStatsScreen extends StatefulWidget {
  const WeeklyStatsScreen({super.key});

  @override
  State<WeeklyStatsScreen> createState() => _WeeklyStatsScreenState();
}

class _WeeklyStatsScreenState extends State<WeeklyStatsScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    // 이번 주 월요일로 시작
    final now = DateTime.now();
    _weekStart = _getWeekStart(now);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  DateTime _getWeekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    final diary = context.read<DiaryProvider>();
    if (auth.userId != null) {
      diary.loadWeeklyEntries(auth.familyId, _weekStart);
    }
  }

  void _prevWeek() {
    setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
    _loadData();
  }

  void _nextWeek() {
    final nextStart = _weekStart.add(const Duration(days: 7));
    if (nextStart.isAfter(DateTime.now())) return;
    setState(() => _weekStart = nextStart);
    _loadData();
  }

  String _weekLabel() {
    final end = _weekStart.add(const Duration(days: 6));
    if (_weekStart.month == end.month) {
      return '${DateFormat('M월 d일', 'ko').format(_weekStart)} ~ ${DateFormat('d일', 'ko').format(end)}';
    }
    return '${DateFormat('M월 d일', 'ko').format(_weekStart)} ~ ${DateFormat('M월 d일', 'ko').format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final diary = context.watch<DiaryProvider>();

    final liquidStats = diary.getWeeklyLiquidStats(_weekStart);
    final liquidCountStats = diary.getWeeklyLiquidCountStats(_weekStart);
    final sleepStats = diary.getWeeklySleepStats(_weekStart);
    final diaperStats = diary.getWeeklyDiaperStats(_weekStart);
    final peeStats = diary.getWeeklyPeeStats(_weekStart);
    final poopStats = diary.getWeeklyPoopStats(_weekStart);
    final tempStats = diary.getWeeklyTemperatureStats(_weekStart);
    final activityStats = diary.getWeeklyActivityStats(_weekStart);
    final caloriesStats = diary.getWeeklyCaloriesStats(_weekStart);
    final feedingDurationStats = diary.getWeeklyFeedingDurationStats(_weekStart);

    final totalLiquidMl = liquidStats.values.fold(0, (a, b) => a + b);
    final totalLiquidCount = liquidCountStats.values.fold(0, (a, b) => a + b);
    final totalSleepMin = sleepStats.values.fold(0, (a, b) => a + b);
    final totalDiapers = diaperStats.values.fold(0, (a, b) => a + b);
    final totalPee = peeStats.values.fold(0, (a, b) => a + b);
    final totalPoop = poopStats.values.fold(0, (a, b) => a + b);
    final hasNutrition = caloriesStats.values.any((v) => v > 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF6),
      appBar: AppBar(
        title: const Text('주간 통계'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2D2D2D),
      ),
      body: diary.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // 주차 네비게이터
                    _buildWeekNavigator(),
                    const SizedBox(height: 16),
                    // 요약 카드
                    _buildSummaryRow(
                      totalLiquidMl: totalLiquidMl,
                      totalLiquidCount: totalLiquidCount,
                      totalSleepMin: totalSleepMin,
                      totalDiapers: totalDiapers,
                    ),
                    const SizedBox(height: 20),
                    // 이번 주 영양 섭취 (이유식 기록이 있을 때만)
                    if (hasNutrition) ...[
                      _buildNutritionCard(diary),
                      const SizedBox(height: 16),
                    ],
                    // 수유/음료 (건수 있으면 표시)
                    if (liquidCountStats.values.any((v) => v > 0)) ...[
                      _buildChartCard(
                        title: '수유 & 음료',
                        subtitle: '막대: 섭취량(ml)  ·  선: 횟수(회)',
                        icon: Icons.local_cafe_rounded,
                        color: const Color(0xFF29B6F6),
                        child: _buildLiquidComboChart(
                          mlStats: liquidStats,
                          countStats: liquidCountStats,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // 수유 시간
                    if (feedingDurationStats.values.any((v) => v > 0)) ...[
                      _buildChartCard(
                        title: '수유 시간',
                        subtitle: '일별 총 수유 시간 (분)',
                        icon: Icons.favorite_rounded,
                        color: const Color(0xFFF48FB1),
                        child: _buildBarChart(
                          stats: feedingDurationStats,
                          color: const Color(0xFFF48FB1),
                          unit: '분',
                          maxY: _calcMaxY(feedingDurationStats.values, 30),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // 수면
                    if (sleepStats.values.any((v) => v > 0)) ...[
                      _buildChartCard(
                        title: '수면',
                        subtitle: '일별 총 수면 시간 (분)',
                        icon: Icons.bedtime_rounded,
                        color: const Color(0xFF9575CD),
                        child: _buildBarChart(
                          stats: sleepStats,
                          color: const Color(0xFF9575CD),
                          unit: '분',
                          maxY: _calcMaxY(sleepStats.values, 120),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // 기저귀 (소변/대변 분리)
                    if (diaperStats.values.any((v) => v > 0)) ...[
                      _buildDiaperCard(
                        diaperStats: diaperStats,
                        peeStats: peeStats,
                        poopStats: poopStats,
                        totalPee: totalPee,
                        totalPoop: totalPoop,
                      ),
                      const SizedBox(height: 16),
                    ],
                    // 체온
                    if (tempStats.isNotEmpty) ...[
                      _buildChartCard(
                        title: '체온',
                        subtitle: '일별 체온 기록 (°C)',
                        icon: Icons.thermostat_rounded,
                        color: const Color(0xFFF06292),
                        child: _buildTempLineChart(tempStats),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // 활동
                    if (activityStats.values.any((v) => v > 0)) ...[
                      _buildChartCard(
                        title: '활동 (놀이 + 터미타임)',
                        subtitle: '일별 총 활동 시간 (분)',
                        icon: Icons.sports_esports_rounded,
                        color: const Color(0xFF66BB6A),
                        child: _buildBarChart(
                          stats: activityStats,
                          color: const Color(0xFF66BB6A),
                          unit: '분',
                          maxY: _calcMaxY(activityStats.values, 60),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // 데이터 없음 안내
                    if (!hasNutrition &&
                        liquidStats.values.every((v) => v == 0) &&
                        sleepStats.values.every((v) => v == 0) &&
                        diaperStats.values.every((v) => v == 0) &&
                        tempStats.isEmpty &&
                        activityStats.values.every((v) => v == 0) &&
                        feedingDurationStats.values.every((v) => v == 0))
                      _buildNoData(),
                  ],
                ),
    );
  }

  // ====== 이번 주 영양 섭취 카드 ======
  Widget _buildNutritionCard(DiaryProvider diary) {
    // 주간 총 영양 합산
    double totalCal = 0, totalProtein = 0, totalCarbs = 0, totalFat = 0;
    for (int i = 0; i < 7; i++) {
      final day = _normalizeDate(_weekStart.add(Duration(days: i)));
      final n = diary.getDayNutrition(day);
      totalCal += n.calories;
      totalProtein += n.protein;
      totalCarbs += n.carbohydrates;
      totalFat += n.fat;
    }
    final avgCal = totalCal / 7;

    final caloriesStats = diary.getWeeklyCaloriesStats(_weekStart);
    final maxCal = caloriesStats.values
        .fold(0.0, (a, b) => a > b ? a : b);

    return Container(
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
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFFFF7043), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '이번 주 영양 섭취',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  Text(
                    '이유식 기준 · 일별 칼로리 (kcal)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 칼로리 바 차트
          SizedBox(
            height: 140,
            child: _buildCaloriesBarChart(caloriesStats, maxCal),
          ),
          const SizedBox(height: 16),
          // 주간 영양 요약 칩 행
          Row(
            children: [
              _buildNutrientChip('총 칼로리', '${totalCal.toStringAsFixed(0)} kcal',
                  const Color(0xFFFF7043)),
              const SizedBox(width: 8),
              _buildNutrientChip(
                  '일 평균', '${avgCal.toStringAsFixed(0)} kcal', const Color(0xFFFFA726)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildNutrientChip('단백질', '${totalProtein.toStringAsFixed(1)}g',
                  const Color(0xFF42A5F5)),
              const SizedBox(width: 8),
              _buildNutrientChip('탄수화물', '${totalCarbs.toStringAsFixed(1)}g',
                  const Color(0xFF66BB6A)),
              const SizedBox(width: 8),
              _buildNutrientChip('지방', '${totalFat.toStringAsFixed(1)}g',
                  const Color(0xFF7E57C2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesBarChart(
      Map<DateTime, double> stats, double maxCal) {
    final labels = _dayLabels();
    final safeMax = maxCal < 100 ? 500.0 : maxCal * 1.25;
    const color = Color(0xFFFF7043);

    final barGroups = List.generate(7, (i) {
      final day = _normalizeDate(_weekStart.add(Duration(days: i)));
      final value = stats[day] ?? 0.0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            color: value > 0 ? color : color.withValues(alpha: 0.15),
            width: 26,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: safeMax,
              color: color.withValues(alpha: 0.06),
            ),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: safeMax,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gi, rod, ri) {
              final val = rod.toY;
              if (val == 0) return null;
              return BarTooltipItem(
                '${val.toStringAsFixed(0)}kcal',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[idx],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.withValues(alpha: 0.1),
            strokeWidth: 0.5,
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildNoData() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '이번 주 기록이 없어요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '일지를 기록하면 통계가 표시됩니다',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigator() {
    final isCurrentWeek = !_weekStart
        .add(const Duration(days: 7))
        .isAfter(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _prevWeek,
            icon: const Icon(Icons.chevron_left_rounded),
            color: const Color(0xFF6BBF59),
          ),
          Text(
            _weekLabel(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D2D2D),
            ),
          ),
          IconButton(
            onPressed: isCurrentWeek ? _nextWeek : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: isCurrentWeek
                ? const Color(0xFF6BBF59)
                : Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required int totalLiquidMl,
    required int totalLiquidCount,
    required int totalSleepMin,
    required int totalDiapers,
  }) {
    String sleepLabel;
    if (totalSleepMin >= 60) {
      final h = totalSleepMin ~/ 60;
      final m = totalSleepMin % 60;
      sleepLabel = m > 0 ? '${h}h ${m}m' : '${h}h';
    } else {
      sleepLabel = '$totalSleepMin분';
    }

    String avgSleepLabel;
    final avgSleepMin = totalSleepMin ~/ 7;
    if (avgSleepMin >= 60) {
      final h = avgSleepMin ~/ 60;
      final m = avgSleepMin % 60;
      avgSleepLabel = m > 0 ? '${h}h${m}m' : '${h}h';
    } else {
      avgSleepLabel = '$avgSleepMin분';
    }

    final avgLiquidMl = totalLiquidMl ~/ 7;
    final avgDiapers = (totalDiapers / 7).toStringAsFixed(1);

    return Row(
      children: [
        _buildSummaryCard(
          icon: Icons.local_cafe_rounded,
          color: const Color(0xFF29B6F6),
          label: '수유/음료',
          value: totalLiquidMl > 0 ? '${totalLiquidMl}ml' : '$totalLiquidCount회',
          avg: totalLiquidMl > 0
              ? '$totalLiquidCount회 · 평균 ${avgLiquidMl}ml'
              : '평균 ${(totalLiquidCount / 7).toStringAsFixed(1)}회/일',
        ),
        const SizedBox(width: 10),
        _buildSummaryCard(
          icon: Icons.bedtime_rounded,
          color: const Color(0xFF9575CD),
          label: '총 수면',
          value: sleepLabel,
          avg: '평균 $avgSleepLabel/일',
        ),
        const SizedBox(width: 10),
        _buildSummaryCard(
          icon: Icons.baby_changing_station_rounded,
          color: const Color(0xFFFFB74D),
          label: '기저귀',
          value: '$totalDiapers회',
          avg: '평균 $avgDiapers회/일',
        ),
      ],
    );
  }

  // ====== 기저귀 소변/대변 분리 카드 ======
  Widget _buildDiaperCard({
    required Map<DateTime, int> diaperStats,
    required Map<DateTime, int> peeStats,
    required Map<DateTime, int> poopStats,
    required int totalPee,
    required int totalPoop,
  }) {
    return Container(
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
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.baby_changing_station_rounded,
                    color: Color(0xFFFFB74D), size: 18),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('기저귀',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D2D2D))),
                  Text('일별 교체 횟수',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              // 소변/대변 합계 뱃지
              Row(
                children: [
                  _buildDiaperBadge('💧 소변', totalPee, const Color(0xFF29B6F6)),
                  const SizedBox(width: 6),
                  _buildDiaperBadge('💩 대변', totalPoop, const Color(0xFF8D6E63)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 차트
          SizedBox(
            height: 140,
            child: _buildDiaperComboChart(
              peeStats: peeStats,
              poopStats: poopStats,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaperBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $count회',
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    String? avg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            if (avg != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  avg,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  Text(
                    subtitle,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 160, child: child),
        ],
      ),
    );
  }

  List<String> _dayLabels() {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return List.generate(7, (i) {
      final d = _weekStart.add(Duration(days: i));
      return '${days[i]}\n${d.day}';
    });
  }

  double _calcMaxY(Iterable<int> values, int minMax) {
    final max = values.isEmpty ? minMax : values.reduce((a, b) => a > b ? a : b);
    return (max < minMax ? minMax : max * 1.2).toDouble();
  }

  // ── 수유 콤보 차트: 막대(ml) + 선(횟수) ──
  // 기저귀 소변(파랑)/대변(갈색) 그룹 막대 차트
  Widget _buildDiaperComboChart({
    required Map<DateTime, int> peeStats,
    required Map<DateTime, int> poopStats,
  }) {
    final labels = _dayLabels();
    final allValues = [...peeStats.values, ...poopStats.values];
    final maxY = _calcMaxY(allValues, 5).toDouble();
    const peeColor = Color(0xFF29B6F6);
    const poopColor = Color(0xFF8D6E63);

    final barGroups = List.generate(7, (i) {
      final day = _normalizeDate(_weekStart.add(Duration(days: i)));
      final pee = (peeStats[day] ?? 0).toDouble();
      final poop = (poopStats[day] ?? 0).toDouble();
      return BarChartGroupData(
        x: i,
        barsSpace: 3,
        barRods: [
          BarChartRodData(
            toY: pee,
            color: pee > 0 ? peeColor : peeColor.withValues(alpha: 0.15),
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: poop,
            color: poop > 0 ? poopColor : poopColor.withValues(alpha: 0.15),
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return Column(
      children: [
        // 범례
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendDot(peeColor, '💧 소변'),
            const SizedBox(width: 16),
            _buildLegendDot(poopColor, '💩 대변'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, rodIndex) {
                    final val = rod.toY.toInt();
                    if (val == 0) return null;
                    final label = rodIndex == 0 ? '소변' : '대변';
                    return BarTooltipItem(
                      '$label ${val}회',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(labels[idx],
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade500)),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.grey.shade100,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildLiquidComboChart({
    required Map<DateTime, int> mlStats,
    required Map<DateTime, int> countStats,
  }) {
    final maxY = _calcMaxY(mlStats.values, 500);
    final labels = _dayLabels();
    final maxCount =
        countStats.values.isEmpty ? 1 : countStats.values.reduce((a, b) => a > b ? a : b);
    const barColor = Color(0xFF29B6F6);
    const lineColor = Color(0xFFFF7043);

    // 횟수를 ml 스케일로 변환 (최대 횟수 = 차트 높이의 80%)
    double scaleCount(int count) =>
        maxCount > 0 ? (count / maxCount) * maxY * 0.8 : 0;

    final barGroups = List.generate(7, (i) {
      final day = _normalizeDate(_weekStart.add(Duration(days: i)));
      final value = (mlStats[day] ?? 0).toDouble();
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            color: value > 0 ? barColor : barColor.withValues(alpha: 0.15),
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: barColor.withValues(alpha: 0.06),
            ),
          ),
        ],
      );
    });

    final lineSpots = List.generate(7, (i) {
      final day = _normalizeDate(_weekStart.add(Duration(days: i)));
      return FlSpot(i.toDouble(), scaleCount(countStats[day] ?? 0));
    });

    final actualCounts = List.generate(7, (i) {
      final day = _normalizeDate(_weekStart.add(Duration(days: i)));
      return countStats[day] ?? 0;
    });

    Widget bottomTitle(double value, TitleMeta meta) {
      final idx = value.toInt();
      if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          labels[idx],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            height: 1.4,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // ── 막대: ml ──
        BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, gi, rod, ri) {
                  final val = rod.toY.toInt();
                  if (val == 0) return null;
                  return BarTooltipItem(
                    '${val}ml',
                    const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: bottomTitle,
                ),
              ),
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.grey.withValues(alpha: 0.1),
                strokeWidth: 0.5,
              ),
            ),
            barGroups: barGroups,
          ),
        ),
        // ── 선: 횟수 ──
        LineChart(
          LineChartData(
            minX: -0.5,
            maxX: 6.5,
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: lineSpots,
                isCurved: true,
                color: lineColor,
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2.5,
                    strokeColor: lineColor,
                  ),
                ),
                belowBarData: BarAreaData(show: false),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((s) {
                  final count = actualCounts[s.x.round()];
                  return LineTooltipItem(
                    '$count회',
                    const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
            ),
            titlesData: const FlTitlesData(
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false, reservedSize: 36)),
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart({
    required Map<DateTime, int> stats,
    required Color color,
    required String unit,
    required double maxY,
    bool isCount = false,
  }) {
    final labels = _dayLabels();
    final barGroups = List.generate(7, (i) {
      final day = _normalizeDate(_weekStart.add(Duration(days: i)));
      final value = (stats[day] ?? 0).toDouble();
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            color: value > 0 ? color : color.withValues(alpha: 0.15),
            width: 26,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: color.withValues(alpha: 0.06),
            ),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gi, rod, ri) {
              final val = rod.toY.toInt();
              if (val == 0) return null;
              String valStr;
              if (!isCount && unit == '분' && val >= 60) {
                final h = val ~/ 60;
                final m = val % 60;
                valStr = m > 0 ? '${h}h ${m}m' : '${h}h';
              } else {
                valStr = '$val$unit';
              }
              return BarTooltipItem(
                valStr,
                const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[idx],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.withValues(alpha: 0.1),
            strokeWidth: 0.5,
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildTempLineChart(Map<DateTime, double> stats) {
    final labels = _dayLabels();
    final spots = <FlSpot>[];
    for (int i = 0; i < 7; i++) {
      final day = _normalizeDate(_weekStart.add(Duration(days: i)));
      if (stats.containsKey(day)) {
        spots.add(FlSpot(i.toDouble(), stats[day]!));
      }
    }

    if (spots.isEmpty) return const SizedBox.shrink();

    final temps = stats.values;
    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final yMin = (minTemp - 0.5).clamp(35.0, 40.0);
    final yMax = (maxTemp + 0.5).clamp(36.0, 42.0);

    return LineChart(
      LineChartData(
        minY: yMin,
        maxY: yMax,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFF06292),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 4,
                color: const Color(0xFFF06292),
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFF06292).withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
              return LineTooltipItem(
                '${s.y.toStringAsFixed(1)}°C',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[idx],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style:
                    TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.withValues(alpha: 0.1),
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        // 37.5°C 이상 경고선
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 37.5,
              color: const Color(0xFFEF5350).withValues(alpha: 0.5),
              strokeWidth: 1.5,
              dashArray: [5, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => '37.5°',
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFFEF5350),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
