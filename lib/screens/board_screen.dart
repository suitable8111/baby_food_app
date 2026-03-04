import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/board_recipe.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import 'recipe_detail_screen.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RecipeProvider>().loadBoardRecipes();
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final boardRecipes = recipeProvider.boardRecipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('레시피 게시판'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => recipeProvider.loadBoardRecipes(),
          ),
        ],
      ),
      floatingActionButton: authProvider.isAuthenticated
          ? FloatingActionButton.extended(
              onPressed: () => _showPublishDialog(context),
              icon: const Icon(Icons.publish),
              label: const Text('레시피 게시'),
            )
          : null,
      body: boardRecipes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    '게시된 레시피가 없습니다',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '첫 번째 레시피를 게시해보세요!',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => recipeProvider.loadBoardRecipes(),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: boardRecipes.length,
                itemBuilder: (context, index) {
                  final boardRecipe = boardRecipes[index];
                  return _BoardRecipeCard(boardRecipe: boardRecipe);
                },
              ),
            ),
    );
  }

  void _showPublishDialog(BuildContext outerContext) {
    final recipeProvider = outerContext.read<RecipeProvider>();
    final userRecipes = recipeProvider.userRecipes;

    if (userRecipes.isEmpty) {
      ScaffoldMessenger.of(outerContext).showSnackBar(
        const SnackBar(content: Text('게시할 나만의 레시피가 없습니다. 먼저 레시피를 만들어주세요!')),
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
                    '게시할 레시피 선택',
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
                      backgroundColor: _getStageColor(recipe.stage)
                          .withOpacity(0.2),
                      child: Icon(Icons.restaurant,
                          color: _getStageColor(recipe.stage)),
                    ),
                    title: Text(recipe.name),
                    subtitle: Text(
                        '${recipe.stage.shortName} | ${recipe.cookingTimeMinutes}분'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final confirm = await showDialog<bool>(
                        context: outerContext,
                        builder: (dlgContext) => AlertDialog(
                          title: const Text('레시피 게시'),
                          content: Text(
                              "'${recipe.name}' 레시피를 게시판에 공유하시겠습니까?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dlgContext, false),
                              child: const Text('취소'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(dlgContext, true),
                              child: const Text('게시'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && outerContext.mounted) {
                        final success =
                            await recipeProvider.publishToBoard(recipe);
                        if (outerContext.mounted) {
                          ScaffoldMessenger.of(outerContext).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? '레시피가 게시판에 공유되었습니다!'
                                  : '게시에 실패했습니다.'),
                            ),
                          );
                        }
                      }
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

  Color _getStageColor(BabyFoodStage stage) {
    switch (stage.index) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _BoardRecipeCard extends StatelessWidget {
  final BoardRecipe boardRecipe;

  const _BoardRecipeCard({required this.boardRecipe});

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final recipe = boardRecipe.toRecipe();
    final canEdit = recipeProvider.canEditBoardRecipe(boardRecipe);
    final isFav = recipeProvider.isBoardFavorite(boardRecipe.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(
                recipe: recipe,
                boardRecipe: boardRecipe,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역
            Container(
              height: 100,
              width: double.infinity,
              color: _getStageColor(recipe.stage).withOpacity(0.2),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (boardRecipe.photoUrl != null)
                    Image.network(
                      boardRecipe.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Center(
                        child: Icon(Icons.restaurant,
                            size: 40, color: _getStageColor(recipe.stage)),
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        Icons.restaurant,
                        size: 40,
                        color: _getStageColor(recipe.stage),
                      ),
                    ),
                  // 단계 뱃지
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStageColor(recipe.stage),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        recipe.stage.shortName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // 즐겨찾기
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () async {
                        final authProvider = context.read<AuthProvider>();
                        if (!authProvider.isAuthenticated) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('즐겨찾기는 로그인이 필요합니다.')),
                          );
                          return;
                        }
                        await recipeProvider
                            .toggleBoardFavorite(boardRecipe.id);
                      },
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.grey,
                        size: 22,
                      ),
                    ),
                  ),
                  // 관리자/작성자 편집 메뉴
                  if (canEdit)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: PopupMenuButton<String>(
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.more_vert,
                              color: Colors.white, size: 16),
                        ),
                        onSelected: (value) async {
                          if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('게시물 삭제'),
                                content: const Text('이 게시물을 삭제하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    child: const Text('삭제'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              await recipeProvider
                                  .deleteBoardRecipe(boardRecipe.id);
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('삭제',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // 정보 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${recipe.cookingTimeMinutes}분 | ${recipe.difficulty.displayName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      boardRecipe.authorDisplayName ??
                          boardRecipe.authorEmail.split('@').first,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStageColor(BabyFoodStage stage) {
    switch (stage.index) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
