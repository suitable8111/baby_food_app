import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 레시피 이미지 관리 서비스
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// 레시피 이미지 저장 디렉토리 경로
  Future<String> get _recipeImageDir async {
    if (kIsWeb) {
      // 웹에서는 로컬 파일 저장 불가
      return '';
    }
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(path.join(appDir.path, 'recipe_images'));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir.path;
  }

  /// 갤러리에서 이미지 선택
  Future<XFile?> pickImageFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('이미지 선택 실패: $e');
      return null;
    }
  }

  /// 카메라로 이미지 촬영
  Future<XFile?> pickImageFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('카메라 촬영 실패: $e');
      return null;
    }
  }

  /// 이미지를 로컬 저장소에 저장하고 경로 반환
  Future<String?> saveRecipeImage(XFile imageFile, String recipeName) async {
    if (kIsWeb) {
      // 웹에서는 XFile의 path를 그대로 사용 (blob URL)
      return imageFile.path;
    }

    try {
      final dir = await _recipeImageDir;
      final fileName = '${_sanitizeFileName(recipeName)}_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedPath = path.join(dir, fileName);

      final bytes = await imageFile.readAsBytes();
      final file = File(savedPath);
      await file.writeAsBytes(bytes);

      return savedPath;
    } catch (e) {
      debugPrint('이미지 저장 실패: $e');
      return null;
    }
  }

  /// 로컬 이미지 삭제
  Future<bool> deleteRecipeImage(String imagePath) async {
    if (kIsWeb || imagePath.isEmpty) return true;

    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      debugPrint('이미지 삭제 실패: $e');
      return false;
    }
  }

  /// 이미지 경로가 로컬 파일인지 확인
  bool isLocalFile(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;
    if (kIsWeb) return false;
    return !imagePath.startsWith('http') && !imagePath.startsWith('assets/');
  }

  /// 이미지 경로가 asset 파일인지 확인
  bool isAssetFile(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;
    return imagePath.startsWith('assets/');
  }

  /// 파일명에서 특수문자 제거
  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\s가-힣]'), '').replaceAll(' ', '_');
  }
}
