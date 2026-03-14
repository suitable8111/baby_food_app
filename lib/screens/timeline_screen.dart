import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/food_diary_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/diary_provider.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  bool _isLoading = true;
  List<FoodDiaryEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final diary = context.read<DiaryProvider>();
    if (auth.userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // 오늘 + 어제 두 날 로드 (24시간이 날짜 경계에 걸칠 수 있음)
    await diary.loadEntries(auth.familyId, today);
    final todayEntries = diary.getEntriesForDate(today);

    await diary.loadEntries(auth.familyId, yesterday);
    final yesterdayEntries = diary.getEntriesForDate(yesterday);

    // 오늘 데이터도 다시 복원 (loadEntries가 clear 하므로)
    await diary.loadEntries(auth.familyId, today);

    final cutoff = now.subtract(const Duration(hours: 24));
    final all = [...todayEntries, ...yesterdayEntries]
        .where((e) => e.mealTime.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.mealTime.compareTo(a.mealTime)); // 최신순

    if (mounted) {
      setState(() {
        _entries = all;
        _isLoading = false;
      });
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '어제';
  }

  String _formatTime(DateTime dt) =>
      DateFormat('a h:mm', 'ko').format(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF6),
      appBar: AppBar(
        title: const Text('타임라인'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmpty()
              : _buildTimeline(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timeline_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '최근 24시간 기록이 없어요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '이유식/아이 기록 화면에서 기록을 추가해보세요',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // 헤더 요약
        _buildSummaryChips(),
        const SizedBox(height: 20),
        // 타임라인 아이템
        for (int i = 0; i < _entries.length; i++)
          _buildTimelineItem(_entries[i], isLast: i == _entries.length - 1),
      ],
    );
  }

  Widget _buildSummaryChips() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));

    // 카테고리별 집계
    final feeding = _entries.where((e) => e.entryType.isLiquidEntry).length;
    final diaper = _entries.where((e) => e.entryType == EntryType.diaper).length;
    final sleep = _entries.where((e) => e.entryType == EntryType.sleep).length;
    final activity = _entries
        .where((e) =>
            e.entryType == EntryType.play ||
            e.entryType == EntryType.tummyTime)
        .length;

    final chips = <(String, Color, bool)>[
      ('🍼 수유 $feeding회', const Color(0xFF29B6F6), feeding > 0),
      ('🚼 기저귀 $diaper회', const Color(0xFFFFB74D), diaper > 0),
      if (sleep > 0) ('💤 수면 $sleep회', const Color(0xFF9575CD), true),
      if (activity > 0) ('🎮 활동 $activity회', const Color(0xFF66BB6A), true),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 16, color: Color(0xFF6BBF59)),
              const SizedBox(width: 6),
              Text(
                '최근 24시간 · ${_entries.length}건',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const Spacer(),
              Text(
                '${DateFormat('M/d HH:mm').format(cutoff)} ~ 지금',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: chips.map((c) {
                final (label, color, active) = c;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: active ? 0.12 : 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? color : Colors.grey.shade400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(FoodDiaryEntry entry, {required bool isLast}) {
    final color = entry.entryType.color;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 왼쪽: 시간 + 점 + 선
          SizedBox(
            width: 70,
            child: Column(
              children: [
                Text(
                  _formatTime(entry.mealTime),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 4),
                Text(
                  _relativeTime(entry.mealTime),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 가운데: 점 + 연결선
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // 오른쪽: 카드
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 아이콘
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(entry.entryType.icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    // 내용
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _entryTitle(entry),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          if (_entrySubtitle(entry).isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _entrySubtitle(entry),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // 작성자 (가족 연동 시)
                    if (entry.authorName != null &&
                        entry.authorName!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6BBF59).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.authorName!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6BBF59),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _entryTitle(FoodDiaryEntry entry) {
    switch (entry.entryType) {
      case EntryType.breastMilk:
      case EntryType.formulaMilk:
      case EntryType.pumpedMilk:
      case EntryType.cowMilk:
      case EntryType.water:
        if (entry.milkAmountMl != null && entry.milkAmountMl! > 0) {
          return '${entry.entryType.displayName} ${entry.milkAmountMl}ml';
        }
        return entry.entryType.displayName;
      case EntryType.diaper:
        return '기저귀 (${entry.diaperType?.displayName ?? ''})';
      case EntryType.sleep:
        if (entry.durationMinutes != null) {
          return '수면 ${entry.durationMinutes}분';
        }
        return '수면';
      case EntryType.play:
      case EntryType.tummyTime:
        if (entry.durationMinutes != null) {
          return '${entry.entryType.displayName} ${entry.durationMinutes}분';
        }
        return entry.entryType.displayName;
      case EntryType.temperature:
        if (entry.temperatureCelsius != null) {
          return '체온 ${entry.temperatureCelsius!.toStringAsFixed(1)}°C';
        }
        return '체온 측정';
      default:
        return entry.recipeName.isNotEmpty
            ? entry.recipeName
            : entry.entryType.displayName;
    }
  }

  String _entrySubtitle(FoodDiaryEntry entry) {
    final parts = <String>[];
    if (entry.memo != null && entry.memo!.isNotEmpty) {
      parts.add(entry.memo!);
    }
    return parts.join(' · ');
  }
}
