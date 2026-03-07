import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { message, memo, notice, cheer }

extension MessageTypeExtension on MessageType {
  String get displayName {
    switch (this) {
      case MessageType.message:
        return '메시지';
      case MessageType.memo:
        return '메모';
      case MessageType.notice:
        return '공지';
      case MessageType.cheer:
        return '응원';
    }
  }

  String get emoji {
    switch (this) {
      case MessageType.message:
        return '💬';
      case MessageType.memo:
        return '📝';
      case MessageType.notice:
        return '📢';
      case MessageType.cheer:
        return '🎉';
    }
  }
}

class FamilyMessage {
  final String id;
  final String familyId;
  final String userId;
  final String authorName;
  final String content;
  final MessageType type;
  final DateTime createdAt;

  const FamilyMessage({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'familyId': familyId,
        'userId': userId,
        'authorName': authorName,
        'content': content,
        'type': type.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory FamilyMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyMessage(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      userId: data['userId'] ?? '',
      authorName: data['authorName'] ?? '알 수 없음',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.message,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
