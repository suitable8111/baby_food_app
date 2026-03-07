import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/family_message.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

class FamilyChatScreen extends StatefulWidget {
  const FamilyChatScreen({super.key});

  @override
  State<FamilyChatScreen> createState() => _FamilyChatScreenState();
}

class _FamilyChatScreenState extends State<FamilyChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  List<FamilyMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  MessageType _selectedType = MessageType.message;
  MessageType? _filterType; // null = 전체

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMessages());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final auth = context.read<AuthProvider>();
    final service = context.read<FirebaseService>();
    if (!auth.isAuthenticated) return;

    setState(() => _isLoading = true);
    try {
      final msgs = await service.getFamilyMessages(auth.familyId);
      if (mounted) {
        setState(() => _messages = msgs);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('메시지 로드 실패: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _sendMessage() async {
    final content = _textController.text.trim();
    if (content.isEmpty || _isSending) return;

    final auth = context.read<AuthProvider>();
    final service = context.read<FirebaseService>();
    if (auth.userId == null) return;

    setState(() => _isSending = true);
    try {
      final msg = FamilyMessage(
        id: '',
        familyId: auth.familyId,
        userId: auth.userId!,
        authorName: auth.displayName ?? '나',
        content: content,
        type: _selectedType,
        createdAt: DateTime.now(),
      );
      await service.sendFamilyMessage(msg);
      _textController.clear();
    } catch (e) {
      debugPrint('메시지 전송 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전송에 실패했습니다.')),
        );
      }
      if (mounted) setState(() => _isSending = false);
      return;
    }
    // 전송 성공 후 목록 새로고침 (별도 에러 처리)
    await _loadMessages();
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _deleteMessage(FamilyMessage msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('메시지 삭제'),
        content: const Text('이 메시지를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제',
                style: TextStyle(color: Color(0xFFE57373))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final service = context.read<FirebaseService>();
    try {
      await service.deleteFamilyMessage(msg.id);
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다.')));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final partnerName =
        auth.partnerProfile?.nickname ?? auth.partnerProfile?.email ?? '파트너';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('가족 대화방',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(
              auth.hasPartner ? '$partnerName 과 함께' : '파트너 연동 필요',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2D2D2D),
        actions: [
          IconButton(
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 칩 바
          _buildFilterBar(),
          // 메시지 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Builder(builder: (_) {
                    final filtered = _filterType == null
                        ? _messages
                        : _messages
                            .where((m) => m.type == _filterType)
                            .toList();
                    return RefreshIndicator(
                      onRefresh: _loadMessages,
                      child: filtered.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final msg = filtered[i];
                                final showDate = i == 0 ||
                                    !_isSameDay(
                                        filtered[i - 1].createdAt,
                                        msg.createdAt);
                                return Column(
                                  children: [
                                    if (showDate)
                                      _buildDateDivider(msg.createdAt),
                                    _buildMessageBubble(msg, auth.userId ?? ''),
                                  ],
                                );
                              },
                            ),
                    );
                  }),
          ),
          // 입력 영역
          _buildInputArea(auth),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 전체 칩
            _buildFilterChip(
              label: '전체',
              emoji: '🗂️',
              isSelected: _filterType == null,
              color: const Color(0xFF78909C),
              onTap: () => setState(() => _filterType = null),
            ),
            const SizedBox(width: 8),
            // 타입별 칩
            ...MessageType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: type.displayName,
                    emoji: type.emoji,
                    isSelected: _filterType == type,
                    color: _typeColor(type),
                    onTap: () => setState(
                        () => _filterType = _filterType == type ? null : type),
                    count: _messages.where((m) => m.type == type).length,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String emoji,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    int? count,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                '아직 메시지가 없어요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '메모, 공지, 응원 메시지를 남겨보세요!',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(FamilyMessage msg, String myUserId) {
    final isMe = msg.userId == myUserId;
    final timeStr = DateFormat('HH:mm').format(msg.createdAt);

    return GestureDetector(
      onLongPress: isMe ? () => _deleteMessage(msg) : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 파트너 아바타
            if (!isMe) ...[
              _buildAvatar(msg.authorName),
              const SizedBox(width: 8),
            ],
            // 말풍선 + 시간
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // 작성자명 (파트너만)
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        msg.authorName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 내 메시지: 시간 왼쪽
                      if (isMe) ...[
                        Text(
                          timeStr,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade400),
                        ),
                        const SizedBox(width: 4),
                      ],
                      // 말풍선
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.65,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF6BBF59)
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft:
                                  Radius.circular(isMe ? 18 : 4),
                              bottomRight:
                                  Radius.circular(isMe ? 4 : 18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 메시지 타입 뱃지 (일반 메시지 제외)
                              if (msg.type != MessageType.message)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : _typeColor(msg.type)
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${msg.type.emoji} ${msg.type.displayName}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isMe
                                            ? Colors.white
                                            : _typeColor(msg.type),
                                      ),
                                    ),
                                  ),
                                ),
                              // 내용
                              Text(
                                msg.content,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isMe
                                      ? Colors.white
                                      : const Color(0xFF2D2D2D),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 파트너 메시지: 시간 오른쪽
                      if (!isMe) ...[
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade400),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // 내 아바타 (오른쪽)
            if (isMe) ...[
              const SizedBox(width: 8),
              _buildAvatar(msg.authorName, isMe: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, {bool isMe = false}) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFF6BBF59).withValues(alpha: 0.2)
            : const Color(0xFFEC407A).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isMe ? const Color(0xFF4A9E3F) : const Color(0xFFEC407A),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(AuthProvider auth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 메시지 타입 선택
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: MessageType.values.map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _typeColor(type)
                            : _typeColor(type).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: _typeColor(type).withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '${type.emoji} ${type.displayName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.white : _typeColor(type),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // 입력창 + 전송 버튼
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: '${_selectedType.emoji} ${_selectedType.displayName} 입력...',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isSending ? null : _sendMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _isSending
                        ? Colors.grey.shade300
                        : const Color(0xFF6BBF59),
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _typeColor(MessageType type) {
    switch (type) {
      case MessageType.message:
        return const Color(0xFF6BBF59);
      case MessageType.memo:
        return const Color(0xFF42A5F5);
      case MessageType.notice:
        return const Color(0xFFFF7043);
      case MessageType.cheer:
        return const Color(0xFFEC407A);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return '오늘';
    if (diff == 1) return '어제';
    return DateFormat('M월 d일 (E)', 'ko').format(date);
  }
}
