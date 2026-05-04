import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum MilestoneType {
  headControl,  // 목 가누기
  rolling,      // 뒤집기
  armyCrawl,    // 배밀이
  sittingAlone, // 혼자앉기
  crawling,     // 기어가기
  firstSteps,   // 첫걸음마
}

extension MilestoneTypeExtension on MilestoneType {
  String get displayName {
    switch (this) {
      case MilestoneType.headControl:
        return '목 가누기';
      case MilestoneType.rolling:
        return '뒤집기';
      case MilestoneType.armyCrawl:
        return '배밀이';
      case MilestoneType.sittingAlone:
        return '혼자앉기';
      case MilestoneType.crawling:
        return '기어가기';
      case MilestoneType.firstSteps:
        return '첫걸음마';
    }
  }

  String get emoji {
    switch (this) {
      case MilestoneType.headControl:
        return '🍼';
      case MilestoneType.rolling:
        return '🔄';
      case MilestoneType.armyCrawl:
        return '🐛';
      case MilestoneType.sittingAlone:
        return '🪑';
      case MilestoneType.crawling:
        return '🐣';
      case MilestoneType.firstSteps:
        return '👶';
    }
  }

  String get description {
    switch (this) {
      case MilestoneType.headControl:
        return '고개를 스스로 들어요';
      case MilestoneType.rolling:
        return '몸을 뒤집어요';
      case MilestoneType.armyCrawl:
        return '배를 바닥에 대고 기어가요';
      case MilestoneType.sittingAlone:
        return '혼자 앉아있어요';
      case MilestoneType.crawling:
        return '무릎으로 기어가요';
      case MilestoneType.firstSteps:
        return '첫 발을 내딛어요';
    }
  }

  Color get color {
    switch (this) {
      case MilestoneType.headControl:
        return const Color(0xFF4FC3F7);
      case MilestoneType.rolling:
        return const Color(0xFFFFB74D);
      case MilestoneType.armyCrawl:
        return const Color(0xFF81C784);
      case MilestoneType.sittingAlone:
        return const Color(0xFFBA68C8);
      case MilestoneType.crawling:
        return const Color(0xFF4DB6AC);
      case MilestoneType.firstSteps:
        return const Color(0xFFFF8A65);
    }
  }

  IconData get icon {
    switch (this) {
      case MilestoneType.headControl:
        return Icons.child_care_rounded;
      case MilestoneType.rolling:
        return Icons.rotate_right_rounded;
      case MilestoneType.armyCrawl:
        return Icons.directions_run_rounded;
      case MilestoneType.sittingAlone:
        return Icons.accessibility_new_rounded;
      case MilestoneType.crawling:
        return Icons.airline_seat_flat_rounded;
      case MilestoneType.firstSteps:
        return Icons.directions_walk_rounded;
    }
  }

  // 일반적인 발달 순서 (정렬용)
  int get typicalOrder {
    switch (this) {
      case MilestoneType.headControl:
        return 0;
      case MilestoneType.rolling:
        return 1;
      case MilestoneType.armyCrawl:
        return 2;
      case MilestoneType.sittingAlone:
        return 3;
      case MilestoneType.crawling:
        return 4;
      case MilestoneType.firstSteps:
        return 5;
    }
  }
}

class BabyMilestone {
  final MilestoneType type;
  final DateTime date;
  final String? memo;

  const BabyMilestone({
    required this.type,
    required this.date,
    this.memo,
  });

  Map<String, dynamic> toJson() => {
        'date': Timestamp.fromDate(date),
        'memo': memo,
      };

  factory BabyMilestone.fromJson(MilestoneType type, Map<String, dynamic> json) {
    return BabyMilestone(
      type: type,
      date: (json['date'] as Timestamp).toDate(),
      memo: json['memo'] as String?,
    );
  }
}
