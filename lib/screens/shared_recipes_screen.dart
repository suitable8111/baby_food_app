import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shared_recipe.dart';
import '../models/ingredient.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import 'recipe_detail_screen.dart';

class SharedRecipesScreen extends StatefulWidget {
  const SharedRecipesScreen({super.key});

  @override
  State<SharedRecipesScreen> createState() => _SharedRecipesScreenState();
}

class _SharedRecipesScreenState extends State<SharedRecipesScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<RecipeProvider>();
    provider.loadReceivedShares();
    provider.loadSentShares();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('레시피 공유함'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '받은 공유'),
              Tab(text: '보낸 공유'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showShareFlow(context),
          icon: const Icon(Icons.share),
          label: const Text('레시피 공유'),
        ),
        body: const TabBarView(
          children: [
            _ReceivedSharesTab(),
            _SentSharesTab(),
          ],
        ),
      ),
    );
  }

  void _showShareFlow(BuildContext outerContext) {
    final authProvider = outerContext.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(outerContext).showSnackBar(
        const SnackBar(content: Text('로그인이 필요한 기능입니다.')),
      );
      return;
    }

    final recipeProvider = outerContext.read<RecipeProvider>();
    final userRecipes = recipeProvider.userRecipes;

    if (userRecipes.isEmpty) {
      ScaffoldMessenger.of(outerContext).showSnackBar(
        const SnackBar(content: Text('공유할 나만의 레시피가 없습니다. 먼저 레시피를 만들어주세요!')),
      );
      return;
    }

    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '공유할 레시피 선택',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: userRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = userRecipes[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _getStageColor(recipe.stage).withOpacity(0.2),
                      child: Icon(Icons.restaurant,
                          color: _getStageColor(recipe.stage)),
                    ),
                    title: Text(recipe.name),
                    subtitle: Text(
                        '${recipe.stage.shortName} | ${recipe.cookingTimeMinutes}분'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showEmailDialog(outerContext, recipe);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmailDialog(BuildContext outerContext, recipe) {
    final emailController = TextEditingController();
    showDialog(
      context: outerContext,
      builder: (dlgContext) => AlertDialog(
        title: const Text('레시피 공유'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "'${recipe.name}' 레시피를 공유할 이메일을 입력하세요.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: '받는 사람 이메일',
                hintText: 'example@email.com',
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  const SnackBar(content: Text('올바른 이메일을 입력해주세요.')),
                );
                return;
              }
              Navigator.pop(dlgContext);
              final recipeProvider = outerContext.read<RecipeProvider>();
              final success =
                  await recipeProvider.shareRecipe(recipe, email);
              if (outerContext.mounted) {
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '$email에게 레시피를 공유했습니다!'
                        : '공유에 실패했습니다.'),
                  ),
                );
              }
            },
            child: const Text('공유'),
          ),
        ],
      ),
    );
  }

  Color _getStageColor(BabyFoodStage stage) {
    switch (stage) {
      case BabyFoodStage.early:
        return Colors.green;
      case BabyFoodStage.middle:
        return Colors.orange;
      case BabyFoodStage.late:
        return Colors.purple;
    }
  }
}

class _ReceivedSharesTab extends StatelessWidget {
  const _ReceivedSharesTab();

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final shares = recipeProvider.receivedShares;

    if (shares.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              '받은 공유가 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => recipeProvider.loadReceivedShares(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: shares.length,
        itemBuilder: (context, index) {
          final share = shares[index];
          return _SharedRecipeCard(
            share: share,
            isReceived: true,
          );
        },
      ),
    );
  }
}

class _SentSharesTab extends StatelessWidget {
  const _SentSharesTab();

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final shares = recipeProvider.sentShares;

    if (shares.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.outbox_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              '보낸 공유가 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => recipeProvider.loadSentShares(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: shares.length,
        itemBuilder: (context, index) {
          final share = shares[index];
          return _SharedRecipeCard(
            share: share,
            isReceived: false,
          );
        },
      ),
    );
  }
}

class _SharedRecipeCard extends StatelessWidget {
  final SharedRecipe share;
  final bool isReceived;

  const _SharedRecipeCard({
    required this.share,
    required this.isReceived,
  });

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.read<RecipeProvider>();
    final isPending = share.status == ShareStatus.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    share.recipeName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                _buildStatusChip(share.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isReceived
                  ? '보낸 사람: ${share.senderEmail}'
                  : '받는 사람: ${share.receiverEmail}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            if (share.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatDate(share.createdAt!),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RecipeDetailScreen(recipe: share.toRecipe()),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('레시피 보기'),
                ),
                if (isReceived && isPending) ...[
                  FilledButton.icon(
                    onPressed: () async {
                      final success = await recipeProvider.acceptShare(share);
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('레시피가 내 레시피에 저장되었습니다!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_alt, size: 18),
                    label: const Text('내 레시피에 추가'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await recipeProvider.declineShare(share.id);
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('거절'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ShareStatus status) {
    Color color;
    String label;

    switch (status) {
      case ShareStatus.pending:
        color = Colors.orange;
        label = '대기중';
      case ShareStatus.accepted:
        color = Colors.green;
        label = '수락됨';
      case ShareStatus.declined:
        color = Colors.red;
        label = '거절됨';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
