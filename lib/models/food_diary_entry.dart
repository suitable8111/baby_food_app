import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ingredient.dart';
import 'nutrition.dart';

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
  final DateTime date; // 날짜 (시간 제거, 쿼리용)
  final MealType mealType;
  final DateTime mealTime; // 실제 먹은 시간
  final String recipeId;
  final String recipeName;
  final BabyFoodStage recipeStage;
  final Nutrition nutrition;
  final String? memo;
  final DateTime? createdAt;

  const FoodDiaryEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.mealTime,
    required this.recipeId,
    required this.recipeName,
    required this.recipeStage,
    required this.nutrition,
    this.memo,
    this.createdAt,
  });

  FoodDiaryEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    MealType? mealType,
    DateTime? mealTime,
    String? recipeId,
    String? recipeName,
    BabyFoodStage? recipeStage,
    Nutrition? nutrition,
    String? memo,
    DateTime? createdAt,
  }) {
    return FoodDiaryEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      mealTime: mealTime ?? this.mealTime,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      recipeStage: recipeStage ?? this.recipeStage,
      nutrition: nutrition ?? this.nutrition,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'mealType': mealType.name,
      'mealTime': Timestamp.fromDate(mealTime),
      'recipeId': recipeId,
      'recipeName': recipeName,
      'recipeStage': recipeStage.index,
      'nutrition': nutrition.toJson(),
      'memo': memo,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  factory FoodDiaryEntry.fromJson(Map<String, dynamic> json, {String id = ''}) {
    return FoodDiaryEntry(
      id: id,
      userId: json['userId'] ?? '',
      date: json['date'] != null
          ? (json['date'] as Timestamp).toDate()
          : DateTime.now(),
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
      memo: json['memo'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory FoodDiaryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodDiaryEntry.fromJson(data, id: doc.id);
  }
}
