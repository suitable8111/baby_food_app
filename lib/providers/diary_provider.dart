import 'dart:async';
import 'package:flutter/material.dart';
import '../models/food_diary_entry.dart';
import '../models/nutrition.dart';
import '../services/firebase_service.dart';
import '../services/widget_service.dart';

class DiaryProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;

  DiaryProvider(this._firebaseService);

  // 상태
  final Map<DateTime, List<FoodDiaryEntry>> _entries = {};
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  StreamSubscription<List<FoodDiaryEntry>>? _todayStream;

  // Getters
  Map<DateTime, List<FoodDiaryEntry>> get entries => _entries;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;

  /// 날짜 키 정규화 (시간 제거)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 선택 날짜 변경
  void setSelectedDate(DateTime date) {
    _selectedDate = _normalizeDate(date);
    notifyListeners();
  }

  /// 해당 월 데이터 로드 (familyId 기준)
  Future<void> loadEntries(String familyId, DateTime month) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1일 전부터 로드: 전달 말일의 자정 넘기는 수면 항목 캡처
      final start = DateTime(month.year, month.month, 1).subtract(const Duration(days: 1));
      final end = DateTime(month.year, month.month + 1, 1);

      final list = await _firebaseService.getDiaryEntries(familyId, start, end);

      // 임시 맵에 먼저 조립한 뒤 한 번에 교체 (스트림과 race condition 방지)
      final tempMap = <DateTime, List<FoodDiaryEntry>>{};
      for (final entry in list) {
        final key = _normalizeDate(entry.date);
        tempMap.putIfAbsent(key, () => []).add(entry);
      }
      _entries.clear();
      _entries.addAll(tempMap);
    } catch (e) {
      debugPrint('일지 로드 실패: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 주간 데이터 로드 (월 경계 처리)
  Future<void> loadWeeklyEntries(String familyId, DateTime weekStart) async {
    _isLoading = true;
    notifyListeners();

    try {
      final weekEnd = weekStart.add(const Duration(days: 6));
      final tempMap = <DateTime, List<FoodDiaryEntry>>{};

      // 시작 월 로드
      final startMonthStart = DateTime(weekStart.year, weekStart.month, 1);
      final startMonthEnd = DateTime(weekStart.year, weekStart.month + 1, 1);
      final list1 = await _firebaseService.getDiaryEntries(
          familyId, startMonthStart, startMonthEnd);
      for (final entry in list1) {
        final key = _normalizeDate(entry.date);
        tempMap.putIfAbsent(key, () => []).add(entry);
      }

      // 주가 월 경계에 걸치면 끝 월도 로드
      if (weekEnd.year != weekStart.year || weekEnd.month != weekStart.month) {
        final endMonthStart = DateTime(weekEnd.year, weekEnd.month, 1);
        final endMonthEnd = DateTime(weekEnd.year, weekEnd.month + 1, 1);
        final list2 = await _firebaseService.getDiaryEntries(
            familyId, endMonthStart, endMonthEnd);
        for (final entry in list2) {
          final key = _normalizeDate(entry.date);
          tempMap.putIfAbsent(key, () => []).add(entry);
        }
      }

      // weekStart 전날이 다른 달인 경우 (예: 5/1 시작 주 → 4/30 필요)
      final prevDay = weekStart.subtract(const Duration(days: 1));
      if (prevDay.year != weekStart.year || prevDay.month != weekStart.month) {
        final prevDayList = await _firebaseService.getDiaryEntries(
            familyId, prevDay, weekStart);
        for (final entry in prevDayList) {
          final key = _normalizeDate(entry.date);
          tempMap.putIfAbsent(key, () => []).add(entry);
        }
      }

      _entries.clear();
      _entries.addAll(tempMap);
    } catch (e) {
      debugPrint('주간 일지 로드 실패: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// ID로 원본 엔트리 조회 (편집용 - 분할 전 원본 반환)
  FoodDiaryEntry? getEntryById(String id) {
    for (final entries in _entries.values) {
      for (final e in entries) {
        if (e.id == id) return e;
      }
    }
    return null;
  }

  /// 수면 엔트리에서 특정 날짜에 해당하는 분량만 계산 (자정 기준 분할)
  int _sleepMinutesOnDate(FoodDiaryEntry e, DateTime date) {
    final midnight = DateTime(date.year, date.month, date.day);
    final nextMidnight = midnight.add(const Duration(days: 1));
    final start = e.mealTime.isBefore(midnight) ? midnight : e.mealTime;
    final end = e.mealTime.add(Duration(minutes: e.durationMinutes!));
    final clampedEnd = end.isAfter(nextMidnight) ? nextMidnight : end;
    return clampedEnd.difference(start).inMinutes.clamp(0, e.durationMinutes!);
  }

  /// 선택된 날짜의 엔트리 리스트
  /// 수면 항목은 자정 기준으로 분할하여 해당 날짜 분량만 표시
  /// 편집 시에는 getEntryById로 원본을 사용할 것
  List<FoodDiaryEntry> getEntriesForDate(DateTime date) {
    final key = _normalizeDate(date);
    final midnight = DateTime(date.year, date.month, date.day);
    final nextMidnight = midnight.add(const Duration(days: 1));
    final seen = <String>{};
    final result = <FoodDiaryEntry>[];

    // 이날 항목 — 자정을 넘기는 수면은 이날 분량만
    for (final e in _entries[key] ?? []) {
      if (e.id.isNotEmpty && !seen.add(e.id)) continue;
      if (e.entryType == EntryType.sleep && (e.durationMinutes ?? 0) > 0) {
        final endTime = e.mealTime.add(Duration(minutes: e.durationMinutes!));
        if (endTime.isAfter(nextMidnight)) {
          final mins = _sleepMinutesOnDate(e, date);
          result.add(e.copyWith(durationMinutes: mins));
        } else {
          result.add(e);
        }
      } else {
        result.add(e);
      }
    }

    // 전날 수면 중 자정을 넘겨 이날까지 이어지는 항목
    // → mealTime을 자정으로, durationMinutes를 이날 분량으로 분할
    final prevKey = _normalizeDate(date.subtract(const Duration(days: 1)));
    for (final e in _entries[prevKey] ?? []) {
      if (e.entryType != EntryType.sleep || (e.durationMinutes ?? 0) <= 0) continue;
      final endTime = e.mealTime.add(Duration(minutes: e.durationMinutes!));
      if (!endTime.isAfter(midnight)) continue;
      if (e.id.isNotEmpty && !seen.add(e.id)) continue;
      final mins = _sleepMinutesOnDate(e, date);
      result.add(e.copyWith(mealTime: midnight, durationMinutes: mins));
    }

    result.sort((a, b) => a.mealTime.compareTo(b.mealTime));
    return result;
  }

  /// 주간 엔트리 전체
  List<FoodDiaryEntry> getWeekEntries(DateTime weekStart) {
    final all = <FoodDiaryEntry>[];
    for (int i = 0; i < 7; i++) {
      all.addAll(getEntriesForDate(weekStart.add(Duration(days: i))));
    }
    return all;
  }

  /// 해당 날짜의 총 영양소
  Nutrition getDayNutrition(DateTime date) {
    final dayEntries = getEntriesForDate(date);
    if (dayEntries.isEmpty) return Nutrition.empty;

    Nutrition total = Nutrition.empty;
    for (final entry in dayEntries) {
      if (!entry.entryType.isNutritionEntry) continue;
      total = total + entry.nutrition;
    }
    return total;
  }

  /// 일일 권장량 대비 퍼센트
  Map<String, double> getNutritionPercentages(
      DateTime date, int babyAgeMonths) {
    final actual = getDayNutrition(date);
    final recommended = DailyRecommendation.getByAge(babyAgeMonths);

    double safe(double actual, double recommended) {
      if (recommended <= 0) return 0;
      return (actual / recommended * 100).clamp(0, 200);
    }

    return {
      '칼로리': safe(actual.calories, recommended.calories),
      '단백질': safe(actual.protein, recommended.protein),
      '탄수화물': safe(actual.carbohydrates, recommended.carbohydrates),
      '지방': safe(actual.fat, recommended.fat),
      '칼슘': safe(actual.calcium, recommended.calcium),
      '철분': safe(actual.iron, recommended.iron),
    };
  }

  // ==================== 주간 통계 ====================

  /// 주간 수유/음료 일별 횟수
  Map<DateTime, int> getWeeklyLiquidCountStats(DateTime weekStart) {
    final result = <DateTime, int>{};
    for (int i = 0; i < 7; i++) {
      final day = _normalizeDate(weekStart.add(Duration(days: i)));
      result[day] =
          getEntriesForDate(day).where((e) => e.entryType.isLiquidEntry).length;
    }
    return result;
  }

  /// 주간 수유/음료 일별 ml 합계
  Map<DateTime, int> getWeeklyLiquidStats(DateTime weekStart) {
    final result = <DateTime, int>{};
    for (int i = 0; i < 7; i++) {
      final day = _normalizeDate(weekStart.add(Duration(days: i)));
      final total = getEntriesForDate(day)
          .where((e) => e.entryType.isLiquidEntry && e.milkAmountMl != null)
          .fold(0, (sum, e) => sum + e.milkAmountMl!);
      result[day] = total;
    }
    return result;
  }

  /// 주간 수면 일별 분 합계
  Map<DateTime, int> getWeeklySleepStats(DateTime weekStart) {
    final split = getWeeklySleepSplitStats(weekStart);
    return split.map((k, v) => MapEntry(k, v.nap + v.night));
  }

  /// 두 시간 범위의 겹치는 분 계산
  int _intersectMinutes(
      DateTime start, DateTime end, DateTime wStart, DateTime wEnd) {
    final s = start.isAfter(wStart) ? start : wStart;
    final e = end.isBefore(wEnd) ? end : wEnd;
    return e.isAfter(s) ? e.difference(s).inMinutes : 0;
  }

  /// 주간 수면을 낮잠(07-20시) / 밤수면(20-07시)으로 분리한 일별 통계
  Map<DateTime, ({int nap, int night})> getWeeklySleepSplitStats(
      DateTime weekStart) {
    final result = <DateTime, ({int nap, int night})>{};
    for (int i = 0; i < 7; i++) {
      final day = _normalizeDate(weekStart.add(Duration(days: i)));
      int nap = 0, night = 0;
      final napStart = DateTime(day.year, day.month, day.day, 7);
      final napEnd = DateTime(day.year, day.month, day.day, 20);
      final nextMidnight = day.add(const Duration(days: 1));

      for (final e in getEntriesForDate(day)) {
        if (e.entryType != EntryType.sleep || (e.durationMinutes ?? 0) <= 0) {
          continue;
        }
        final s = e.mealTime;
        final end = e.mealTime.add(Duration(minutes: e.durationMinutes!));
        nap += _intersectMinutes(s, end, napStart, napEnd);
        night += _intersectMinutes(s, end, day, napStart); // 00:00-07:00
        night += _intersectMinutes(s, end, napEnd, nextMidnight); // 20:00-24:00
      }
      result[day] = (nap: nap, night: night);
    }
    return result;
  }

  /// 주간 기저귀 일별 횟수 (전체)
  Map<DateTime, int> getWeeklyDiaperStats(DateTime weekStart) {
    final result = <DateTime, int>{};
    for (int i = 0; i < 7; i++) {
      final day = _normalizeDate(weekStart.add(Duration(days: i)));
      result[day] =
          getEntriesForDate(day).where((e) => e.entryType == EntryType.diaper).length;
    }
    return result;
  }

  /// 주간 소변 기저귀 일별 횟수 (wet + both)
  Map<DateTime, int> getWeeklyPeeStats(DateTime weekStart) {
    final result = <DateTime, int>{};
    for (int i = 0; i < 7; i++) {
      final day = _normalizeDate(weekStart.add(Duration(days: i)));
      result[day] = getEntriesForDate(day).where((e) =>
          e.entryType == EntryType.diaper &&
          (e.diaperType == DiaperType.wet ||
              e.diaperType == DiaperType.both)).length;
    }
    return result;
  }

  /// 주간 대변 기저귀 일별 횟수 (soiled + both)
  Map<DateTime, int> getWeeklyPoopStats(DateTime weekStart) {
    final result = <DateTime, int>{};
    for (int i = 0; i < 7; i++) {
      final day = _normalizeDate(weekStart.add(Duration(days: i)));
      result[day] = getEntriesForDate(day).where((e) =>
          e.entryType == EntryType.diaper &&
          (e.diaperType == DiaperType.soiled ||
              e.diaperType == DiaperType.both)).length;
    }
    return result;
  }

  /// 주간 체온 기록 (날짜별 최근 체온)
  Map<DateTime, double> getWeeklyTemperatureStats(DateTime weekStart) {
    final result = <DateTime, double>{};
    for (int i = 0; i < 7; i++) {
      final day = _normalizeDate(weekStart.add(Duration(days: i)));
      final temps = getEntriesForDate(day)
          .where((e) =>
              e.entryType == EntryType.temperature &&
              e.temperatureCelsius != null)
          .toList();
      if (temps.isNotEmpty) {
        result[day] = temps.last.temperatureCelsius!;
      }
    }
    return result;
  }

  /// 주간 이유식 일별 칼로리 합계
  Map<DateTime, double> getWeeklyCaloriesStats(DateTime weekStart) {
    final result = <DateTime, double>{};
    for (int i = 0; i < 7; i++) {
      final day = _normalizeDate(weekStart.add(Duration(days: i)));
      result[day] = getDayNutrition(day).calories;
    }
    return result;
  }

  /// 주간 수유 시간 일별 분 합계 (모유/분유/유축수유/우유)
  Map<DateTime, int> getWeeklyFeedingDurationStats(DateTime weekStart) {
    final result = <DateTime, int>{};
    for (int i = 0; i < 7; i++) {
      final day = _normalizeDate(weekStart.add(Duration(days: i)));
      final total = getEntriesForDate(day)
          .where((e) =>
              e.entryType.isMilkFeedingEntry && e.durationMinutes != null)
          .fold(0, (sum, e) => sum + e.durationMinutes!);
      result[day] = total;
    }
    return result;
  }

  /// 주간 활동 일별 분 합계 (놀이 + 터미타임)
  Map<DateTime, int> getWeeklyActivityStats(DateTime weekStart) {
    final result = <DateTime, int>{};
    for (int i = 0; i < 7; i++) {
      final day = _normalizeDate(weekStart.add(Duration(days: i)));
      final total = getEntriesForDate(day)
          .where((e) =>
              (e.entryType == EntryType.play ||
                  e.entryType == EntryType.tummyTime) &&
              e.durationMinutes != null)
          .fold(0, (sum, e) => sum + e.durationMinutes!);
      result[day] = total;
    }
    return result;
  }

  // ==================== CRUD ====================

  /// 일지 추가
  // 위젯에 표시할 아기 이름 (외부에서 설정)
  String _babyName = '우리아이';
  void setBabyName(String name) => _babyName = name;

  /// 오늘 데이터 실시간 감지 시작 (파트너 변경도 자동 반영)
  void startTodayStream(String familyId) {
    _todayStream?.cancel();
    _todayStream = _firebaseService.streamTodayEntries(familyId).listen(
      (todayEntries) {
        // 오늘 날짜 캐시 갱신
        final today = _normalizeDate(DateTime.now());
        _entries[today] = todayEntries;
        notifyListeners();
        // 위젯 업데이트
        WidgetService.updateTodayStats(todayEntries, babyName: _babyName);
      },
      onError: (e) => debugPrint('오늘 스트림 오류: $e'),
    );
  }

  void stopTodayStream() {
    _todayStream?.cancel();
    _todayStream = null;
  }

  @override
  void dispose() {
    _todayStream?.cancel();
    super.dispose();
  }

  Future<bool> addEntry(FoodDiaryEntry entry) async {
    try {
      final docId = await _firebaseService.addDiaryEntry(entry);
      final saved = entry.copyWith(id: docId);
      final key = _normalizeDate(entry.date);
      _entries.putIfAbsent(key, () => []).add(saved);
      notifyListeners();
      _updateWidget(entry.date);
      return true;
    } catch (e) {
      debugPrint('일지 추가 실패: $e');
      return false;
    }
  }

  /// 일지 수정
  Future<bool> updateEntry(FoodDiaryEntry entry) async {
    try {
      await _firebaseService.updateDiaryEntry(entry.id, entry.toJson());
      final key = _normalizeDate(entry.date);
      final list = _entries[key];
      if (list != null) {
        final idx = list.indexWhere((e) => e.id == entry.id);
        if (idx >= 0) list[idx] = entry;
      }
      notifyListeners();
      _updateWidget(entry.date);
      return true;
    } catch (e) {
      debugPrint('일지 수정 실패: $e');
      return false;
    }
  }

  /// 일지 삭제
  Future<bool> deleteEntry(String entryId, DateTime date) async {
    try {
      await _firebaseService.deleteDiaryEntry(entryId);
      final key = _normalizeDate(date);
      _entries[key]?.removeWhere((e) => e.id == entryId);
      if (_entries[key]?.isEmpty ?? false) {
        _entries.remove(key);
      }
      notifyListeners();
      _updateWidget(date);
      return true;
    } catch (e) {
      debugPrint('일지 삭제 실패: $e');
      return false;
    }
  }

  /// 오늘 날짜일 때만 위젯 업데이트
  void _updateWidget(DateTime date) {
    final today = _normalizeDate(DateTime.now());
    if (_normalizeDate(date) == today) {
      WidgetService.updateTodayStats(
        getEntriesForDate(today),
        babyName: _babyName,
      );
    }
  }
}
