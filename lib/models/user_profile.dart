import 'package:cloud_firestore/cloud_firestore.dart';
import 'ingredient.dart';

enum BabyGender { male, female }

extension BabyGenderExtension on BabyGender {
  String get displayName {
    switch (this) {
      case BabyGender.male:
        return '남아';
      case BabyGender.female:
        return '여아';
    }
  }
}

class UserProfile {
  final String userId;
  final String email;
  final String? nickname;
  final String? babyName;
  final DateTime? babyBirthDate;
  final BabyGender? babyGender;
  final String? babyPhotoPath;
  final String? familyId;
  final String? partnerUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.userId,
    required this.email,
    this.nickname,
    this.babyName,
    this.babyBirthDate,
    this.babyGender,
    this.babyPhotoPath,
    this.familyId,
    this.partnerUserId,
    this.createdAt,
    this.updatedAt,
  });

  /// 아기 나이 (개월 수)
  int? get babyAgeMonths {
    if (babyBirthDate == null) return null;
    final now = DateTime.now();
    final months =
        (now.year - babyBirthDate!.year) * 12 + now.month - babyBirthDate!.month;
    if (now.day < babyBirthDate!.day) return months - 1;
    return months;
  }

  /// 아기 나이 기반 이유식 단계
  BabyFoodStage? get babyStage {
    final months = babyAgeMonths;
    if (months == null) return null;
    if (months <= 6) return BabyFoodStage.early;
    if (months <= 9) return BabyFoodStage.middle;
    return BabyFoodStage.late;
  }

  /// 아기 나이 표시 문자열
  String? get babyAgeText {
    final months = babyAgeMonths;
    if (months == null) return null;
    if (months < 1) return '신생아';
    if (months < 12) return '$months개월';
    final years = months ~/ 12;
    final remainMonths = months % 12;
    if (remainMonths == 0) return '$years세';
    return '$years세 $remainMonths개월';
  }

  /// 유효 familyId (없으면 본인 userId 폴백)
  String get effectiveFamilyId => familyId ?? userId;

  UserProfile copyWith({
    String? userId,
    String? email,
    String? nickname,
    String? babyName,
    DateTime? babyBirthDate,
    BabyGender? babyGender,
    String? babyPhotoPath,
    String? familyId,
    String? partnerUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      babyName: babyName ?? this.babyName,
      babyBirthDate: babyBirthDate ?? this.babyBirthDate,
      babyGender: babyGender ?? this.babyGender,
      babyPhotoPath: babyPhotoPath ?? this.babyPhotoPath,
      familyId: familyId ?? this.familyId,
      partnerUserId: partnerUserId ?? this.partnerUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'nickname': nickname,
      'babyName': babyName,
      if (babyBirthDate != null)
        'babyBirthDate': Timestamp.fromDate(babyBirthDate!),
      if (babyGender != null) 'babyGender': babyGender!.name,
      'babyPhotoPath': babyPhotoPath,
      if (familyId != null) 'familyId': familyId,
      if (partnerUserId != null) 'partnerUserId': partnerUserId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      userId: doc.id,
      email: data['email'] ?? '',
      nickname: data['nickname'],
      babyName: data['babyName'],
      babyBirthDate: (data['babyBirthDate'] as Timestamp?)?.toDate(),
      babyGender: data['babyGender'] != null
          ? BabyGender.values.firstWhere(
              (g) => g.name == data['babyGender'],
              orElse: () => BabyGender.male,
            )
          : null,
      babyPhotoPath: data['babyPhotoPath'],
      familyId: data['familyId'],
      partnerUserId: data['partnerUserId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
