import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/food_diary_entry.dart';

class WidgetService {
  static const _appGroupId = 'group.com.babyfood.babyFoodApp';
  static const _iOSWidgetName = 'BabyTrackerWidget';
  static const _androidWidgetName = 'BabyTrackerWidget';

  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (e) {
      debugPrint('위젯 초기화 실패: $e');
    }
  }

  static Future<void> updateTodayStats(
    List<FoodDiaryEntry> todayEntries, {
    String babyName = '우리아이',
  }) async {
    try {
      final feedingEntries =
          todayEntries.where((e) => e.entryType.isLiquidEntry).toList();
      final feedingCount = feedingEntries.length;
      final feedingMl = feedingEntries.fold(
        0,
        (sum, e) => sum + (e.milkAmountMl ?? 0),
      );

      final diaperCount =
          todayEntries.where((e) => e.entryType == EntryType.diaper).length;

      final playMinutes = todayEntries
          .where((e) =>
              e.entryType == EntryType.play ||
              e.entryType == EntryType.tummyTime)
          .fold(0, (sum, e) => sum + (e.durationMinutes ?? 0));

      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      await HomeWidget.saveWidgetData('feedingCount', feedingCount);
      await HomeWidget.saveWidgetData('feedingMl', feedingMl);
      await HomeWidget.saveWidgetData('diaperCount', diaperCount);
      await HomeWidget.saveWidgetData('playMinutes', playMinutes);
      await HomeWidget.saveWidgetData('babyName', babyName);
      await HomeWidget.saveWidgetData('lastUpdate', timeStr);

      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e) {
      debugPrint('위젯 업데이트 실패: $e');
    }
  }
}
