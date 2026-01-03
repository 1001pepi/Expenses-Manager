import '../../theme/theme_provider.dart';
import 'package:flutter/material.dart';
import '../../models/account.dart';
import '../../widgets/forms/amount_input_field.dart';
import '../../widgets/forms/account_selector.dart';
import '../../widgets/forms/category_grid_selector.dart';
import '../../widgets/forms/date_selector.dart';
import '../../widgets/forms/tags_section.dart';
import '../../widgets/forms/comment_field.dart';

class AddBudgetForm extends StatefulWidget {
  final Account? selectedAccount;
  final List<dynamic> categories;
  final dynamic selectedCategory;
  final DateTime selectedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final ThemeProvider? themeProvider;
  final List<String> tags;
  final Set<String> selectedTags;
  final String? defaultCurrency;
  final VoidCallback? onCategoriesChanged;
  final FocusNode? amountFocusNode;
  final TextEditingController? amountController;
  final TextEditingController? commentController;
  final Function(Account) onAccountSelected;
  final Function(dynamic) onCategorySelected;
  final Function(DateTime) onDateSelected;
  final Function(DateTime)? onStartDateSelected;
  final Function(DateTime)? onEndDateSelected;
  final Function(String) onAddTag;
  final Function(String) onToggleTag;
  final VoidCallback onSave;

  const AddBudgetForm({
    Key? key,
    required this.selectedAccount,
    required this.categories,
    required this.selectedCategory,
    required this.selectedDate,
    this.startDate,
    this.endDate,
    this.themeProvider,
    required this.tags,
    required this.selectedTags,
    this.defaultCurrency,
    this.onCategoriesChanged,
    this.amountFocusNode,
    this.amountController,
    this.commentController,
    required this.onAccountSelected,
    required this.onCategorySelected,
    required this.onDateSelected,
    this.onStartDateSelected,
    this.onEndDateSelected,
    required this.onAddTag,
    required this.onToggleTag,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddBudgetForm> createState() => _AddBudgetFormState();
}

class _AddBudgetFormState extends State<AddBudgetForm> {
  VoidCallback? _amountListener;

  @override
  void initState() {
    super.initState();
    // Add listener to amount controller for form validation
    _amountListener = () {
      if (!mounted) return;
      setState(() {});
    };
    widget.amountController?.addListener(_amountListener!);
  }

  @override
  void dispose() {
    if (_amountListener != null) {
      widget.amountController?.removeListener(_amountListener!);
    }
    super.dispose();
  }

  bool get _isFormValid {
    final amountIsValid =
        widget.amountController?.text.trim().isNotEmpty ?? false;
    final categoryIsSelected = widget.selectedCategory != null;
    return amountIsValid && categoryIsSelected;
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode =
        widget.selectedAccount?.currency ?? widget.defaultCurrency ?? 'USD';

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Amount',
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
                RepaintBoundary(
                  child: AmountInputField(
                    currencyCode: currencyCode,
                    focusNode: widget.amountFocusNode,
                    controller: widget.amountController,
                  ),
                ),
                const SizedBox(height: 24),
                RepaintBoundary(
                  child: AccountSelector(
                    selectedAccount: widget.selectedAccount,
                    onAccountSelected: widget.onAccountSelected,
                  ),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  child: CategoryGridSelector(
                    categories: widget.categories,
                    selectedCategory: widget.selectedCategory,
                    onCategorySelected: (category) {
                      widget.onCategorySelected(category);
                      setState(() {});
                    },
                    themeProvider: widget.themeProvider,
                    onCategoriesChanged: widget.onCategoriesChanged,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          RepaintBoundary(
                            child: DateSelector(
                              selectedDate:
                                  widget.startDate ?? widget.selectedDate,
                              onDateSelected:
                                  widget.onStartDateSelected ??
                                  widget.onDateSelected,
                              helpText: 'Start Date',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          RepaintBoundary(
                            child: DateSelector(
                              selectedDate:
                                  widget.endDate ?? widget.selectedDate,
                              onDateSelected:
                                  widget.onEndDateSelected ??
                                  widget.onDateSelected,
                              helpText: 'End Date',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                RepaintBoundary(
                  child: TagsSection(
                    tags: widget.tags,
                    selectedTags: widget.selectedTags,
                    onAddTag: widget.onAddTag,
                    onToggleTag: widget.onToggleTag,
                  ),
                ),
                RepaintBoundary(
                  child: CommentField(controller: widget.commentController),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
