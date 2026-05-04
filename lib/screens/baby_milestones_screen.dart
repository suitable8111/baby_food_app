import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/baby_milestone.dart';
import '../providers/auth_provider.dart';
import '../providers/milestone_provider.dart';

class BabyMilestonesScreen extends StatefulWidget {
  const BabyMilestonesScreen({super.key});

  @override
  State<BabyMilestonesScreen> createState() => _BabyMilestonesScreenState();
}

class _BabyMilestonesScreenState extends State<BabyMilestonesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final familyId = auth.userProfile?.effectiveFamilyId ?? auth.userId;
    if (familyId != null) {
      await context.read<MilestoneProvider>().load(familyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<MilestoneProvider>();
    final babyName = auth.userProfile?.babyName ?? '우리 아이';
    final birthDate = auth.userProfile?.babyBirthDate;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF6),
      appBar: AppBar(
        title: Text('$babyName 첫순간'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D2D2D),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(babyName),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final type = MilestoneType.values[i];
                        final milestone = provider.getMilestone(type);
                        return _MilestoneCard(
                          type: type,
                          milestone: milestone,
                          birthDate: birthDate,
                          onTap: () => _showEditSheet(type, milestone),
                        );
                      },
                      childCount: MilestoneType.values.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.25,
                    ),
                  ),
                ),
                if (provider.completedMilestones.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildTimeline(provider.completedMilestones, birthDate),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildHeader(String babyName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB6C1), Color(0xFFFFD6A0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$babyName의 첫순간',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    '소중한 성장 이정표를 기록해요',
                    style: TextStyle(fontSize: 12, color: Color(0xFF555555)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(List<BabyMilestone> milestones, DateTime? birthDate) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC407A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFFEC407A), size: 15),
                ),
                const SizedBox(width: 8),
                const Text(
                  '성장 타임라인',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(milestones.length, (i) {
            final ms = milestones[i];
            final isLast = i == milestones.length - 1;
            return _TimelineItem(
              milestone: ms,
              birthDate: birthDate,
              isLast: isLast,
              onEdit: () => _showEditSheet(ms.type, ms),
              onDelete: () => _confirmDelete(ms.type),
            );
          }),
        ],
      ),
    );
  }

  void _showEditSheet(MilestoneType type, BabyMilestone? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MilestoneEditSheet(
        type: type,
        existing: existing,
        onSave: (milestone) async {
          await context.read<MilestoneProvider>().save(milestone);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${type.displayName} 기록을 저장했어요 🎉')),
            );
          }
        },
        onDelete: existing != null ? () => _confirmDelete(type) : null,
      ),
    );
  }

  Future<void> _confirmDelete(MilestoneType type) async {
    Navigator.of(context).pop();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 삭제'),
        content: Text('${type.displayName} 기록을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<MilestoneProvider>().delete(type);
    }
  }
}

// ====== 마일스톤 카드 ======
class _MilestoneCard extends StatelessWidget {
  final MilestoneType type;
  final BabyMilestone? milestone;
  final DateTime? birthDate;
  final VoidCallback onTap;

  const _MilestoneCard({
    required this.type,
    required this.milestone,
    required this.birthDate,
    required this.onTap,
  });

  String _ageText(DateTime date) {
    if (birthDate == null) return '';
    final days = date.difference(birthDate!).inDays;
    if (days < 0) return '';
    if (days < 30) return '$days일';
    final months = days ~/ 30;
    final remDays = days % 30;
    if (remDays == 0) return '$months개월';
    return '$months개월 $remDays일';
  }

  @override
  Widget build(BuildContext context) {
    final done = milestone != null;
    final color = type.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: done ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: done ? color.withValues(alpha: 0.4) : Colors.grey.shade200,
            width: done ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: done
                        ? color.withValues(alpha: 0.2)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(type.emoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const Spacer(),
                if (done)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '완료',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  )
                else
                  Icon(Icons.add_circle_outline_rounded,
                      size: 18, color: Colors.grey.shade400),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: done ? color.withValues(alpha: 0.85) : const Color(0xFF2D2D2D),
                  ),
                ),
                if (done) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(milestone!.date),
                    style: TextStyle(
                        fontSize: 11,
                        color: color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500),
                  ),
                  if (_ageText(milestone!.date).isNotEmpty)
                    Text(
                      _ageText(milestone!.date),
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                    ),
                ] else
                  Text(
                    type.description,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

// ====== 타임라인 아이템 ======
class _TimelineItem extends StatelessWidget {
  final BabyMilestone milestone;
  final DateTime? birthDate;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TimelineItem({
    required this.milestone,
    required this.birthDate,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
  });

  String _ageText() {
    if (birthDate == null) return '';
    final days = milestone.date.difference(birthDate!).inDays;
    if (days < 0) return '';
    if (days < 30) return '생후 $days일';
    final months = days ~/ 30;
    final remDays = days % 30;
    if (remDays == 0) return '생후 $months개월';
    return '생후 $months개월 $remDays일';
  }

  @override
  Widget build(BuildContext context) {
    final type = milestone.type;
    final color = type.color;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임라인 선 + 아이콘
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: Text(type.emoji, style: const TextStyle(fontSize: 17)),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [color.withValues(alpha: 0.4), Colors.grey.shade200],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // 내용 카드
          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: color.withValues(alpha: 0.25), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: color.withValues(alpha: 0.9),
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_horiz_rounded,
                              size: 18, color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('수정')),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('삭제',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                          onSelected: (v) {
                            if (v == 'edit') onEdit();
                            if (v == 'delete') onDelete();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(milestone.date),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        if (_ageText().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _ageText(),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: color.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (milestone.memo != null &&
                        milestone.memo!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        milestone.memo!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

// ====== 편집 바텀시트 ======
class _MilestoneEditSheet extends StatefulWidget {
  final MilestoneType type;
  final BabyMilestone? existing;
  final Future<void> Function(BabyMilestone) onSave;
  final VoidCallback? onDelete;

  const _MilestoneEditSheet({
    required this.type,
    required this.existing,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_MilestoneEditSheet> createState() => _MilestoneEditSheetState();
}

class _MilestoneEditSheetState extends State<_MilestoneEditSheet> {
  late DateTime _selectedDate;
  late TextEditingController _memoCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.existing?.date ?? DateTime.now();
    _memoCtrl = TextEditingController(text: widget.existing?.memo ?? '');
  }

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(BabyMilestone(
        type: widget.type,
        date: _selectedDate,
        memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      ));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.type.color;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(widget.type.emoji,
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.type.displayName,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    widget.type.description,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          // 날짜 선택
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: color, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _formatDate(_selectedDate),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.9),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.grey.shade400, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 메모
          TextField(
            controller: _memoCtrl,
            decoration: InputDecoration(
              hintText: '한 줄 메모 (선택)',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.edit_note_rounded,
                  color: Colors.grey.shade400, size: 20),
            ),
            maxLines: 2,
            maxLength: 100,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.onDelete != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: Colors.red),
                    label: const Text('삭제',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              if (widget.onDelete != null) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('저장',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}년 ${d.month}월 ${d.day}일';
}
