import 'package:cloud_firestore/cloud_firestore.dart';

enum InviteStatus { pending, accepted, declined }

class FamilyInvite {
  final String id;
  final String senderUserId;
  final String senderEmail;
  final String? senderNickname;
  final String receiverEmail;
  final InviteStatus status;
  final DateTime? createdAt;

  const FamilyInvite({
    required this.id,
    required this.senderUserId,
    required this.senderEmail,
    this.senderNickname,
    required this.receiverEmail,
    this.status = InviteStatus.pending,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'senderUserId': senderUserId,
      'senderEmail': senderEmail,
      'senderNickname': senderNickname,
      'receiverEmail': receiverEmail,
      'status': status.name,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  factory FamilyInvite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyInvite(
      id: doc.id,
      senderUserId: data['senderUserId'] ?? '',
      senderEmail: data['senderEmail'] ?? '',
      senderNickname: data['senderNickname'],
      receiverEmail: data['receiverEmail'] ?? '',
      status: InviteStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => InviteStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
