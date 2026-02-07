import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe.dart';

enum ShareStatus { pending, accepted, declined }

class SharedRecipe {
  final String id;
  final String senderUserId;
  final String senderEmail;
  final String receiverEmail;
  final Map<String, dynamic> recipeData;
  final ShareStatus status;
  final DateTime? createdAt;

  const SharedRecipe({
    required this.id,
    required this.senderUserId,
    required this.senderEmail,
    required this.receiverEmail,
    required this.recipeData,
    this.status = ShareStatus.pending,
    this.createdAt,
  });

  Recipe toRecipe() => Recipe.fromJson(recipeData);

  String get recipeName => recipeData['name'] ?? '';

  Map<String, dynamic> toJson() {
    return {
      'senderUserId': senderUserId,
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'recipeData': recipeData,
      'status': status.name,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  factory SharedRecipe.fromJson(Map<String, dynamic> json) {
    return SharedRecipe(
      id: json['id'] ?? '',
      senderUserId: json['senderUserId'] ?? '',
      senderEmail: json['senderEmail'] ?? '',
      receiverEmail: json['receiverEmail'] ?? '',
      recipeData: Map<String, dynamic>.from(json['recipeData'] ?? {}),
      status: ShareStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ShareStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory SharedRecipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SharedRecipe.fromJson({...data, 'id': doc.id});
  }
}
