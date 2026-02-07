import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/nutrition.dart';
import '../providers/recipe_provider.dart';
import '../widgets/ingredient_selector.dart';
import '../services/image_service.dart';

class RecipeEditScreen extends StatefulWidget {
  final Recipe? recipe; // null이면 새로 생성, 있으면 편집

  const RecipeEditScreen({super.key, this.recipe});

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _tipController;
  late TextEditingController _storageController;

  late BabyFoodStage _selectedStage;
  late Difficulty _selectedDifficulty;
  late int _cookingTime;
  late List<RecipeIngredientData> _ingredientData;
  late List<String> _steps;

  // 이미지 관련
  final ImageService _imageService = ImageService();
  XFile? _selectedImage;
  String? _existingImageUrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;

    _nameController = TextEditingController(text: recipe?.name ?? '');
    _tipController = TextEditingController(text: recipe?.tip ?? '');
    _storageController = TextEditingController(text: recipe?.storageInfo ?? '');
    _selectedStage = recipe?.stage ?? BabyFoodStage.early;
    _selectedDifficulty = recipe?.difficulty ?? Difficulty.easy;
    _cookingTime = recipe?.cookingTimeMinutes ?? 20;
    _ingredientData = recipe?.ingredientData.toList() ?? [];
    _steps = recipe?.steps.toList() ?? [''];
    _existingImageUrl = recipe?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tipController.dispose();
    _storageController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.recipe?.userId != null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredientData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('재료를 1개 이상 추가해주세요.')),
      );
      return;
    }

    final nonEmptySteps = _steps.where((s) => s.trim().isNotEmpty).toList();
    if (nonEmptySteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('조리법을 1단계 이상 입력해주세요.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final recipeProvider = context.read<RecipeProvider>();

    // 이미지 저장
    String? imageUrl = _existingImageUrl;
    if (_selectedImage != null) {
      final savedPath = await _imageService.saveRecipeImage(
        _selectedImage!,
        _nameController.text.trim(),
      );
      if (savedPath != null) {
        imageUrl = savedPath;
      }
    }

    final newRecipe = Recipe(
      id: widget.recipe?.id ?? '',
      name: _nameController.text.trim(),
      stage: _selectedStage,
      ingredientData: _ingredientData,
      steps: nonEmptySteps,
      cookingTimeMinutes: _cookingTime,
      difficulty: _selectedDifficulty,
      imageUrl: imageUrl,
      storageInfo: _storageController.text.trim().isNotEmpty
          ? _storageController.text.trim()
          : null,
      tip: _tipController.text.trim().isNotEmpty
          ? _tipController.text.trim()
          : null,
    );

    bool success;
    if (_isEditing) {
      success = await recipeProvider.updateUserRecipe(widget.recipe!.id, newRecipe);
    } else {
      final id = await recipeProvider.addUserRecipe(newRecipe);
      success = id != null;
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? '레시피가 수정되었습니다.' : '레시피가 저장되었습니다.'),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _addIngredient() async {
    final recipeProvider = context.read<RecipeProvider>();
    final ingredients = recipeProvider.ingredients;

    final selected = await showDialog<Ingredient>(
      context: context,
      builder: (context) => IngredientPickerDialog(
        ingredients: ingredients,
        title: '재료 추가',
      ),
    );

    if (selected != null) {
      // 이미 추가된 재료인지 확인
      final exists = _ingredientData.any((d) => d.ingredientId == selected.id);
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 추가된 재료입니다.')),
          );
        }
        return;
      }

      setState(() {
        _ingredientData.add(
          RecipeIngredientData(ingredientId: selected.id, amount: 10),
        );
      });
    }
  }

  void _addStep() {
    setState(() {
      _steps.add('');
    });
  }

  void _removeStep(int index) {
    if (_steps.length > 1) {
      setState(() {
        _steps.removeAt(index);
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _imageService.pickImageFromGallery();
                if (image != null) {
                  setState(() => _selectedImage = image);
                }
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('카메라로 촬영'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _imageService.pickImageFromCamera();
                  if (image != null) {
                    setState(() => _selectedImage = image);
                  }
                },
              ),
            if (_selectedImage != null || _existingImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('이미지 삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _existingImageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '레시피 편집' : '새 레시피'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 레시피 이름
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '레시피 이름 *',
                hintText: '예: 당근 소고기죽',
                prefixIcon: Icon(Icons.restaurant),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '레시피 이름을 입력해주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 이미지 선택
            _buildSectionHeader('레시피 사진', Icons.image),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 24),

            // 단계 & 난이도
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<BabyFoodStage>(
                    value: _selectedStage,
                    decoration: const InputDecoration(
                      labelText: '단계',
                      prefixIcon: Icon(Icons.child_care),
                    ),
                    items: BabyFoodStage.values
                        .map((stage) => DropdownMenuItem(
                              value: stage,
                              child: Text(stage.shortName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedStage = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<Difficulty>(
                    value: _selectedDifficulty,
                    decoration: const InputDecoration(
                      labelText: '난이도',
                      prefixIcon: Icon(Icons.signal_cellular_alt),
                    ),
                    items: Difficulty.values
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d.displayName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedDifficulty = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 조리 시간
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('조리시간:'),
                Expanded(
                  child: Slider(
                    value: _cookingTime.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '$_cookingTime분',
                    onChanged: (value) {
                      setState(() => _cookingTime = value.toInt());
                    },
                  ),
                ),
                Text('$_cookingTime분',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),

            // 재료 섹션
            _buildSectionHeader('재료', Icons.shopping_basket),
            const SizedBox(height: 8),
            ..._ingredientData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final ingredient = recipeProvider.getIngredientById(data.ingredientId);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: ingredient != null
                      ? CircleAvatar(
                          backgroundColor: Colors.green.withOpacity(0.2),
                          child: const Icon(Icons.eco,
                              color: Colors.green, size: 20),
                        )
                      : null,
                  title: Text(ingredient?.name ?? data.ingredientId),
                  subtitle: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: () {
                          if (data.amount > 5) {
                            setState(() {
                              _ingredientData[index] =
                                  data.copyWith(amount: data.amount - 5);
                            });
                          }
                        },
                      ),
                      Text('${data.amount.toStringAsFixed(0)}g',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: () {
                          setState(() {
                            _ingredientData[index] =
                                data.copyWith(amount: data.amount + 5);
                          });
                        },
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _ingredientData.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add),
              label: const Text('재료 추가'),
            ),

            // 영양소 미리보기
            if (_ingredientData.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNutritionPreview(recipeProvider),
            ],
            const SizedBox(height: 24),

            // 조리법 섹션
            _buildSectionHeader('조리법', Icons.menu_book),
            const SizedBox(height: 8),
            ..._steps.asMap().entries.map((entry) {
              final index = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _steps[index],
                        decoration: InputDecoration(
                          hintText: '${index + 1}단계 조리법 입력',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 2,
                        onChanged: (value) => _steps[index] = value,
                      ),
                    ),
                    if (_steps.length > 1)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 20),
                        onPressed: () => _removeStep(index),
                      ),
                  ],
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _addStep,
              icon: const Icon(Icons.add),
              label: const Text('단계 추가'),
            ),
            const SizedBox(height: 24),

            // 팁 & 보관 정보
            _buildSectionHeader('추가 정보', Icons.info_outline),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tipController,
              decoration: const InputDecoration(
                labelText: '조리 팁 (선택)',
                hintText: '요리할 때 도움이 되는 팁을 적어주세요',
                prefixIcon: Icon(Icons.lightbulb_outline),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _storageController,
              decoration: const InputDecoration(
                labelText: '보관 정보 (선택)',
                hintText: '예: 냉장 2일, 냉동 2주',
                prefixIcon: Icon(Icons.kitchen),
              ),
            ),
            const SizedBox(height: 32),

            // 저장 버튼
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isEditing ? '레시피 수정' : '레시피 저장'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildNutritionPreview(RecipeProvider recipeProvider) {
    // 영양소 계산
    Nutrition total = Nutrition.empty;
    for (var data in _ingredientData) {
      final ingredient = recipeProvider.getIngredientById(data.ingredientId);
      if (ingredient != null) {
        total = total + ingredient.getNutritionForGrams(data.amount);
      }
    }

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, size: 18, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  '영양소 미리보기',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _nutritionChip('칼로리', '${total.calories.toStringAsFixed(0)}kcal'),
                _nutritionChip('단백질', '${total.protein.toStringAsFixed(1)}g'),
                _nutritionChip('탄수화물', '${total.carbohydrates.toStringAsFixed(1)}g'),
                _nutritionChip('지방', '${total.fat.toStringAsFixed(1)}g'),
                _nutritionChip('철분', '${total.iron.toStringAsFixed(1)}mg'),
                _nutritionChip('칼슘', '${total.calcium.toStringAsFixed(0)}mg'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutritionChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildImagePreview() {
    // 새로 선택한 이미지가 있으면 표시
    if (_selectedImage != null) {
      if (kIsWeb) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            _selectedImage!.path,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 180,
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_selectedImage!.path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 180,
          ),
        );
      }
    }

    // 기존 이미지가 있으면 표시
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      if (_imageService.isLocalFile(_existingImageUrl)) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_existingImageUrl!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 180,
            errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
          ),
        );
      } else if (_existingImageUrl!.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            _existingImageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 180,
            errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
          ),
        );
      }
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(
          '탭하여 사진 추가',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
