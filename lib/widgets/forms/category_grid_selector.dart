import 'package:flutter/material.dart';
import '../../screens/category/category_selection_screen.dart';
import '../../screens/category/create_category_screen.dart';
import '../../theme/theme_provider.dart';

class CategoryGridSelector extends StatelessWidget {
  final List<dynamic> categories;
  final dynamic selectedCategory;
  final Function(dynamic) onCategorySelected;
  final ThemeProvider? themeProvider;
  final VoidCallback? onCategoriesChanged;

  const CategoryGridSelector({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.themeProvider,
    this.onCategoriesChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If no categories, show a Create Category button (matches Add tag style)
    if (categories.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Category',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreateCategoryScreen(themeProvider: themeProvider),
                ),
              );
              if (created == true) {
                onCategoriesChanged?.call();
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Category'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    // Limit to first 7 categories for display
    final displayCategories = categories.take(7).toList();
    final showMoreButton = categories.length > 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Category',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              TextSpan(
                text: ' *',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.8,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayCategories.length + (showMoreButton ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < displayCategories.length) {
              final category = displayCategories[index];
              final isSelected = selectedCategory?.id == category.id;
              return CategoryGridItem(
                category: category,
                isSelected: isSelected,
                onTap: () => onCategorySelected(category),
              );
            } else {
              // Show '+' tile for more categories
              return MoreCategoriesButton(
                selectedCategory: selectedCategory,
                onCategorySelected: onCategorySelected,
                themeProvider: themeProvider,
              );
            }
          },
        ),
      ],
    );
  }
}

class CategoryGridItem extends StatelessWidget {
  final dynamic category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryGridItem({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconData = IconData(category.iconCode, fontFamily: 'MaterialIcons');
    final categoryColor = Color(category.color);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? categoryColor.withOpacity(0.25)
                  : categoryColor.withOpacity(0.15),
              border: Border.all(
                color: categoryColor,
                width: isSelected ? 3.0 : 0.5,
              ),
            ),
            padding: EdgeInsets.all(isSelected ? 14 : 12),
            child: Icon(iconData, size: 38, color: categoryColor),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white,
                    Colors.white,
                    Colors.white.withOpacity(0),
                  ],
                  stops: const [0.0, 0.95, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? categoryColor
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MoreCategoriesButton extends StatelessWidget {
  final dynamic selectedCategory;
  final Function(dynamic) onCategorySelected;
  final ThemeProvider? themeProvider;

  const MoreCategoriesButton({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.themeProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selected = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategorySelectionScreen(
              initialSelection: selectedCategory,
              themeProvider: themeProvider,
            ),
          ),
        );
        if (selected != null) {
          onCategorySelected(selected);
        }
      },
      borderRadius: BorderRadius.circular(50),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Center(
              child: Text(
                '. . .',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const SizedBox(height: 11),
        ],
      ),
    );
  }
}
