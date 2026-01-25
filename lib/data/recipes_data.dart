import '../models/ingredient.dart';
import '../models/recipe.dart';
import 'ingredients_data.dart';

/// 기본 레시피 데이터
final List<Recipe> defaultRecipes = [
  // ========== 초기 이유식 (4-6개월) ==========
  Recipe(
    id: 'rice_porridge',
    name: '쌀미음',
    stage: BabyFoodStage.early,
    ingredients: [
      RecipeIngredient(
        ingredient: findIngredientById('rice')!,
        amount: 10,
      ),
    ],
    steps: [
      '쌀을 깨끗이 씻어 30분 이상 불린다.',
      '불린 쌀을 믹서에 곱게 간다.',
      '냄비에 쌀가루와 물 100ml를 넣고 중불에서 저어가며 끓인다.',
      '농도가 걸쭉해지면 약불로 줄이고 5분 더 끓인다.',
      '체에 걸러 덩어리를 제거하고 식혀서 제공한다.',
    ],
    cookingTimeMinutes: 20,
    difficulty: Difficulty.easy,
    storageInfo: '냉장 1일, 냉동 1주',
    tip: '처음에는 묽게 시작하여 점차 농도를 높여주세요.',
  ),

  Recipe(
    id: 'carrot_rice_porridge',
    name: '당근 쌀미음',
    stage: BabyFoodStage.early,
    ingredients: [
      RecipeIngredient(
        ingredient: findIngredientById('rice')!,
        amount: 10,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('carrot')!,
        amount: 15,
      ),
    ],
    steps: [
      '쌀을 깨끗이 씻어 30분 이상 불린다.',
      '당근은 껍질을 벗기고 잘게 썬다.',
      '당근을 부드럽게 삶아 으깬다.',
      '불린 쌀과 으깬 당근을 믹서에 곱게 간다.',
      '냄비에 물 100ml와 함께 넣고 저어가며 끓인다.',
      '체에 걸러 부드럽게 만들어 식힌다.',
    ],
    cookingTimeMinutes: 25,
    difficulty: Difficulty.easy,
    storageInfo: '냉장 1일, 냉동 1주',
    tip: '당근은 충분히 익혀야 소화가 잘 됩니다.',
  ),

  Recipe(
    id: 'sweet_potato_puree',
    name: '고구마 퓌레',
    stage: BabyFoodStage.early,
    ingredients: [
      RecipeIngredient(
        ingredient: findIngredientById('sweet_potato')!,
        amount: 50,
      ),
    ],
    steps: [
      '고구마를 깨끗이 씻어 껍질째 찐다.',
      '푹 익은 고구마의 껍질을 벗긴다.',
      '뜨거울 때 포크로 으깬다.',
      '물이나 모유/분유를 조금씩 넣어 농도를 조절한다.',
      '체에 걸러 부드럽게 만든다.',
    ],
    cookingTimeMinutes: 30,
    difficulty: Difficulty.easy,
    storageInfo: '냉장 2일, 냉동 2주',
    tip: '단맛이 있어 아기가 잘 먹습니다. 처음 시작하기 좋은 이유식입니다.',
  ),

  Recipe(
    id: 'potato_puree',
    name: '감자 퓌레',
    stage: BabyFoodStage.early,
    ingredients: [
      RecipeIngredient(
        ingredient: findIngredientById('potato')!,
        amount: 50,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('olive_oil')!,
        amount: 2,
      ),
    ],
    steps: [
      '감자를 깨끗이 씻어 껍질을 벗긴다.',
      '적당한 크기로 잘라 부드럽게 삶는다.',
      '삶은 감자를 으깬다.',
      '올리브오일을 약간 넣고 섞는다.',
      '물이나 모유/분유를 넣어 농도를 조절한다.',
    ],
    cookingTimeMinutes: 25,
    difficulty: Difficulty.easy,
    storageInfo: '냉장 2일, 냉동 2주',
    tip: '올리브오일을 넣으면 영양 흡수가 좋아집니다.',
  ),

  Recipe(
    id: 'apple_puree',
    name: '사과 퓌레',
    stage: BabyFoodStage.early,
    ingredients: [
      RecipeIngredient(
        ingredient: findIngredientById('apple')!,
        amount: 50,
      ),
    ],
    steps: [
      '사과를 깨끗이 씻어 껍질을 벗긴다.',
      '씨를 제거하고 잘게 자른다.',
      '냄비에 사과와 물 약간을 넣고 부드럽게 익힌다.',
      '익힌 사과를 믹서에 곱게 간다.',
      '체에 걸러 부드럽게 만든다.',
    ],
    cookingTimeMinutes: 15,
    difficulty: Difficulty.easy,
    storageInfo: '냉장 1일, 냉동 1주',
    tip: '처음에는 익힌 사과로 시작하고, 적응하면 생과일도 가능합니다.',
  ),

  Recipe(
    id: 'banana_puree',
    name: '바나나 퓌레',
    stage: BabyFoodStage.early,
    ingredients: [
      RecipeIngredient(
        ingredient: findIngredientById('banana')!,
        amount: 40,
      ),
    ],
    steps: [
      '잘 익은 바나나 껍질을 벗긴다.',
      '포크로 곱게 으깬다.',
      '필요시 모유나 분유를 넣어 농도를 조절한다.',
    ],
    cookingTimeMinutes: 5,
    difficulty: Difficulty.easy,
    storageInfo: '즉시 섭취 권장 (갈변됨)',
    tip: '검은 반점이 있는 잘 익은 바나나가 소화가 잘 됩니다.',
  ),

  // ========== 중기 이유식 (7-9개월) ==========
  Recipe(
    id: 'vegetable_chicken_porridge',
    name: '닭고기 야채죽',
    stage: BabyFoodStage.middle,
    ingredients: [
      RecipeIngredient(
        ingredient: findIngredientById('rice')!,
        amount: 30,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('chicken_breast')!,
        amount: 20,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('carrot')!,
        amount: 15,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('zucchini')!,
        amount: 15,
      ),
    ],
    steps: [
      '쌀을 씻어 30분 불린 후 믹서에 굵게 간다.',
      '닭가슴살을 삶아 잘게 다진다.',
      '당근, 애호박을 작은 주사위 모양으로 썬다.',
      '냄비에 물 200ml, 쌀, 야채를 넣고 중불에서 끓인다.',
      '야채가 익으면 다진 닭고기를 넣는다.',
      '약불로 줄이고 10분간 저어가며 끓인다.',
      '적당한 온도로 식혀 제공한다.',
    ],
    cookingTimeMinutes: 35,
    difficulty: Difficulty.medium,
    storageInfo: '냉장 2일, 냉동 2주',
    tip: '닭고기는 완전히 익혀야 합니다. 육수를 사용하면 더 맛있어요.',
  ),

  Recipe(
    id: 'beef_spinach_porridge',
    name: '소고기 시금치죽',
    stage: BabyFoodStage.middle,
    ingredients: [
      RecipeIngredient(
        ingredient: findIngredientById('rice')!,
        amount: 30,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('beef')!,
        amount: 20,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('spinach')!,
        amount: 20,
      ),
    ],
    steps: [
      '쌀을 씻어 불린 후 굵게 간다.',
      '소고기는 핏물을 빼고 잘게 다진다.',
      '시금치는 데쳐서 잘게 다진다.',
      '냄비에 물, 쌀, 소고기를 넣고 끓인다.',
      '죽이 끓으면 시금치를 넣고 저어가며 익힌다.',
      '적당한 농도가 되면 불을 끄고 식힌다.',
    ],
    cookingTimeMinutes: 30,
    difficulty: Difficulty.medium,
    storageInfo: '냉장 2일, 냉동 2주',
    tip: '소고기는 철분 보충에 좋습니다. 시금치와 함께 먹으면 흡수가 좋아요.',
  ),

  Recipe(
    id: 'tofu_vegetable_porridge',
    name: '두부 야채죽',
    stage: BabyFoodStage.middle,
    ingredients: [
      RecipeIngredient(
        ingredient: findIngredientById('rice')!,
        amount: 30,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('tofu')!,
        amount: 30,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('broccoli')!,
        amount: 20,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('carrot')!,
        amount: 15,
      ),
    ],
    steps: [
      '쌀을 불려 굵게 간다.',
      '두부는 끓는 물에 데쳐 으깬다.',
      '브로콜리, 당근을 잘게 다진다.',
      '냄비에 물, 쌀, 야채를 넣고 끓인다.',
      '야채가 익으면 두부를 넣고 저어가며 끓인다.',
      '알맞은 농도로 완성한다.',
    ],
    cookingTimeMinutes: 30,
    difficulty: Difficulty.medium,
    storageInfo: '냉장 1일, 냉동 1주',
    tip: '두부 알레르기가 있는지 소량으로 먼저 확인하세요.',
  ),

  Recipe(
    id: 'egg_yolk_porridge',
    name: '달걀 노른자죽',
    stage: BabyFoodStage.middle,
    ingredients: [
      RecipeIngredient(
        ingredient: findIngredientById('rice')!,
        amount: 30,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('egg_yolk')!,
        amount: 15, // 약 1개 노른자
      ),
      RecipeIngredient(
        ingredient: findIngredientById('carrot')!,
        amount: 10,
      ),
    ],
    steps: [
      '달걀을 완숙으로 삶아 노른자만 분리한다.',
      '쌀을 불려 죽을 끓인다.',
      '당근을 삶아 다진다.',
      '죽에 노른자를 으깨어 넣고 잘 섞는다.',
      '당근을 넣고 한소끔 끓인다.',
    ],
    cookingTimeMinutes: 30,
    difficulty: Difficulty.medium,
    storageInfo: '냉장 1일',
    tip: '달걀 알레르기 확인 필수! 노른자부터 시작하세요.',
  ),

  // ========== 후기 이유식 (10-12개월) ==========
  Recipe(
    id: 'salmon_vegetable_rice',
    name: '연어 야채 진밥',
    stage: BabyFoodStage.late,
    ingredients: [
      RecipeIngredient(
        ingredient: findIngredientById('rice')!,
        amount: 50,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('salmon')!,
        amount: 30,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('broccoli')!,
        amount: 20,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('carrot')!,
        amount: 15,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('olive_oil')!,
        amount: 3,
      ),
    ],
    steps: [
      '쌀로 진밥을 짓는다.',
      '연어는 가시를 완전히 제거하고 굽거나 찐다.',
      '연어를 잘게 부순다.',
      '브로콜리, 당근을 잘게 다져 올리브오일에 볶는다.',
      '진밥에 연어와 야채를 섞는다.',
      '골고루 섞어 제공한다.',
    ],
    cookingTimeMinutes: 40,
    difficulty: Difficulty.medium,
    storageInfo: '냉장 1일, 냉동 2주',
    tip: '연어 가시는 완전히 제거해주세요. 오메가3가 풍부합니다.',
  ),

  Recipe(
    id: 'beef_pumpkin_rice',
    name: '소고기 단호박 진밥',
    stage: BabyFoodStage.late,
    ingredients: [
      RecipeIngredient(
        ingredient: findIngredientById('rice')!,
        amount: 50,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('beef')!,
        amount: 30,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('pumpkin')!,
        amount: 40,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('spinach')!,
        amount: 15,
      ),
    ],
    steps: [
      '쌀로 진밥을 짓는다.',
      '소고기는 잘게 다져 볶는다.',
      '단호박은 찌서 으깬다.',
      '시금치는 데쳐서 다진다.',
      '진밥에 모든 재료를 섞는다.',
    ],
    cookingTimeMinutes: 35,
    difficulty: Difficulty.medium,
    storageInfo: '냉장 2일, 냉동 2주',
    tip: '단호박의 단맛으로 아기가 잘 먹습니다.',
  ),

  Recipe(
    id: 'cheese_vegetable_oatmeal',
    name: '치즈 야채 오트밀',
    stage: BabyFoodStage.late,
    ingredients: [
      RecipeIngredient(
        ingredient: findIngredientById('oatmeal')!,
        amount: 30,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('cheese')!,
        amount: 10,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('broccoli')!,
        amount: 20,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('carrot')!,
        amount: 15,
      ),
    ],
    steps: [
      '오트밀을 물 또는 우유와 함께 끓인다.',
      '브로콜리, 당근을 잘게 다져 삶는다.',
      '오트밀에 삶은 야채를 넣는다.',
      '치즈를 잘게 썰어 넣고 녹인다.',
      '골고루 섞어 제공한다.',
    ],
    cookingTimeMinutes: 20,
    difficulty: Difficulty.easy,
    storageInfo: '냉장 1일',
    tip: '치즈는 저염 치즈를 사용하세요.',
  ),

  Recipe(
    id: 'yogurt_fruit_bowl',
    name: '요거트 과일 볼',
    stage: BabyFoodStage.late,
    ingredients: [
      RecipeIngredient(
        ingredient: findIngredientById('yogurt')!,
        amount: 80,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('banana')!,
        amount: 30,
      ),
      RecipeIngredient(
        ingredient: findIngredientById('apple')!,
        amount: 20,
      ),
    ],
    steps: [
      '바나나를 작은 조각으로 자른다.',
      '사과를 깨끗이 씻어 껍질을 벗기고 작게 자른다.',
      '플레인 요거트에 과일을 담는다.',
      '부드럽게 섞어 제공한다.',
    ],
    cookingTimeMinutes: 10,
    difficulty: Difficulty.easy,
    storageInfo: '즉시 섭취',
    tip: '무가당 플레인 요거트를 사용하세요. 간식으로 좋습니다.',
  ),
];

/// 단계별 레시피 필터링
List<Recipe> getRecipesByStage(BabyFoodStage stage) {
  return defaultRecipes.where((r) => r.stage == stage).toList();
}

/// ID로 레시피 찾기
Recipe? findRecipeById(String id) {
  try {
    return defaultRecipes.firstWhere((r) => r.id == id);
  } catch (e) {
    return null;
  }
}
