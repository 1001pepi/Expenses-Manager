import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../database/database_helper.dart';
import '../../models/account.dart';
import '../../models/category.dart' as app;
import '../../models/expense.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/config_drawer.dart';
import 'add_expense_form.dart';

class EditExpenseScreen extends StatefulWidget {
  const EditExpenseScreen({
    super.key,
    required this.expense,
    this.themeProvider,
  });

  final Expense expense;
  final ThemeProvider? themeProvider;

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode _amountFocusNode = FocusNode();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final List<String> _tags = [];
  final Set<String> _selectedTags = {};
  final ImagePicker _picker = ImagePicker();
  final List<XFile?> _photos = [null, null];

  bool _isDirty = false;
  bool _loading = true;

  List<app.Category> _categories = [];
  Account? _selectedAccount;
  app.Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.expense.amount.toStringAsFixed(2);
    if (widget.expense.comment != null) {
      _commentController.text = widget.expense.comment!;
    }
    _selectedDate = widget.expense.date;

    _amountController.addListener(_markDirty);
    _commentController.addListener(_markDirty);

    final tagList = widget.expense.tags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    _tags.addAll(tagList);
    _selectedTags.addAll(tagList);

    if (widget.expense.photo1Path != null) {
      _photos[0] = XFile(widget.expense.photo1Path!);
    }
    if (widget.expense.photo2Path != null) {
      _photos[1] = XFile(widget.expense.photo2Path!);
    }

    _loadData();
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _markDirty() {
    // Always rebuild so save button state mirrors create form behavior.
    setState(() {
      _isDirty = true;
    });
  }

  Future<void> _loadData() async {
    final accounts = await DatabaseHelper.instance.getAllAccounts();
    final categories = await DatabaseHelper.instance.getAllCategories();

    Account? selectedAccount;
    if (accounts.isNotEmpty) {
      selectedAccount = accounts.firstWhere(
        (a) => a.id == widget.expense.accountId,
        orElse: () => accounts.first,
      );
    }

    app.Category? selectedCategory = categories.firstWhere(
      (c) => c.id == widget.expense.categoryId,
      orElse: () => categories.isNotEmpty
          ? categories.first
          : app.Category(
              id: -1,
              name: 'Unknown',
              iconCode: Icons.category.codePoint,
              color: 0xFF9E9E9E,
            ),
    );

    if (!mounted) return;

    setState(() {
      _categories = categories;
      _selectedAccount = selectedAccount;
      _selectedCategory = selectedCategory;
      _loading = false;
    });
  }

  Future<void> _refreshCategories() async {
    final categories = await DatabaseHelper.instance.getAllCategories(
      forceRefresh: true,
    );
    if (mounted) {
      setState(() {
        _categories = categories;
      });
    }
  }

  void _promoteCategoryIfNeeded(app.Category category) {
    final index = _categories.indexWhere((cat) => cat.id == category.id);

    if (index == -1) {
      _categories.insert(0, category);
      return;
    }

    if (index >= 7) {
      final existing = _categories.removeAt(index);
      _categories.insert(0, existing);
    }
  }

  Future<void> _showPhotoOptions(int slot) async {
    final allowCamera = !kIsWeb;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (allowCamera)
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickPhoto(slot, ImageSource.camera);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickPhoto(slot, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto(int slot, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null && mounted) {
        setState(() {
          _photos[slot] = picked;
          _isDirty = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to pick photo: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (_selectedAccount == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account and category')),
      );
      return;
    }

    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    final amount = double.tryParse(amountStr.replaceAll(',', '.'));
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final updated = widget.expense.copyWith(
      accountId: _selectedAccount!.id!,
      categoryId: _selectedCategory!.id!,
      amount: amount,
      date: _selectedDate,
      tags: _selectedTags.join(','),
      comment: _commentController.text.isNotEmpty
          ? _commentController.text
          : null,
      photo1Path: _photos[0]?.path,
      photo2Path: _photos[1]?.path,
    );

    try {
      await DatabaseHelper.instance.updateExpense(updated);
      if (mounted) {
        _isDirty = false;
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating expense: $e')));
      }
    }
  }

  bool get _isFormValid {
    final amountIsValid = _amountController.text.trim().isNotEmpty;
    final categoryIsSelected = _selectedCategory != null;
    final accountIsSelected = _selectedAccount != null;
    return amountIsValid && categoryIsSelected && accountIsSelected;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isSaveEnabled = _isFormValid;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_isDirty) return;

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Discard changes?',
              style: TextStyle(fontSize: 18),
            ),
            content: const Text(
              'You have unsaved changes. Do you want to discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Discard'),
              ),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawerEnableOpenDragGesture: false,
        drawer: ConfigDrawer(themeProvider: widget.themeProvider),
        appBar: AppBar(
          title: const Text('Edit Expense'),
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
          ),
        ),
        body: AddExpenseForm(
          selectedAccount: _selectedAccount,
          photos: _photos,
          categories: _categories,
          selectedCategory: _selectedCategory,
          selectedDate: _selectedDate,
          tags: _tags,
          selectedTags: _selectedTags,
          defaultCurrency: widget.themeProvider?.defaultCurrency,
          themeProvider: widget.themeProvider,
          amountFocusNode: _amountFocusNode,
          amountController: _amountController,
          commentController: _commentController,
          onAccountSelected: (account) {
            setState(() {
              _selectedAccount = account;
              _isDirty = true;
            });
          },
          onPhotoTap: (slot) {
            _showPhotoOptions(slot);
          },
          onPhotoDelete: (slot) {
            setState(() {
              _photos[slot] = null;
              _isDirty = true;
            });
          },
          onCategorySelected: (category) {
            setState(() {
              _selectedCategory = category;
              _promoteCategoryIfNeeded(category);
              _isDirty = true;
            });
          },
          onDateSelected: (date) {
            setState(() {
              _selectedDate = date;
              _isDirty = true;
            });
          },
          onAddTag: (tag) {
            setState(() {
              if (!_tags.contains(tag)) {
                _tags.insert(0, tag);
                _selectedTags.add(tag);
                _isDirty = true;
              }
            });
          },
          onToggleTag: (tag) {
            setState(() {
              if (_selectedTags.contains(tag)) {
                _selectedTags.remove(tag);
              } else {
                _selectedTags.add(tag);
              }
              _isDirty = true;
            });
          },
          onSave: _save,
          onCategoriesChanged: _refreshCategories,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          width: 200,
          child: FloatingActionButton.extended(
            onPressed: isSaveEnabled ? _save : null,
            elevation: isSaveEnabled ? 2 : 0,
            disabledElevation: 0,
            heroTag: null,
            backgroundColor: isSaveEnabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withOpacity(0.2),
            foregroundColor: isSaveEnabled
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.primary.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            extendedPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 32,
            ),
            label: const Text(
              'Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
