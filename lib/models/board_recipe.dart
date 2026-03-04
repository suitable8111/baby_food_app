import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe.dart';

class BoardRecipe {
  final String id;
  final Map<String, dynamic> recipeData;
  final String authorUserId;
  final String authorEmail;
  final String? authorDisplayName;
  final String? photoUrl;
  final DateTime? publishedAt;
  final DateTime? updatedAt;

  const BoardRecipe({
    required this.id,
    required this.recipeData,
    required this.authorUserId,
    required this.authorEmail,
    this.authorDisplayName,
    this.photoUrl,
    this.publishedAt,
    this.updatedAt,
  });

  Recipe toRecipe() => Recipe.fromJson(recipeData);

  String get recipeName => recipeData['name'] ?? '';

  Map<String, dynamic> toJson() {
    return {
      'recipeData': recipeData,
      'authorUserId': authorUserId,
      'authorEmail': authorEmail,
      'authorDisplayName': authorDisplayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'publishedAt':
          publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory BoardRecipe.fromJson(Map<String, dynamic> json) {
    return BoardRecipe(
      id: json['id'] ?? '',
      recipeData: Map<String, dynamic>.from(json['recipeData'] ?? {}),
      authorUserId: json['authorUserId'] ?? '',
      authorEmail: json['authorEmail'] ?? '',
      authorDisplayName: json['authorDisplayName'],
      photoUrl: json['photoUrl'],
      publishedAt: json['publishedAt'] != null
          ? (json['publishedAt'] as Timestamp).toDate()
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory BoardRecipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BoardRecipe.fromJson({...data, 'id': doc.id});
  }
}
