import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/food_diary_entry.dart';
import '../providers/diary_provider.dart';
import '../providers/auth_provider.dart';

class WeeklyStatsScreen extends StatefulWidget {
  const WeeklyStatsScreen({super.key});

  @override
  State<WeeklyStatsScreen> createState() => _WeeklyStatsScreenState();
}

class _WeeklyStatsScreenState extends State<WeeklyStatsScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _weekStart;
  late TabController _tabController;
  OverlayEntry? _activeTimelineOverlay;
  String? _highlightedEntryId;
  bool _isVerticalTimeline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _weekStart = _getWeekStart(now);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _activeTimelineOverlay?.remove();
    _tabController.dispose();
    super.dispose();
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
    final sleepSplitStats = diary.getWeeklySleepSplitStats(_weekStart);
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
    final hasAnyData = hasNutrition ||
        liquidStats.values.any((v) => v > 0) ||
        sleepStats.values.any((v) => v > 0) ||
        diaperStats.values.any((v) => v > 0) ||
        tempStats.isNotEmpty ||
        activityStats.values.any((v) => v > 0) ||
        feedingDurationStats.values.any((v) => v > 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF6),
      appBar: AppBar(
        title: const Text('주간 통계'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2D2D2D),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6BBF59),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6BBF59),
          indicatorWeight: 2.5,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded, size: 16), text: '통계'),
            Tab(icon: Icon(Icons.view_timeline_rounded, size: 16), text: '타임라인'),
          ],
        ),
      ),
      body: diary.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 주차 네비게이터 (두 탭 공유)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _buildWeekNavigator(),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // ── Tab 0: 통계 ──
                      ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          _buildSummaryRow(
                            totalLiquidMl: totalLiquidMl,
                            totalLiquidCount: totalLiquidCount,
                            totalSleepMin: totalSleepMin,
                            totalDiapers: totalDiapers,
                          ),
                          const SizedBox(height: 20),
                          if (hasNutrition) ...[
                            _buildNutritionCard(diary),
                            const SizedBox(height: 16),
                          ],
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
                          if (sleepStats.values.any((v) => v > 0)) ...[
                            _buildSleepCard(sleepSplitStats),
                            const SizedBox(height: 16),
                          ],
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
                          if (!hasAnyData) _buildNoData(),
                        ],
                      ),
                      // ── Tab 1: 타임라인 ──
                      _buildTimelineView(diary),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ====== 타임라인 탭 ======

  Widget _buildTimelineView(DiaryProvider diary) {
    final allEntries = List.generate(7, (i) {
      final day = _normalizeDate(_weekStart.add(Duration(days: i)));
      return diary.getEntriesForDate(day);
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Container(
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 + 가로/세로 토글
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF26A69A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.view_timeline_rounded,
                        color: Color(0xFF26A69A), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('일별 타임라인',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D2D2D))),
                        Text(
                          _isVerticalTimeline ? '0시 ~ 24시 수직 뷰' : '0시 ~ 24시 가로 뷰',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  _buildViewToggle(),
                ],
              ),
              const SizedBox(height: 14),
              _buildTimelineLegend(),
              const SizedBox(height: 14),
              // 가로/세로 전환 (AnimatedSwitcher)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: _isVerticalTimeline
                    ? _buildVerticalContent(allEntries)
                    : _buildHorizontalContent(allEntries),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 가로/세로 토글 버튼 ──
  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleBtn(
            Icons.view_timeline_rounded,
            '가로',
            !_isVerticalTimeline,
            () => setState(() => _isVerticalTimeline = false),
          ),
          _buildToggleBtn(
            Icons.calendar_view_week_rounded,
            '세로',
            _isVerticalTimeline,
            () => setState(() => _isVerticalTimeline = true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(
      IconData icon, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: selected ? const Color(0xFF26A69A) : Colors.grey),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color:
                    selected ? const Color(0xFF26A69A) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 가로 타임라인 컨텐츠 ──
  Widget _buildHorizontalContent(List<List<FoodDiaryEntry>> allEntries) {
    return Column(
      key: const ValueKey('horizontal'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeAxisHeader(),
        const SizedBox(height: 6),
        ...List.generate(7, (i) {
          final day = _normalizeDate(_weekStart.add(Duration(days: i)));
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildDayTimelineRow(day, allEntries[i], i),
          );
        }),
      ],
    );
  }

  // ── 세로 타임라인 컨텐츠 ──
  Widget _buildVerticalContent(List<List<FoodDiaryEntry>> allEntries) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final today = _normalizeDate(DateTime.now());

    return Column(
      key: const ValueKey('vertical'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 요일 헤더
        Row(
          children: [
            const SizedBox(width: _VerticalTimelinePainter.kLabelW),
            ...List.generate(7, (i) {
              final day = _normalizeDate(_weekStart.add(Duration(days: i)));
              final isToday = day == today;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      days[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isToday ? FontWeight.w800 : FontWeight.w600,
                        color: isToday
                            ? const Color(0xFF6BBF59)
                            : const Color(0xFF2D2D2D),
                      ),
                    ),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                          fontSize: 9, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 6),
        // 세로 그리드
        LayoutBuilder(
          builder: (ctx, constraints) {
            final gridWidth =
                constraints.maxWidth - _VerticalTimelinePainter.kLabelW;
            const totalH = 24 * _VerticalTimelinePainter.kHourH;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final tapX = details.localPosition.dx -
                    _VerticalTimelinePainter.kLabelW;
                final tapY = details.localPosition.dy;
                if (tapX < 0) return;
                final hit =
                    _hitTestVertical(allEntries, tapX, tapY, gridWidth);
                if (hit != null) {
                  _showTimelinePopup(ctx, hit, details.globalPosition);
                }
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _VerticalTimelinePainter.kLabelW,
                    height: totalH,
                    child: CustomPaint(
                      painter: _VerticalTimeLabelPainter(),
                      size: Size(_VerticalTimelinePainter.kLabelW, totalH),
                    ),
                  ),
                  SizedBox(
                    width: gridWidth,
                    height: totalH,
                    child: CustomPaint(
                      painter: _VerticalTimelinePainter(
                        allEntries: allEntries,
                        highlightedId: _highlightedEntryId,
                      ),
                      size: Size(gridWidth, totalH),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelineLegend() {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        _buildLegendChip(const Color(0xFF3949AB), '밤수면', isBar: true),
        _buildLegendChip(const Color(0xFF81D4FA), '낮잠', isBar: true),
        _buildLegendChip(const Color(0xFFF48FB1), '모유'),
        _buildLegendChip(const Color(0xFF29B6F6), '분유/수유'),
        _buildLegendChip(const Color(0xFF4FC3F7), '소변'),
        _buildLegendChip(const Color(0xFF8D6E63), '대변'),
      ],
    );
  }

  Widget _buildLegendChip(Color color, String label, {bool isBar = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBar)
          Container(
            width: 14,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          )
        else
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildTimeAxisHeader() {
    return Row(
      children: [
        const SizedBox(width: 44),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              const labels = ['0시', '6시', '12시', '18시', '24시'];
              return SizedBox(
                height: 14,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: List.generate(labels.length, (i) {
                    final frac = i / 4;
                    // 왼쪽 끝은 left-align, 오른쪽 끝은 right-align
                    double left = frac * w;
                    if (i == labels.length - 1) {
                      left = w - 18;
                    } else if (i > 0) {
                      left = left - 8;
                    }
                    return Positioned(
                      left: left,
                      top: 0,
                      child: Text(
                        labels[i],
                        style: TextStyle(
                            fontSize: 9, color: Colors.grey.shade400),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayTimelineRow(
      DateTime day, List<FoodDiaryEntry> entries, int dayIndex) {
    const dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final isToday = day == _normalizeDate(DateTime.now());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 36,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayNames[dayIndex],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isToday
                      ? const Color(0xFF6BBF59)
                      : const Color(0xFF2D2D2D),
                ),
              ),
              Text(
                '${day.day}',
                style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final timelineWidth = constraints.maxWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final hit = _hitTestTimeline(
                    entries,
                    details.localPosition.dx,
                    details.localPosition.dy,
                    timelineWidth,
                  );
                  if (hit != null) {
                    _showTimelinePopup(ctx, hit, details.globalPosition);
                  }
                },
                child: SizedBox(
                  height: 44,
                  child: CustomPaint(
                    painter: _DayTimelinePainter(
                      entries: entries,
                      highlightedId: _highlightedEntryId,
                    ),
                    size: const Size(double.infinity, 44),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 타임라인 터치 히트테스트 ──
  FoodDiaryEntry? _hitTestTimeline(
    List<FoodDiaryEntry> entries,
    double tapX,
    double tapY,
    double width,
  ) {
    double minDist = double.infinity;
    FoodDiaryEntry? closest;
    const maxDist = 24.0;

    double toX(int mins) => (mins / (24 * 60) * width).clamp(0.0, width);

    for (final e in entries) {
      double dist;

      if (e.entryType == EntryType.sleep && (e.durationMinutes ?? 0) > 0) {
        final s = e.mealTime.hour * 60 + e.mealTime.minute;
        final en = (s + e.durationMinutes!).clamp(0, 24 * 60);
        final x1 = toX(s);
        final x2 = toX(en);
        if (tapX < x1 - 4 || tapX > x2 + 4) continue;
        dist = (tapY - (_DayTimelinePainter.kSleepTop + _DayTimelinePainter.kSleepH / 2)).abs();
      } else if (e.entryType.isLiquidEntry) {
        final ex = toX(e.mealTime.hour * 60 + e.mealTime.minute);
        dist = (tapX - ex).abs() + (tapY - _DayTimelinePainter.kFeedY).abs();
      } else if (e.entryType == EntryType.diaper) {
        final ex = toX(e.mealTime.hour * 60 + e.mealTime.minute);
        dist = (tapX - ex).abs() + (tapY - _DayTimelinePainter.kDiaperY).abs();
      } else {
        continue;
      }

      if (dist < minDist && dist <= maxDist) {
        minDist = dist;
        closest = e;
      }
    }
    return closest;
  }

  // ── 팝업 표시 ──
  void _showTimelinePopup(
    BuildContext context,
    FoodDiaryEntry entry,
    Offset globalPos,
  ) {
    _activeTimelineOverlay?.remove();
    setState(() => _highlightedEntryId = entry.id);

    late OverlayEntry overlay;
    overlay = OverlayEntry(
      builder: (_) {
        final screenW = MediaQuery.of(context).size.width;
        final screenH = MediaQuery.of(context).size.height;
        const cardW = 210.0;

        // 팝업 위치 계산 (터치 위 기본, 공간 부족 시 아래)
        double left = (globalPos.dx - cardW / 2).clamp(12.0, screenW - cardW - 12);
        double top = globalPos.dy - 140;
        if (top < 60) top = globalPos.dy + 16;
        top = top.clamp(60.0, screenH - 200);

        return Stack(
          children: [
            // 배경 터치 → 닫기
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  overlay.remove();
                  _activeTimelineOverlay = null;
                  setState(() => _highlightedEntryId = null);
                },
              ),
            ),
            // 팝업 카드
            Positioned(
              left: left,
              top: top,
              width: cardW,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _buildPopupContent(entry),
                ),
              ),
            ),
          ],
        );
      },
    );

    _activeTimelineOverlay = overlay;
    Overlay.of(context).insert(overlay);
  }

  // ── 팝업 내용 ──
  Widget _buildPopupContent(FoodDiaryEntry entry) {
    final timeStr = DateFormat('a h:mm', 'ko').format(entry.mealTime);
    String emoji;
    String title;
    Color accentColor;
    final rows = <Widget>[];

    switch (entry.entryType) {
      case EntryType.sleep:
        final isNight =
            entry.mealTime.hour >= 20 || entry.mealTime.hour < 7;
        emoji = isNight ? '🌙' : '☀️';
        title = isNight ? '밤수면' : '낮잠';
        accentColor = isNight
            ? const Color(0xFF3949AB)
            : const Color(0xFF29B6F6);
        rows.add(_popupRow(Icons.access_time_rounded, '시작', timeStr));
        if ((entry.durationMinutes ?? 0) > 0) {
          rows.add(_popupRow(Icons.timer_rounded, '시간',
              _fmtDur(entry.durationMinutes!)));
        }
        break;

      case EntryType.diaper:
        final dt = entry.diaperType;
        emoji = dt == DiaperType.soiled ? '💩' : '💧';
        title = dt == DiaperType.wet
            ? '소변'
            : dt == DiaperType.soiled
                ? '대변'
                : dt == DiaperType.both
                    ? '소변+대변'
                    : '기저귀';
        accentColor = dt == DiaperType.soiled
            ? const Color(0xFF8D6E63)
            : const Color(0xFF4FC3F7);
        rows.add(_popupRow(Icons.access_time_rounded, '시각', timeStr));
        break;

      default:
        emoji = entry.entryType == EntryType.breastMilk ? '🤱' : '🍼';
        title = entry.entryType.displayName;
        accentColor = entry.entryType.color;
        rows.add(_popupRow(Icons.access_time_rounded, '시각', timeStr));
        if ((entry.milkAmountMl ?? 0) > 0) {
          rows.add(_popupRow(
              Icons.water_drop_rounded, '양', '${entry.milkAmountMl}ml'));
        }
        if ((entry.durationMinutes ?? 0) > 0) {
          rows.add(_popupRow(Icons.timer_rounded, '수유 시간',
              _fmtDur(entry.durationMinutes!)));
        }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji,
                style: const TextStyle(fontSize: 20, height: 1.2)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: Colors.grey.shade100),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }

  Widget _popupRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade400),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade500)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D))),
        ],
      ),
    );
  }

  String _fmtDur(int minutes) {
    if (minutes < 60) return '$minutes분';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '$h시간 $m분' : '$h시간';
  }

  // ====== 이번 주 영양 섭취 카드 ======
  Widget _buildNutritionCard(DiaryProvider diary) {
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
    final maxCal =
        caloriesStats.values.fold(0.0, (a, b) => a > b ? a : b);

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
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: _buildCaloriesBarChart(caloriesStats, maxCal),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildNutrientChip('총 칼로리',
                  '${totalCal.toStringAsFixed(0)} kcal', const Color(0xFFFF7043)),
              const SizedBox(width: 8),
              _buildNutrientChip('일 평균',
                  '${avgCal.toStringAsFixed(0)} kcal', const Color(0xFFFFA726)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildNutrientChip('단백질',
                  '${totalProtein.toStringAsFixed(1)}g', const Color(0xFF42A5F5)),
              const SizedBox(width: 8),
              _buildNutrientChip('탄수화물',
                  '${totalCarbs.toStringAsFixed(1)}g', const Color(0xFF66BB6A)),
              const SizedBox(width: 8),
              _buildNutrientChip('지방',
                  '${totalFat.toStringAsFixed(1)}g', const Color(0xFF7E57C2)),
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
                style: TextStyle(
                    fontSize: 10, color: Colors.grey.shade500)),
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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
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
    );
  }

  Widget _buildNoData() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 64, color: Colors.grey.shade300),
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
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigator() {
    final isCurrentWeek =
        !_weekStart.add(const Duration(days: 7)).isAfter(DateTime.now());

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
          value: totalLiquidMl > 0
              ? '${totalLiquidMl}ml'
              : '$totalLiquidCount회',
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
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _buildDiaperBadge(
                      '💧 소변', totalPee, const Color(0xFF29B6F6)),
                  const SizedBox(width: 6),
                  _buildDiaperBadge(
                      '💩 대변', totalPoop, const Color(0xFF8D6E63)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 2),
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

  // ── 수면 카드 (낮잠/밤수면 스택 바) ──
  Widget _buildSleepCard(
      Map<DateTime, ({int nap, int night})> splitStats) {
    const nightColor = Color(0xFF283593);
    const napColor = Color(0xFF81D4FA);

    final allTotals = splitStats.values.map((v) => v.nap + v.night);
    final maxY = _calcMaxY(allTotals, 60);
    final labels = _dayLabels();

    String fmt(int m) {
      if (m == 0) return '';
      final h = m ~/ 60;
      final min = m % 60;
      return h > 0 ? (min > 0 ? '${h}h ${min}m' : '${h}h') : '${min}m';
    }

    final barGroups = List.generate(7, (i) {
      final day = _normalizeDate(_weekStart.add(Duration(days: i)));
      final s = splitStats[day] ?? (nap: 0, night: 0);
      final total = (s.nap + s.night).toDouble();
      final nightD = s.night.toDouble();

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: total > 0 ? total : 0,
            color: Colors.transparent,
            width: 26,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: nightColor.withValues(alpha: 0.06),
            ),
            rodStackItems: total > 0
                ? [
                    BarChartRodStackItem(0, nightD, nightColor),
                    BarChartRodStackItem(nightD, total, napColor),
                  ]
                : [],
          ),
        ],
      );
    });

    final chart = BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gi, rod, ri) {
              final day =
                  _normalizeDate(_weekStart.add(Duration(days: gi)));
              final s = splitStats[day] ?? (nap: 0, night: 0);
              if (s.nap + s.night == 0) return null;
              final lines = <String>[];
              if (s.night > 0) lines.add('🌙 밤 ${fmt(s.night)}');
              if (s.nap > 0) lines.add('☀️ 낮 ${fmt(s.nap)}');
              return BarTooltipItem(
                lines.join('\n'),
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
    );

    return _buildChartCard(
      title: '수면',
      subtitle: '낮잠 (07-20시)  ·  밤수면 (20-07시)',
      icon: Icons.bedtime_rounded,
      color: nightColor,
      child: Column(
        children: [
          SizedBox(height: 160, child: chart),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(nightColor, '밤수면'),
              const SizedBox(width: 20),
              _buildLegendDot(napColor, '낮잠'),
            ],
          ),
        ],
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
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
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
    final max =
        values.isEmpty ? minMax : values.reduce((a, b) => a > b ? a : b);
    return (max < minMax ? minMax : max * 1.2).toDouble();
  }

  // ── 기저귀 소변(파랑)/대변(갈색) 그룹 막대 차트 ──
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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: poop,
            color:
                poop > 0 ? poopColor : poopColor.withValues(alpha: 0.15),
            width: 14,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return Column(
      children: [
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
                      '$label $val회',
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
                                fontSize: 10,
                                color: Colors.grey.shade500)),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval:
                    maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
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
    final maxCount = countStats.values.isEmpty
        ? 1
        : countStats.values.reduce((a, b) => a > b ? a : b);
    const barColor = Color(0xFF29B6F6);
    const lineColor = Color(0xFFFF7043);

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
            color:
                value > 0 ? barColor : barColor.withValues(alpha: 0.15),
            width: 24,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
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
                  getDotPainter: (spot, pct, bar, idx) =>
                      FlDotCirclePainter(
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
                  sideTitles:
                      SideTitles(showTitles: false, reservedSize: 36)),
              leftTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
            color:
                value > 0 ? color : color.withValues(alpha: 0.15),
            width: 26,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
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
                style: TextStyle(
                    fontSize: 9, color: Colors.grey.shade500),
              ),
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
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

  // 세로 타임라인 히트테스트
  FoodDiaryEntry? _hitTestVertical(
    List<List<FoodDiaryEntry>> allEntries,
    double tapX,
    double tapY,
    double gridWidth,
  ) {
    const kHourH = _VerticalTimelinePainter.kHourH;
    final colW = gridWidth / 7;
    final dayIdx = (tapX / colW).floor().clamp(0, 6);
    final tapMins = (tapY / kHourH * 60).round();

    double minDist = double.infinity;
    FoodDiaryEntry? closest;
    const maxDist = 20.0; // 픽셀 기준 임계값

    for (final e in allEntries[dayIdx]) {
      double dist;
      final startMins = e.mealTime.hour * 60 + e.mealTime.minute;

      if (e.entryType == EntryType.sleep && (e.durationMinutes ?? 0) > 0) {
        final endMins = (startMins + e.durationMinutes!).clamp(0, 24 * 60);
        if (tapMins < startMins - 15 || tapMins > endMins + 15) continue;
        final centerMins = (startMins + endMins) / 2;
        dist = (tapMins - centerMins).abs() * kHourH / 60;
      } else if (e.entryType.isLiquidEntry || e.entryType == EntryType.diaper) {
        dist = (tapMins - startMins).abs() * kHourH / 60;
      } else {
        continue;
      }

      if (dist < minDist && dist <= maxDist) {
        minDist = dist;
        closest = e;
      }
    }
    return closest;
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

// ══════════════════════════════════════════════════
// 일별 타임라인 CustomPainter
// ══════════════════════════════════════════════════

class _DayTimelinePainter extends CustomPainter {
  final List<FoodDiaryEntry> entries;
  final String? highlightedId;

  // 레이아웃 상수 (캔버스 높이 44px 기준) — 히트테스트에서도 참조
  static const kFeedY = 8.0;
  static const kSleepTop = 17.0;
  static const kSleepH = 12.0;
  static const kDiaperY = 36.0;
  static const _dotR = 4.5;

  const _DayTimelinePainter({required this.entries, this.highlightedId});

  double _toX(int totalMinutes, double width) =>
      (totalMinutes / (24 * 60) * width).clamp(0.0, width);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 배경
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)),
      Paint()..color = const Color(0xFFEEF2FA),
    );

    // 시간 구분선
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 1;
    for (int hr = 0; hr <= 24; hr += 6) {
      canvas.drawLine(Offset(hr / 24 * w, 0), Offset(hr / 24 * w, h), gridPaint);
    }

    // ── 수면 바 ──
    for (final e in entries) {
      if (e.entryType != EntryType.sleep || (e.durationMinutes ?? 0) <= 0) continue;
      final startMins = e.mealTime.hour * 60 + e.mealTime.minute;
      final endMins = (startMins + e.durationMinutes!).clamp(0, 24 * 60);
      if (startMins >= endMins) continue;

      final x1 = _toX(startMins, w);
      final x2 = _toX(endMins, w);
      final barW = (x2 - x1).clamp(2.0, w);
      final isHL = e.id == highlightedId;

      final startH = e.mealTime.hour;
      final baseColor = (startH >= 7 && startH < 20)
          ? const Color(0xFF81D4FA)
          : const Color(0xFF3949AB);

      if (isHL) {
        // 하이라이트: 글로우 + 확장
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x1 - 2, kSleepTop - 3, barW + 4, kSleepH + 6),
            const Radius.circular(6),
          ),
          Paint()..color = baseColor.withValues(alpha: 0.28),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x1, kSleepTop, barW, kSleepH),
          const Radius.circular(4),
        ),
        Paint()..color = isHL ? baseColor : baseColor,
      );
      if (isHL) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x1, kSleepTop, barW, kSleepH),
            const Radius.circular(4),
          ),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // ── 수유/음료 점 (상단) ──
    for (final e in entries) {
      if (!e.entryType.isLiquidEntry) continue;
      final mins = e.mealTime.hour * 60 + e.mealTime.minute;
      final x = _toX(mins, w);
      final isHL = e.id == highlightedId;
      final r = isHL ? _dotR + 2.5 : _dotR;
      if (isHL) {
        canvas.drawCircle(Offset(x, kFeedY), r + 4,
            Paint()..color = e.entryType.color.withValues(alpha: 0.25));
      }
      canvas.drawCircle(Offset(x, kFeedY), r, Paint()..color = e.entryType.color);
      canvas.drawCircle(Offset(x, kFeedY), r,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = isHL ? 2.0 : 1.5);
    }

    // ── 기저귀 점 (하단) ──
    for (final e in entries) {
      if (e.entryType != EntryType.diaper) continue;
      final mins = e.mealTime.hour * 60 + e.mealTime.minute;
      final x = _toX(mins, w);
      final isHL = e.id == highlightedId;
      final r = isHL ? _dotR + 1.5 : _dotR - 0.5;
      final color = switch (e.diaperType) {
        DiaperType.wet => const Color(0xFF4FC3F7),
        DiaperType.soiled => const Color(0xFF8D6E63),
        DiaperType.both => const Color(0xFFFF8F00),
        _ => const Color(0xFFBDBDBD),
      };
      if (isHL) {
        canvas.drawCircle(Offset(x, kDiaperY), r + 4,
            Paint()..color = color.withValues(alpha: 0.25));
      }
      canvas.drawCircle(Offset(x, kDiaperY), r, Paint()..color = color);
      canvas.drawCircle(Offset(x, kDiaperY), r, strokePaint);
    }
  }

  @override
  bool shouldRepaint(_DayTimelinePainter old) =>
      old.entries != entries || old.highlightedId != highlightedId;
}

// ══════════════════════════════════════════════════
// 세로 타임라인 Painters
// ══════════════════════════════════════════════════

/// 세로 타임라인 시간 라벨 (좌측 컬럼)
class _VerticalTimeLabelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const kHourH = _VerticalTimelinePainter.kHourH;
    for (int hr = 0; hr <= 24; hr += 3) {
      final y = hr * kHourH;
      final tp = TextPainter(
        text: TextSpan(
          text: '$hr시',
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade400,
            height: 1.2,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_VerticalTimeLabelPainter old) => false;
}

/// 세로 타임라인 7일 그리드
class _VerticalTimelinePainter extends CustomPainter {
  final List<List<FoodDiaryEntry>> allEntries;
  final String? highlightedId;

  static const kHourH = 28.0;  // px per hour
  static const kLabelW = 30.0; // 시간 라벨 컬럼 너비

  const _VerticalTimelinePainter({
    required this.allEntries,
    this.highlightedId,
  });

  double _minsToY(int totalMins) =>
      (totalMins / 60 * kHourH).clamp(0.0, 24 * kHourH);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final colW = w / 7;

    // 배경
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFF7F9FF),
    );

    // 시간 그리드 (수평선)
    for (int hr = 0; hr <= 24; hr++) {
      final y = hr * kHourH;
      final isMain = hr % 3 == 0;
      canvas.drawLine(
        Offset(0, y),
        Offset(w, y),
        Paint()
          ..color = isMain
              ? Colors.grey.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.08)
          ..strokeWidth = isMain ? 0.8 : 0.5,
      );
    }

    // 요일 구분선 (수직선)
    for (int d = 1; d < 7; d++) {
      canvas.drawLine(
        Offset(d * colW, 0),
        Offset(d * colW, h),
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.15)
          ..strokeWidth = 0.5,
      );
    }

    // 각 요일 이벤트 렌더링
    for (int dayIdx = 0; dayIdx < 7; dayIdx++) {
      final colX = dayIdx * colW;
      final entries = allEntries[dayIdx];

      // ── 수면 바 (중앙 60%) ──
      for (final e in entries) {
        if (e.entryType != EntryType.sleep || (e.durationMinutes ?? 0) <= 0) {
          continue;
        }
        final startMins = e.mealTime.hour * 60 + e.mealTime.minute;
        final endMins = (startMins + e.durationMinutes!).clamp(0, 24 * 60);
        if (startMins >= endMins) continue;

        final y1 = _minsToY(startMins);
        final y2 = _minsToY(endMins);
        final barH = (y2 - y1).clamp(2.0, h);
        final isHL = e.id == highlightedId;

        final startH = e.mealTime.hour;
        final baseColor = (startH >= 7 && startH < 20)
            ? const Color(0xFF81D4FA)
            : const Color(0xFF3949AB);

        final barX = colX + colW * 0.2;
        final barW2 = colW * 0.6;

        if (isHL) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(barX - 3, y1 - 2, barW2 + 6, barH + 4),
              const Radius.circular(5),
            ),
            Paint()..color = baseColor.withValues(alpha: 0.25),
          );
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, y1, barW2, barH),
            const Radius.circular(4),
          ),
          Paint()..color = baseColor,
        );
        if (isHL) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(barX, y1, barW2, barH),
              const Radius.circular(4),
            ),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }

      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // ── 수유 점 (왼쪽) ──
      for (final e in entries) {
        if (!e.entryType.isLiquidEntry) continue;
        final mins = e.mealTime.hour * 60 + e.mealTime.minute;
        final y = _minsToY(mins);
        final x = colX + colW * 0.28;
        final isHL = e.id == highlightedId;
        final r = isHL ? 5.5 : 4.0;

        if (isHL) {
          canvas.drawCircle(Offset(x, y), r + 4,
              Paint()..color = e.entryType.color.withValues(alpha: 0.25));
        }
        canvas.drawCircle(Offset(x, y), r, Paint()..color = e.entryType.color);
        canvas.drawCircle(Offset(x, y), r,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = isHL ? 2.0 : 1.5);
      }

      // ── 기저귀 점 (오른쪽) ──
      for (final e in entries) {
        if (e.entryType != EntryType.diaper) continue;
        final mins = e.mealTime.hour * 60 + e.mealTime.minute;
        final y = _minsToY(mins);
        final x = colX + colW * 0.72;
        final isHL = e.id == highlightedId;
        final r = isHL ? 5.0 : 3.5;
        final color = switch (e.diaperType) {
          DiaperType.wet => const Color(0xFF4FC3F7),
          DiaperType.soiled => const Color(0xFF8D6E63),
          DiaperType.both => const Color(0xFFFF8F00),
          _ => const Color(0xFFBDBDBD),
        };

        if (isHL) {
          canvas.drawCircle(
              Offset(x, y), r + 4, Paint()..color = color.withValues(alpha: 0.25));
        }
        canvas.drawCircle(Offset(x, y), r, Paint()..color = color);
        canvas.drawCircle(Offset(x, y), r, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_VerticalTimelinePainter old) =>
      old.allEntries != allEntries || old.highlightedId != highlightedId;
}
