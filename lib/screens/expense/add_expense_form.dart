import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/account.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/forms/account_selector.dart';
import '../../widgets/forms/amount_input_field.dart';
import '../../widgets/forms/category_grid_selector.dart';
import '../../widgets/forms/comment_field.dart';
import '../../widgets/forms/date_selector.dart';
import '../../widgets/forms/tags_section.dart';

class AddExpenseForm extends StatefulWidget {
  final Account? selectedAccount;
  final List<dynamic> categories;
  final dynamic selectedCategory;
  final DateTime selectedDate;
  final ThemeProvider? themeProvider;
  final List<String> tags;
  final Set<String> selectedTags;
  final List<XFile?> photos;
  final String? defaultCurrency;
  final VoidCallback? onCategoriesChanged;
  final FocusNode? amountFocusNode;
  final TextEditingController? amountController;
  final TextEditingController? commentController;
  final Function(Account) onAccountSelected;
  final Function(dynamic) onCategorySelected;
  final Function(DateTime) onDateSelected;
  final Function(String) onAddTag;
  final Function(String) onToggleTag;
  final void Function(int) onPhotoTap;
  final void Function(int) onPhotoDelete;
  final VoidCallback onSave;

  const AddExpenseForm({
    Key? key,
    required this.selectedAccount,
    required this.categories,
    required this.selectedCategory,
    required this.selectedDate,
    this.themeProvider,
    required this.tags,
    required this.selectedTags,
    required this.photos,
    this.defaultCurrency,
    this.onCategoriesChanged,
    this.amountFocusNode,
    this.amountController,
    this.commentController,
    required this.onAccountSelected,
    required this.onCategorySelected,
    required this.onDateSelected,
    required this.onAddTag,
    required this.onToggleTag,
    required this.onPhotoTap,
    required this.onPhotoDelete,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  VoidCallback? _amountListener;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final currencyCode =
        widget.selectedAccount?.currency ?? widget.defaultCurrency ?? 'USD';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                RepaintBoundary(
                  child: DateSelector(
                    selectedDate: widget.selectedDate,
                    onDateSelected: widget.onDateSelected,
                    helpText: 'Select Expense Date',
                  ),
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
                const SizedBox(height: 16),
                Text(
                  'Photo',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(2, (index) {
                    final photo = index < widget.photos.length
                        ? widget.photos[index]
                        : null;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (photo == null) {
                            widget.onPhotoTap(index);
                          } else {
                            _viewPhoto(photo);
                          }
                        },
                        child: Container(
                          height: 120,
                          margin: EdgeInsets.only(
                            right: index == 0 ? 6 : 0,
                            left: index == 1 ? 6 : 0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.25),
                            ),
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceVariant.withOpacity(0.4),
                          ),
                          child: photo == null
                              ? const Center(child: Icon(Icons.add, size: 30))
                              : Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _buildPhotoPreview(photo),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _confirmDeletePhoto(index),
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.6,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  void _viewPhoto(XFile photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: kIsWeb
                  ? Image.network(photo.path, fit: BoxFit.contain)
                  : Image.file(File(photo.path), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeletePhoto(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?', style: TextStyle(fontSize: 18)),
        content: const Text(
          'Are you sure you want to delete this photo?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onPhotoDelete(index);
    }
  }

  Widget _buildPhotoPreview(XFile photo) {
    if (kIsWeb) {
      return Image.network(
        photo.path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return Image.file(
      File(photo.path),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
