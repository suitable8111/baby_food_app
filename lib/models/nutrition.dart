/// 영양소 정보 모델
class Nutrition {
  final double calories;      // kcal
  final double carbohydrates; // g (탄수화물)
  final double protein;       // g (단백질)
  final double fat;           // g (지방)
  final double fiber;         // g (식이섬유)
  final double vitaminA;      // μg RAE
  final double vitaminC;      // mg
  final double vitaminD;      // μg
  final double calcium;       // mg (칼슘)
  final double iron;          // mg (철분)
  final double zinc;          // mg (아연)
  final double sodium;        // mg (나트륨)

  const Nutrition({
    this.calories = 0,
    this.carbohydrates = 0,
    this.protein = 0,
    this.fat = 0,
    this.fiber = 0,
    this.vitaminA = 0,
    this.vitaminC = 0,
    this.vitaminD = 0,
    this.calcium = 0,
    this.iron = 0,
    this.zinc = 0,
    this.sodium = 0,
  });

  /// 두 영양소 정보를 더함
  Nutrition operator +(Nutrition other) {
    return Nutrition(
      calories: calories + other.calories,
      carbohydrates: carbohydrates + other.carbohydrates,
      protein: protein + other.protein,
      fat: fat + other.fat,
      fiber: fiber + other.fiber,
      vitaminA: vitaminA + other.vitaminA,
      vitaminC: vitaminC + other.vitaminC,
      vitaminD: vitaminD + other.vitaminD,
      calcium: calcium + other.calcium,
      iron: iron + other.iron,
      zinc: zinc + other.zinc,
      sodium: sodium + other.sodium,
    );
  }

  /// 비율에 따라 영양소 계산 (100g 기준 -> 실제 그램수)
  Nutrition multiply(double factor) {
    return Nutrition(
      calories: calories * factor,
      carbohydrates: carbohydrates * factor,
      protein: protein * factor,
      fat: fat * factor,
      fiber: fiber * factor,
      vitaminA: vitaminA * factor,
      vitaminC: vitaminC * factor,
      vitaminD: vitaminD * factor,
      calcium: calcium * factor,
      iron: iron * factor,
      zinc: zinc * factor,
      sodium: sodium * factor,
    );
  }

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'carbohydrates': carbohydrates,
      'protein': protein,
      'fat': fat,
      'fiber': fiber,
      'vitaminA': vitaminA,
      'vitaminC': vitaminC,
      'vitaminD': vitaminD,
      'calcium': calcium,
      'iron': iron,
      'zinc': zinc,
      'sodium': sodium,
    };
  }

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      calories: (json['calories'] ?? 0).toDouble(),
      carbohydrates: (json['carbohydrates'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      vitaminA: (json['vitaminA'] ?? 0).toDouble(),
      vitaminC: (json['vitaminC'] ?? 0).toDouble(),
      vitaminD: (json['vitaminD'] ?? 0).toDouble(),
      calcium: (json['calcium'] ?? 0).toDouble(),
      iron: (json['iron'] ?? 0).toDouble(),
      zinc: (json['zinc'] ?? 0).toDouble(),
      sodium: (json['sodium'] ?? 0).toDouble(),
    );
  }

  static const Nutrition empty = Nutrition();
}

/// 아기 월령별 일일 권장 영양소 (참고값)
class DailyRecommendation {
  static Nutrition getByAge(int months) {
    if (months <= 6) {
      // 4-6개월
      return const Nutrition(
        calories: 500,
        protein: 9,
        iron: 0.27,
        calcium: 200,
        vitaminA: 400,
        vitaminC: 40,
        vitaminD: 10,
        zinc: 2,
      );
    } else if (months <= 12) {
      // 7-12개월
      return const Nutrition(
        calories: 700,
        protein: 11,
        iron: 11,
        calcium: 260,
        vitaminA: 500,
        vitaminC: 50,
        vitaminD: 10,
        zinc: 3,
      );
    } else {
      // 12개월 이상
      return const Nutrition(
        calories: 900,
        protein: 13,
        iron: 7,
        calcium: 700,
        vitaminA: 300,
        vitaminC: 15,
        vitaminD: 15,
        zinc: 3,
      );
    }
  }
}
