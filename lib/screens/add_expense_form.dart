import 'package:flutter/material.dart';
import '../widgets/forms/amount_input_field.dart';
import '../widgets/forms/category_grid_selector.dart';
import '../widgets/forms/date_selector.dart';
import '../widgets/forms/tags_section.dart';
import '../widgets/forms/comment_field.dart';
import '../theme/theme_provider.dart';

class AddExpenseForm extends StatelessWidget {
  final List<dynamic> categories;
  final dynamic selectedCategory;
  final DateTime selectedDate;
  final List<String> tags;
  final Set<String> selectedTags;
  final String? defaultCurrency;
  final ThemeProvider? themeProvider;
  final VoidCallback? onCategoriesChanged;
  final FocusNode? amountFocusNode;
  final Function(dynamic) onCategorySelected;
  final Function(DateTime) onDateSelected;
  final Function(String) onAddTag;
  final Function(String) onToggleTag;
  final VoidCallback onSave;

  const AddExpenseForm({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.selectedDate,
    required this.tags,
    required this.selectedTags,
    this.defaultCurrency,
    this.themeProvider,
    this.onCategoriesChanged,
    this.amountFocusNode,
    required this.onCategorySelected,
    required this.onDateSelected,
    required this.onAddTag,
    required this.onToggleTag,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyCode = defaultCurrency ?? 'USD';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RepaintBoundary(
            child: AmountInputField(
              currencyCode: currencyCode,
              focusNode: amountFocusNode,
            ),
          ),
          const SizedBox(height: 24),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Expense Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          RepaintBoundary(
            child: CategoryGridSelector(
              categories: categories,
              selectedCategory: selectedCategory,
              onCategorySelected: onCategorySelected,
              themeProvider: themeProvider,
              onCategoriesChanged: onCategoriesChanged,
            ),
          ),
          const SizedBox(height: 12),
          RepaintBoundary(
            child: DateSelector(
              selectedDate: selectedDate,
              onDateSelected: onDateSelected,
              helpText: 'Select Expense Date',
            ),
          ),
          const SizedBox(height: 12),
          RepaintBoundary(
            child: TagsSection(
              tags: tags,
              selectedTags: selectedTags,
              onAddTag: onAddTag,
              onToggleTag: onToggleTag,
            ),
          ),
          const SizedBox(height: 16),
          const RepaintBoundary(child: CommentField()),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Expense'),
          ),
        ],
      ),
    );
  }
}
