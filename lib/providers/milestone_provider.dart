import 'package:flutter/foundation.dart';
import '../models/baby_milestone.dart';
import '../services/firebase_service.dart';

class MilestoneProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;

  MilestoneProvider(this._firebaseService);

  Map<MilestoneType, BabyMilestone> _milestones = {};
  bool _isLoading = false;
  String? _familyId;

  Map<MilestoneType, BabyMilestone> get milestones => _milestones;
  bool get isLoading => _isLoading;

  List<BabyMilestone> get completedMilestones {
    final list = _milestones.values.toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  BabyMilestone? getMilestone(MilestoneType type) => _milestones[type];

  Future<void> load(String familyId) async {
    if (_isLoading) return;
    _familyId = familyId;
    _isLoading = true;
    notifyListeners();
    try {
      _milestones = await _firebaseService.getMilestones(familyId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save(BabyMilestone milestone) async {
    if (_familyId == null) return;
    await _firebaseService.saveMilestone(_familyId!, milestone);
    _milestones[milestone.type] = milestone;
    notifyListeners();
  }

  Future<void> delete(MilestoneType type) async {
    if (_familyId == null) return;
    await _firebaseService.deleteMilestone(_familyId!, type);
    _milestones.remove(type);
    notifyListeners();
  }

  void clear() {
    _milestones = {};
    _familyId = null;
    notifyListeners();
  }
}
