import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/family_invite.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _emailController = TextEditingController();
  List<FamilyInvite> _pendingInvites = [];
  List<FamilyInvite> _sentInvites = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInvites());
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadInvites() async {
    final authProvider = context.read<AuthProvider>();
    final firebaseService = context.read<FirebaseService>();
    if (!authProvider.isAuthenticated) return;

    setState(() => _isLoading = true);

    try {
      final email = authProvider.userEmail ?? '';
      final userId = authProvider.userId ?? '';

      final results = await Future.wait([
        firebaseService.getPendingFamilyInvites(email),
        firebaseService.getSentFamilyInvites(userId),
      ]);

      if (mounted) {
        setState(() {
          _pendingInvites = results[0];
          _sentInvites = results[1];
        });
      }
    } catch (e) {
      debugPrint('초대 로드 실패: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _sendInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final firebaseService = context.read<FirebaseService>();

    if (email == authProvider.userEmail) {
      _showSnackBar('자신에게는 초대를 보낼 수 없습니다.');
      return;
    }

    if (authProvider.hasPartner) {
      _showSnackBar('이미 파트너와 연동되어 있습니다.');
      return;
    }

    setState(() => _isSending = true);

    try {
      final nickname = authProvider.displayName;
      await firebaseService.sendFamilyInvite(
        receiverEmail: email,
        senderNickname: nickname,
      );

      _emailController.clear();
      _showSnackBar('초대를 보냈습니다.');
      await _loadInvites();
    } catch (e) {
      _showSnackBar('초대 보내기에 실패했습니다.');
    }

    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _acceptInvite(String inviteId) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.linkPartner(inviteId);
    if (!mounted) return;
    if (success) {
      _showSnackBar('파트너와 연동되었습니다!');
      await _loadInvites();
    } else {
      _showSnackBar('연동에 실패했습니다.');
    }
  }

  Future<void> _declineInvite(String inviteId) async {
    final firebaseService = context.read<FirebaseService>();
    await firebaseService.declineFamilyInvite(inviteId);
    if (!mounted) return;
    _showSnackBar('초대를 거절했습니다.');
    await _loadInvites();
  }

  Future<void> _unlinkPartner() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('연동 해제'),
        content: const Text('파트너와의 연동을 해제하시겠습니까?\n해제 후에는 각자의 일지만 보입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('해제', style: TextStyle(color: Color(0xFFE57373))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.unlinkPartner();
    if (mounted) {
      _showSnackBar(success ? '연동이 해제되었습니다.' : '연동 해제에 실패했습니다.');
      if (success) setState(() {});
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF6),
      appBar: AppBar(title: const Text('가족 연동')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInvites,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 연동 상태 카드
                  _buildStatusCard(authProvider),
                  const SizedBox(height: 20),

                  // 연동되지 않은 경우: 초대 보내기 + 받은 초대
                  if (!authProvider.hasPartner) ...[
                    _buildSendInviteCard(),
                    const SizedBox(height: 16),
                    if (_pendingInvites.isNotEmpty) ...[
                      _buildSectionTitle('받은 초대'),
                      const SizedBox(height: 8),
                      ..._pendingInvites.map(_buildPendingInviteCard),
                    ],
                    if (_sentInvites.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSectionTitle('보낸 초대'),
                      const SizedBox(height: 8),
                      ..._sentInvites.map(_buildSentInviteCard),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(AuthProvider authProvider) {
    final hasPartner = authProvider.hasPartner;
    final partner = authProvider.partnerProfile;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: hasPartner
                  ? const Color(0xFF6BBF59).withValues(alpha: 0.12)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasPartner ? Icons.favorite_rounded : Icons.people_outline_rounded,
              size: 32,
              color: hasPartner ? const Color(0xFF6BBF59) : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasPartner ? '파트너와 연동됨' : '연동된 파트너 없음',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: hasPartner ? const Color(0xFF2D2D2D) : Colors.grey.shade500,
            ),
          ),
          if (hasPartner && partner != null) ...[
            const SizedBox(height: 8),
            Text(
              partner.nickname ?? partner.email,
              style: const TextStyle(fontSize: 15, color: Color(0xFF555555)),
            ),
            Text(
              partner.email,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _unlinkPartner,
              icon: const Icon(Icons.link_off_rounded, size: 18),
              label: const Text('연동 해제'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE57373),
                side: const BorderSide(color: Color(0xFFE57373)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              '파트너를 초대하여 이유식 일지를 함께 기록하세요',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSendInviteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '파트너 초대',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '파트너의 이메일을 입력하여 초대를 보내세요',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: '파트너 이메일',
              prefixIcon: const Icon(Icons.email_rounded, color: Color(0xFF6BBF59)),
              filled: true,
              fillColor: const Color(0xFFF8FAF6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSending ? null : _sendInvite,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: const Text('초대 보내기', style: TextStyle(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6BBF59),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2D2D2D),
        ),
      ),
    );
  }

  Widget _buildPendingInviteCard(FamilyInvite invite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6BBF59).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF6BBF59).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_rounded, color: Color(0xFF6BBF59), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.senderNickname ?? invite.senderEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                Text(
                  invite.senderEmail,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _declineInvite(invite.id),
            icon: const Icon(Icons.close_rounded, color: Color(0xFFE57373)),
            tooltip: '거절',
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: () => _acceptInvite(invite.id),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6BBF59),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('수락', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSentInviteCard(FamilyInvite invite) {
    final statusText = switch (invite.status) {
      InviteStatus.pending => '대기중',
      InviteStatus.accepted => '수락됨',
      InviteStatus.declined => '거절됨',
    };
    final statusColor = switch (invite.status) {
      InviteStatus.pending => const Color(0xFFFFA726),
      InviteStatus.accepted => const Color(0xFF6BBF59),
      InviteStatus.declined => const Color(0xFFE57373),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.outgoing_mail, color: Colors.grey.shade400, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.receiverEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
