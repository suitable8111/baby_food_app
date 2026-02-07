import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../models/ingredient.dart';
import '../providers/auth_provider.dart';
import '../services/image_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _babyNameController = TextEditingController();

  DateTime? _babyBirthDate;
  BabyGender? _babyGender;
  String? _babyPhotoPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final authProvider = context.read<AuthProvider>();
    final profile = authProvider.userProfile;
    if (profile != null) {
      _nicknameController.text = profile.nickname ?? '';
      _babyNameController.text = profile.babyName ?? '';
      _babyBirthDate = profile.babyBirthDate;
      _babyGender = profile.babyGender;
      _babyPhotoPath = profile.babyPhotoPath;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _babyNameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final imageService = ImageService();
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            if (_babyPhotoPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title:
                    const Text('사진 삭제', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );

    if (source == null) return;

    if (source == 'delete') {
      setState(() => _babyPhotoPath = null);
      return;
    }

    final xFile = source == 'gallery'
        ? await imageService.pickImageFromGallery()
        : await imageService.pickImageFromCamera();

    if (xFile != null) {
      final savedPath =
          await imageService.saveRecipeImage(xFile, 'baby_profile');
      if (savedPath != null) {
        setState(() => _babyPhotoPath = savedPath);
      }
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _babyBirthDate ?? now.subtract(const Duration(days: 180)),
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      helpText: '아기 생년월일 선택',
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() => _babyBirthDate = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final currentProfile = authProvider.userProfile;

    final updatedProfile = UserProfile(
      userId: currentProfile?.userId ?? authProvider.userId ?? '',
      email: authProvider.userEmail ?? '',
      nickname: _nicknameController.text.trim().isEmpty
          ? null
          : _nicknameController.text.trim(),
      babyName: _babyNameController.text.trim().isEmpty
          ? null
          : _babyNameController.text.trim(),
      babyBirthDate: _babyBirthDate,
      babyGender: _babyGender,
      babyPhotoPath: _babyPhotoPath,
      createdAt: currentProfile?.createdAt,
    );

    final success = await authProvider.updateUserProfile(updatedProfile);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '프로필이 저장되었습니다!' : '프로필 저장에 실패했습니다.'),
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  int? get _babyAgeMonths {
    if (_babyBirthDate == null) return null;
    final now = DateTime.now();
    final months =
        (now.year - _babyBirthDate!.year) * 12 + now.month - _babyBirthDate!.month;
    if (now.day < _babyBirthDate!.day) return months - 1;
    return months;
  }

  BabyFoodStage? get _babyStage {
    final months = _babyAgeMonths;
    if (months == null) return null;
    if (months <= 6) return BabyFoodStage.early;
    if (months <= 9) return BabyFoodStage.middle;
    return BabyFoodStage.late;
  }

  Color _getStageColor(BabyFoodStage stage) {
    switch (stage) {
      case BabyFoodStage.early:
        return Colors.green;
      case BabyFoodStage.middle:
        return Colors.orange;
      case BabyFoodStage.late:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 아기 사진
              GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _buildPhotoImage(),
                      child: _babyPhotoPath == null
                          ? Icon(Icons.child_care,
                              size: 60, color: Colors.grey.shade400)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 이유식 단계 표시
              if (_babyBirthDate != null) ...[
                _buildStageInfo(),
                const SizedBox(height: 24),
              ],

              // 계정 이메일 (읽기 전용)
              TextFormField(
                initialValue: authProvider.userEmail ?? '',
                decoration: const InputDecoration(
                  labelText: '계정 이메일',
                  prefixIcon: Icon(Icons.email),
                  filled: true,
                ),
                readOnly: true,
                enabled: false,
              ),

              const SizedBox(height: 16),

              // 별칭
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '별칭 (닉네임)',
                  hintText: '표시할 이름을 입력하세요',
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 16),

              // 아기 이름
              TextFormField(
                controller: _babyNameController,
                decoration: const InputDecoration(
                  labelText: '아기 이름',
                  hintText: '아기 이름을 입력하세요',
                  prefixIcon: Icon(Icons.child_care),
                ),
              ),

              const SizedBox(height: 16),

              // 아기 성별
              _buildGenderSelector(),

              const SizedBox(height: 16),

              // 아기 생년월일
              _buildBirthDateSelector(),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _buildPhotoImage() {
    if (_babyPhotoPath == null) return null;
    if (!kIsWeb && ImageService().isLocalFile(_babyPhotoPath!)) {
      final file = File(_babyPhotoPath!);
      if (file.existsSync()) return FileImage(file);
    }
    if (_babyPhotoPath!.startsWith('http')) {
      return NetworkImage(_babyPhotoPath!);
    }
    return null;
  }

  Widget _buildStageInfo() {
    final months = _babyAgeMonths;
    final stage = _babyStage;
    if (months == null || stage == null) return const SizedBox.shrink();

    final color = _getStageColor(stage);
    String ageText;
    if (months < 1) {
      ageText = '신생아';
    } else if (months < 12) {
      ageText = '$months개월';
    } else {
      final years = months ~/ 12;
      final remainMonths = months % 12;
      ageText = remainMonths == 0 ? '$years세' : '$years세 $remainMonths개월';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cake, color: color, size: 22),
          const SizedBox(width: 8),
          Text(
            ageText,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '이유식 ${stage.shortName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            '아기 성별',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        SegmentedButton<BabyGender?>(
          segments: const [
            ButtonSegment(
              value: BabyGender.male,
              label: Text('남아'),
              icon: Icon(Icons.boy),
            ),
            ButtonSegment(
              value: BabyGender.female,
              label: Text('여아'),
              icon: Icon(Icons.girl),
            ),
          ],
          selected: _babyGender != null ? {_babyGender} : {},
          emptySelectionAllowed: true,
          onSelectionChanged: (selected) {
            setState(() {
              _babyGender = selected.isEmpty ? null : selected.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBirthDateSelector() {
    return InkWell(
      onTap: _pickBirthDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '아기 생년월일',
          prefixIcon: Icon(Icons.calendar_today),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          _babyBirthDate != null
              ? '${_babyBirthDate!.year}년 ${_babyBirthDate!.month}월 ${_babyBirthDate!.day}일'
              : '생년월일을 선택하세요',
          style: TextStyle(
            color:
                _babyBirthDate != null ? null : Colors.grey.shade500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
