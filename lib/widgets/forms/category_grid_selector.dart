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
          Text(
            'Category',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
        Text(
          'Category',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 22,
            crossAxisSpacing: 22,
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
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: categoryColor.withOpacity(0.15),
          border: Border.all(
            color: categoryColor,
            width: isSelected ? 2.5 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 32, color: categoryColor),
            const SizedBox(height: 4),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
          ],
        ),
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
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primaryContainer,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            'more',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
