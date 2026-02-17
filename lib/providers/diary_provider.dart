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
    notifyListeners();

    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 1);

      final list = await _firebaseService.getDiaryEntries(familyId, start, end);

      // 날짜별 그룹핑
      _entries.clear();
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

  /// 선택된 날짜의 엔트리 리스트
  List<FoodDiaryEntry> getEntriesForDate(DateTime date) {
    final key = _normalizeDate(date);
    final list = _entries[key] ?? [];
    list.sort((a, b) => a.mealTime.compareTo(b.mealTime));
    return list;
  }

  /// 해당 날짜의 총 영양소
  Nutrition getDayNutrition(DateTime date) {
    final dayEntries = getEntriesForDate(date);
    if (dayEntries.isEmpty) return Nutrition.empty;

    Nutrition total = Nutrition.empty;
    for (final entry in dayEntries) {
      if (entry.isMilkEntry) continue;
      total = total + entry.nutrition;
    }
    return total;
  }

  /// 일일 권장량 대비 퍼센트
  Map<String, double> getNutritionPercentages(DateTime date, int babyAgeMonths) {
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
