import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../models/ingredient.dart';
import '../providers/auth_provider.dart';
import '../services/image_service.dart';
import 'family_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _babyNameController = TextEditingController();
  final _babyWeightController = TextEditingController();

  DateTime? _babyBirthDate;
  BabyGender? _babyGender;
  String? _babyPhotoPath;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

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
      if (profile.babyWeightKg != null) {
        _babyWeightController.text = profile.babyWeightKg!.toString();
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _babyNameController.dispose();
    _babyWeightController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final imageService = ImageService();
    final userId = context.read<AuthProvider>().userId;
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Color(0xFF66BB6A)),
                ),
                title: const Text('갤러리에서 선택'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Color(0xFF42A5F5)),
                ),
                title: const Text('카메라로 촬영'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              if (_babyPhotoPath != null)
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE57373).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_rounded,
                        color: Color(0xFFE57373)),
                  ),
                  title: const Text('사진 삭제',
                      style: TextStyle(color: Color(0xFFE57373))),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
            ],
          ),
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

    if (xFile != null && userId != null) {
      setState(() => _isUploadingPhoto = true);
      final url = await imageService.uploadProfilePhoto(userId, xFile);
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
          if (url != null) _babyPhotoPath = url;
        });
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
      babyWeightKg: double.tryParse(_babyWeightController.text.trim()),
      familyId: currentProfile?.familyId,
      partnerUserId: currentProfile?.partnerUserId,
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
        return const Color(0xFF66BB6A);
      case BabyFoodStage.middle:
        return const Color(0xFFFFA726);
      case BabyFoodStage.late:
        return const Color(0xFF7E57C2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _isSaving || _isUploadingPhoto ? null : _saveProfile,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: _isSaving || _isUploadingPhoto
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('저장', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 프로필 사진 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isUploadingPhoto ? null : _pickPhoto,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF0F4EE),
                              border: Border.all(
                                  color: const Color(0xFFE0E8DC), width: 3),
                              image: _buildPhotoDecoration(),
                            ),
                            child: _isUploadingPhoto
                                ? const CircularProgressIndicator(strokeWidth: 2)
                                : _babyPhotoPath == null
                                    ? const Icon(Icons.child_care_rounded,
                                        size: 48, color: Color(0xFFB0C4A8))
                                    : null,
                          ),
                          if (!_isUploadingPhoto)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF66BB6A),
                                      Color(0xFF43A047)
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      authProvider.userEmail ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    // 이유식 단계 표시
                    if (_babyBirthDate != null) ...[
                      const SizedBox(height: 16),
                      _buildStageInfo(),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 가족 연동 상태 카드
              _buildFamilyCard(authProvider),

              const SizedBox(height: 16),

              // 정보 입력 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '기본 정보',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 별칭
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: '별칭 (닉네임)',
                        hintText: '표시할 이름을 입력하세요',
                        prefixIcon:
                            Icon(Icons.person_rounded, color: Color(0xFF66BB6A)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 아기 이름
                    TextFormField(
                      controller: _babyNameController,
                      decoration: const InputDecoration(
                        labelText: '아기 이름',
                        hintText: '아기 이름을 입력하세요',
                        prefixIcon: Icon(Icons.child_care_rounded,
                            color: Color(0xFFFFA726)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 아기 몸무게
                    TextFormField(
                      controller: _babyWeightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '아기 몸무게',
                        hintText: '예: 7.5',
                        prefixIcon: Icon(Icons.monitor_weight_outlined,
                            color: Color(0xFF26A69A)),
                        suffixText: 'kg',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final val = double.tryParse(v.trim());
                        if (val == null || val <= 0 || val > 30) {
                          return '올바른 몸무게를 입력하세요 (0~30 kg)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // 아기 성별
                    _buildGenderSelector(),

                    const SizedBox(height: 20),

                    // 아기 생년월일
                    _buildBirthDateSelector(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DecorationImage? _buildPhotoDecoration() {
    if (_babyPhotoPath == null) return null;
    if (!kIsWeb && ImageService().isLocalFile(_babyPhotoPath!)) {
      final file = File(_babyPhotoPath!);
      if (file.existsSync()) {
        return DecorationImage(image: FileImage(file), fit: BoxFit.cover);
      }
    }
    if (_babyPhotoPath!.startsWith('http')) {
      return DecorationImage(
          image: NetworkImage(_babyPhotoPath!), fit: BoxFit.cover);
    }
    return null;
  }

  Widget _buildFamilyCard(AuthProvider authProvider) {
    final hasPartner = authProvider.hasPartner;
    final partner = authProvider.partnerProfile;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FamilyScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasPartner
                    ? const Color(0xFFEC407A).withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasPartner ? Icons.favorite_rounded : Icons.people_outline_rounded,
                color: hasPartner ? const Color(0xFFEC407A) : Colors.grey.shade400,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '가족 연동',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasPartner
                        ? '${partner?.nickname ?? partner?.email ?? "파트너"}와 연동됨'
                        : '파트너를 초대하세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cake_rounded, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            ageText,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '이유식 ${stage.shortName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
        Text(
          '아기 성별',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GenderOption(
                icon: Icons.boy_rounded,
                label: '남아',
                color: const Color(0xFF42A5F5),
                isSelected: _babyGender == BabyGender.male,
                onTap: () => setState(() => _babyGender =
                    _babyGender == BabyGender.male ? null : BabyGender.male),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenderOption(
                icon: Icons.girl_rounded,
                label: '여아',
                color: const Color(0xFFEC407A),
                isSelected: _babyGender == BabyGender.female,
                onTap: () => setState(() => _babyGender =
                    _babyGender == BabyGender.female
                        ? null
                        : BabyGender.female),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBirthDateSelector() {
    return InkWell(
      onTap: _pickBirthDate,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '아기 생년월일',
          prefixIcon:
              Icon(Icons.calendar_today_rounded, color: Color(0xFF7E57C2)),
          suffixIcon: Icon(Icons.arrow_drop_down_rounded),
        ),
        child: Text(
          _babyBirthDate != null
              ? '${_babyBirthDate!.year}년 ${_babyBirthDate!.month}월 ${_babyBirthDate!.day}일'
              : '생년월일을 선택하세요',
          style: TextStyle(
            color: _babyBirthDate != null
                ? const Color(0xFF2D2D2D)
                : Colors.grey.shade400,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFFF8F8F8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey.shade400, size: 22),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade500,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
