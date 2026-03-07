import 'package:flutter/material.dart';
import '../models/food_diary_entry.dart';
import '../models/nutrition.dart';
import '../services/firebase_service.dart';

class DiaryProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;

  DiaryProvider(this._firebaseService);

  // 상태
  final Map<DateTime, List<FoodDiaryEntry>> _entries = {};
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

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
    _entries.clear();
    notifyListeners();

    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 1);

      final list = await _firebaseService.getDiaryEntries(familyId, start, end);

      for (final entry in list) {
        final key = _normalizeDate(entry.date);
        _entries.putIfAbsent(key, () => []).add(entry);
      }
    } catch (e) {
      debugPrint('일지 로드 실패: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 주간 데이터 로드 (월 경계 처리)
  Future<void> loadWeeklyEntries(String familyId, DateTime weekStart) async {
    _isLoading = true;
    _entries.clear();
    notifyListeners();

    try {
      final weekEnd = weekStart.add(const Duration(days: 6));

      // 시작 월 로드
      final startMonthStart = DateTime(weekStart.year, weekStart.month, 1);
      final startMonthEnd = DateTime(weekStart.year, weekStart.month + 1, 1);
      final list1 = await _firebaseService.getDiaryEntries(
          familyId, startMonthStart, startMonthEnd);
      for (final entry in list1) {
        final key = _normalizeDate(entry.date);
        _entries.putIfAbsent(key, () => []).add(entry);
      }

      // 주가 월 경계에 걸치면 끝 월도 로드
      if (weekEnd.year != weekStart.year || weekEnd.month != weekStart.month) {
        final endMonthStart = DateTime(weekEnd.year, weekEnd.month, 1);
        final endMonthEnd = DateTime(weekEnd.year, weekEnd.month + 1, 1);
        final list2 = await _firebaseService.getDiaryEntries(
            familyId, endMonthStart, endMonthEnd);
        for (final entry in list2) {
          final key = _normalizeDate(entry.date);
          _entries.putIfAbsent(key, () => []).add(entry);
        }
      }
    } catch (e) {
      debugPrint('주간 일지 로드 실패: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 선택된 날짜의 엔트리 리스트
  List<FoodDiaryEntry> getEntriesForDate(DateTime date) {
    final key = _normalizeDate(date);
    final list = List<FoodDiaryEntry>.from(_entries[key] ?? []);
    list.sort((a, b) => a.mealTime.compareTo(b.mealTime));
    return list;
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
    final result = <DateTime, int>{};
    for (int i = 0; i < 7; i++) {
      final day = _normalizeDate(weekStart.add(Duration(days: i)));
      final total = getEntriesForDate(day)
          .where(
              (e) => e.entryType == EntryType.sleep && e.durationMinutes != null)
          .fold(0, (sum, e) => sum + e.durationMinutes!);
      result[day] = total;
    }
    return result;
  }

  /// 주간 기저귀 일별 횟수
  Map<DateTime, int> getWeeklyDiaperStats(DateTime weekStart) {
    final result = <DateTime, int>{};
    for (int i = 0; i < 7; i++) {
      final day = _normalizeDate(weekStart.add(Duration(days: i)));
      result[day] =
          getEntriesForDate(day).where((e) => e.entryType == EntryType.diaper).length;
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
  Future<bool> addEntry(FoodDiaryEntry entry) async {
    try {
      final docId = await _firebaseService.addDiaryEntry(entry);
      final saved = entry.copyWith(id: docId);
      final key = _normalizeDate(entry.date);
      _entries.putIfAbsent(key, () => []).add(saved);
      notifyListeners();
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
      return true;
    } catch (e) {
      debugPrint('일지 삭제 실패: $e');
      return false;
    }
  }
}
