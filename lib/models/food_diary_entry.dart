import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ingredient.dart';
import 'nutrition.dart';

/// 기저귀 유형
enum DiaperType { wet, soiled, both, dry }

extension DiaperTypeExtension on DiaperType {
  String get displayName {
    switch (this) {
      case DiaperType.wet:
        return '소변';
      case DiaperType.soiled:
        return '대변';
      case DiaperType.both:
        return '소+대변';
      case DiaperType.dry:
        return '없음';
    }
  }

  IconData get icon {
    switch (this) {
      case DiaperType.wet:
        return Icons.water_drop_outlined;
      case DiaperType.soiled:
        return Icons.circle_rounded;
      case DiaperType.both:
        return Icons.water_drop_rounded;
      case DiaperType.dry:
        return Icons.check_circle_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case DiaperType.wet:
        return const Color(0xFF4FC3F7);
      case DiaperType.soiled:
        return const Color(0xFFA1887F);
      case DiaperType.both:
        return const Color(0xFFFFB74D);
      case DiaperType.dry:
        return const Color(0xFF90A4AE);
    }
  }
}

/// 기록 유형
enum EntryType {
  food,        // 이유식
  formulaMilk, // 분유
  breastMilk,  // 모유
  pumpedMilk,  // 유축 수유
  pumping,     // 유축
  cowMilk,     // 우유
  water,       // 물
  snackFood,   // 간식
  diaper,      // 기저귀
  sleep,       // 수면
  bath,        // 목욕
  hospital,    // 병원
  temperature, // 체온
  medication,  // 투약
  play,        // 놀이
  tummyTime,   // 터미타임
  other,       // 기타
}

extension EntryTypeExtension on EntryType {
  String get displayName {
    switch (this) {
      case EntryType.food:
        return '이유식';
      case EntryType.formulaMilk:
        return '분유';
      case EntryType.breastMilk:
        return '모유';
      case EntryType.pumpedMilk:
        return '유축수유';
      case EntryType.pumping:
        return '유축';
      case EntryType.cowMilk:
        return '우유';
      case EntryType.water:
        return '물';
      case EntryType.snackFood:
        return '간식';
      case EntryType.diaper:
        return '기저귀';
      case EntryType.sleep:
        return '수면';
      case EntryType.bath:
        return '목욕';
      case EntryType.hospital:
        return '병원';
      case EntryType.temperature:
        return '체온';
      case EntryType.medication:
        return '투약';
      case EntryType.play:
        return '놀이';
      case EntryType.tummyTime:
        return '터미타임';
      case EntryType.other:
        return '기타';
    }
  }

  Color get color {
    switch (this) {
      case EntryType.food:
        return const Color(0xFF6BBF59);
      case EntryType.formulaMilk:
        return const Color(0xFF29B6F6);
      case EntryType.breastMilk:
        return const Color(0xFFF48FB1);
      case EntryType.pumpedMilk:
        return const Color(0xFF26C6DA);
      case EntryType.pumping:
        return const Color(0xFF80CBC4);
      case EntryType.cowMilk:
        return const Color(0xFFFBC02D);
      case EntryType.water:
        return const Color(0xFF4FC3F7);
      case EntryType.snackFood:
        return const Color(0xFFFF8A65);
      case EntryType.diaper:
        return const Color(0xFFFFB74D);
      case EntryType.sleep:
        return const Color(0xFF9575CD);
      case EntryType.bath:
        return const Color(0xFF4DD0E1);
      case EntryType.hospital:
        return const Color(0xFFEF5350);
      case EntryType.temperature:
        return const Color(0xFFF06292);
      case EntryType.medication:
        return const Color(0xFFFF7043);
      case EntryType.play:
        return const Color(0xFF66BB6A);
      case EntryType.tummyTime:
        return const Color(0xFF81C784);
      case EntryType.other:
        return const Color(0xFF90A4AE);
    }
  }

  IconData get icon {
    switch (this) {
      case EntryType.food:
        return Icons.restaurant_rounded;
      case EntryType.formulaMilk:
        return Icons.local_cafe_rounded;
      case EntryType.breastMilk:
        return Icons.favorite_rounded;
      case EntryType.pumpedMilk:
        return Icons.water_drop_rounded;
      case EntryType.pumping:
        return Icons.opacity_rounded;
      case EntryType.cowMilk:
        return Icons.emoji_food_beverage_rounded;
      case EntryType.water:
        return Icons.water_drop_outlined;
      case EntryType.snackFood:
        return Icons.cookie_rounded;
      case EntryType.diaper:
        return Icons.baby_changing_station_rounded;
      case EntryType.sleep:
        return Icons.bedtime_rounded;
      case EntryType.bath:
        return Icons.bathtub_rounded;
      case EntryType.hospital:
        return Icons.local_hospital_rounded;
      case EntryType.temperature:
        return Icons.thermostat_rounded;
      case EntryType.medication:
        return Icons.medication_rounded;
      case EntryType.play:
        return Icons.sports_esports_rounded;
      case EntryType.tummyTime:
        return Icons.child_care_rounded;
      case EntryType.other:
        return Icons.more_horiz_rounded;
    }
  }

  /// 수유/음료 계열 (ml 입력)
  bool get isLiquidEntry => const {
        EntryType.formulaMilk,
        EntryType.breastMilk,
        EntryType.pumpedMilk,
        EntryType.pumping,
        EntryType.cowMilk,
        EntryType.water,
      }.contains(this);

  /// 시간 계열 (분 입력)
  bool get isDurationEntry => const {
        EntryType.sleep,
        EntryType.bath,
        EntryType.play,
        EntryType.tummyTime,
      }.contains(this);

  /// 수유 시간 기록 대상 (모유/분유/유축수유/우유)
  bool get isMilkFeedingEntry => const {
        EntryType.breastMilk,
        EntryType.formulaMilk,
        EntryType.pumpedMilk,
        EntryType.cowMilk,
      }.contains(this);

  /// 이유식 영양 추적 대상
  bool get isNutritionEntry => this == EntryType.food;
}

/// 식사 유형
enum MealType {
  breakfast, // 아침
  lunch, // 점심
  dinner, // 저녁
  snack, // 간식
}

extension MealTypeExtension on MealType {
  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return '아침';
      case MealType.lunch:
        return '점심';
      case MealType.dinner:
        return '저녁';
      case MealType.snack:
        return '간식';
    }
  }

  IconData get icon {
    switch (this) {
      case MealType.breakfast:
        return Icons.wb_sunny_rounded;
      case MealType.lunch:
        return Icons.wb_cloudy_rounded;
      case MealType.dinner:
        return Icons.nightlight_rounded;
      case MealType.snack:
        return Icons.cookie_rounded;
    }
  }

  Color get color {
    switch (this) {
      case MealType.breakfast:
        return const Color(0xFFFFA726);
      case MealType.lunch:
        return const Color(0xFF42A5F5);
      case MealType.dinner:
        return const Color(0xFF7E57C2);
      case MealType.snack:
        return const Color(0xFF66BB6A);
    }
  }
}

/// 이유식 일지 엔트리
class FoodDiaryEntry {
  final String id;
  final String userId;
  final DateTime date;
  final EntryType entryType;
  final MealType mealType;
  final DateTime mealTime;
  final String recipeId;
  final String recipeName;   // 이유식 레시피 이름 / 간식명 / 투약명 공용
  final BabyFoodStage recipeStage;
  final Nutrition nutrition;
  final int? milkAmountMl;   // 수유/음료/유축 ml
  final String? memo;
  final String? familyId;
  final String? authorName;
  final DateTime? createdAt;
  // 확장 필드
  final int? durationMinutes;       // 수면/목욕/놀이/터미타임 (분)
  final double? temperatureCelsius; // 체온 (°C)
  final DiaperType? diaperType;     // 기저귀 유형

  const FoodDiaryEntry({
    required this.id,
    required this.userId,
    required this.date,
    this.entryType = EntryType.food,
    required this.mealType,
    required this.mealTime,
    required this.recipeId,
    required this.recipeName,
    required this.recipeStage,
    required this.nutrition,
    this.milkAmountMl,
    this.memo,
    this.familyId,
    this.authorName,
    this.createdAt,
    this.durationMinutes,
    this.temperatureCelsius,
    this.diaperType,
  });

  /// 구 호환: 수유/음료 여부
  bool get isMilkEntry => entryType.isLiquidEntry;

  FoodDiaryEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    EntryType? entryType,
    MealType? mealType,
    DateTime? mealTime,
    String? recipeId,
    String? recipeName,
    BabyFoodStage? recipeStage,
    Nutrition? nutrition,
    int? milkAmountMl,
    String? memo,
    String? familyId,
    String? authorName,
    DateTime? createdAt,
    int? durationMinutes,
    double? temperatureCelsius,
    DiaperType? diaperType,
  }) {
    return FoodDiaryEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      entryType: entryType ?? this.entryType,
      mealType: mealType ?? this.mealType,
      mealTime: mealTime ?? this.mealTime,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      recipeStage: recipeStage ?? this.recipeStage,
      nutrition: nutrition ?? this.nutrition,
      milkAmountMl: milkAmountMl ?? this.milkAmountMl,
      memo: memo ?? this.memo,
      familyId: familyId ?? this.familyId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      diaperType: diaperType ?? this.diaperType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'familyId': familyId ?? userId,
      'date': Timestamp.fromDate(date),
      'entryType': entryType.name,
      'mealType': mealType.name,
      'mealTime': Timestamp.fromDate(mealTime),
      'recipeId': recipeId,
      'recipeName': recipeName,
      'recipeStage': recipeStage.index,
      'nutrition': nutrition.toJson(),
      'milkAmountMl': milkAmountMl,
      'memo': memo,
      'authorName': authorName,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'durationMinutes': durationMinutes,
      'temperatureCelsius': temperatureCelsius,
      'diaperType': diaperType?.name,
    };
  }

  factory FoodDiaryEntry.fromJson(Map<String, dynamic> json,
      {String id = ''}) {
    return FoodDiaryEntry(
      id: id,
      userId: json['userId'] ?? '',
      date: json['date'] != null
          ? (json['date'] as Timestamp).toDate()
          : DateTime.now(),
      entryType: EntryType.values.firstWhere(
        (e) => e.name == json['entryType'],
        orElse: () => EntryType.food,
      ),
      mealType: MealType.values.firstWhere(
        (e) => e.name == json['mealType'],
        orElse: () => MealType.breakfast,
      ),
      mealTime: json['mealTime'] != null
          ? (json['mealTime'] as Timestamp).toDate()
          : DateTime.now(),
      recipeId: json['recipeId'] ?? '',
      recipeName: json['recipeName'] ?? '',
      recipeStage: BabyFoodStage.values[json['recipeStage'] ?? 0],
      nutrition: json['nutrition'] != null
          ? Nutrition.fromJson(json['nutrition'])
          : Nutrition.empty,
      milkAmountMl: json['milkAmountMl'] as int?,
      memo: json['memo'],
      familyId: json['familyId'],
      authorName: json['authorName'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      durationMinutes: json['durationMinutes'] as int?,
      temperatureCelsius: (json['temperatureCelsius'] as num?)?.toDouble(),
      diaperType: json['diaperType'] != null
          ? DiaperType.values.firstWhere(
              (e) => e.name == json['diaperType'],
              orElse: () => DiaperType.wet,
            )
          : null,
    );
  }

  factory FoodDiaryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodDiaryEntry.fromJson(data, id: doc.id);
  }
}
