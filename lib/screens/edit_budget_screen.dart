import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../theme/theme_provider.dart';
import '../widgets/config_drawer.dart';
import 'add_budget_form.dart';

class EditBudgetScreen extends StatefulWidget {
  const EditBudgetScreen({super.key, required this.budget, this.themeProvider});

  final Budget budget;
  final ThemeProvider? themeProvider;

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode _amountFocusNode = FocusNode();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final List<String> _tags = [];
  final Set<String> _selectedTags = {};
  bool _isDirty = false;
  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  List<Category> _categories = [];
  Account? _selectedAccount;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.budget.amount.toStringAsFixed(2);
    if (widget.budget.comment != null) {
      _commentController.text = widget.budget.comment!;
    }
    _selectedDate = widget.budget.startDate;
    _startDate = widget.budget.startDate;
    _endDate = widget.budget.endDate;

    _amountController.addListener(_markDirty);
    _amountController.addListener(_onFormChanged);
    _commentController.addListener(_markDirty);
    _commentController.addListener(_onFormChanged);

    final tagList = widget.budget.tags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    _tags.addAll(tagList);
    _selectedTags.addAll(tagList);

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
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _loadData() async {
    final accounts = await DatabaseHelper.instance.getAllAccounts();
    final categories = await DatabaseHelper.instance.getAllCategories();

    Account? selectedAccount;
    if (accounts.isNotEmpty) {
      selectedAccount = accounts.firstWhere(
        (a) => a.id == widget.budget.accountId,
        orElse: () => accounts.first,
      );
    }

    Category? selectedCategory = categories.firstWhere(
      (c) => c.id == widget.budget.categoryId,
      orElse: () => categories.isNotEmpty
          ? categories.first
          : Category(
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

  void _promoteCategoryIfNeeded(Category category) {
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

  Future<void> _save() async {
    if (_selectedAccount == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account and category')),
      );
      return;
    }

    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final updated = widget.budget.copyWith(
      accountId: _selectedAccount!.id!,
      categoryId: _selectedCategory!.id!,
      amount: amount,
      startDate: _startDate!,
      endDate: _endDate!,
      tags: _selectedTags.join(','),
      comment: _commentController.text.isNotEmpty
          ? _commentController.text
          : null,
      // keep createdAt as original
    );

    try {
      await DatabaseHelper.instance.updateBudget(updated);
      if (mounted) {
        _isDirty = false;
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating budget: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaveEnabled = _isFormValid;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
          title: const Text('Edit Budget'),
          centerTitle: true,
          actions: [TextButton(onPressed: _save, child: const Text('Save'))],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
          ),
        ),
        body: AddBudgetForm(
          selectedAccount: _selectedAccount,
          categories: _categories,
          selectedCategory: _selectedCategory,
          selectedDate: _selectedDate,
          startDate: _startDate,
          endDate: _endDate,
          tags: _tags,
          selectedTags: _selectedTags,
          defaultCurrency: widget.themeProvider?.defaultCurrency,
          themeProvider: widget.themeProvider,
          amountFocusNode: _amountFocusNode,
          amountController: _amountController,
          commentController: _commentController,
          onAccountSelected: (account) {
            setState(() => _selectedAccount = account);
            _markDirty();
          },
          onCategorySelected: (category) {
            setState(() {
              _selectedCategory = category;
              _promoteCategoryIfNeeded(category);
            });
            _markDirty();
          },
          onDateSelected: (date) {
            setState(() => _selectedDate = date);
            _markDirty();
          },
          onStartDateSelected: (date) {
            setState(() => _startDate = date);
            _markDirty();
          },
          onEndDateSelected: (date) {
            setState(() => _endDate = date);
            _markDirty();
          },
          onAddTag: (tag) {
            setState(() {
              if (!_tags.contains(tag)) {
                _tags.insert(0, tag);
                _selectedTags.add(tag);
              }
            });
            _markDirty();
          },
          onToggleTag: (tag) {
            setState(() {
              if (_selectedTags.contains(tag)) {
                _selectedTags.remove(tag);
              } else {
                _selectedTags.add(tag);
              }
            });
            _markDirty();
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
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withOpacity(0.2),
            foregroundColor: isSaveEnabled
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.primary.withOpacity(0.5),
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

  bool get _isFormValid {
    return _selectedAccount != null &&
        _selectedCategory != null &&
        _amountController.text.trim().isNotEmpty &&
        _startDate != null &&
        _endDate != null;
  }
}
