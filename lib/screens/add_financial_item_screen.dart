import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../database/database_helper.dart';
import 'add_budget_form.dart';
import 'add_expense_form.dart';
import '../widgets/config_drawer.dart';

class AddFinancialItemScreen extends StatefulWidget {
  final int initialTabIndex;
  final ThemeProvider? themeProvider;
  final String? selectedTab;
  final DateTime? periodDate;
  final DateTimeRange? customPeriodRange;

  AddFinancialItemScreen({
    Key? key,
    this.initialTabIndex = 0,
    this.themeProvider,
    this.selectedTab,
    this.periodDate,
    this.customPeriodRange,
  }) : super(key: key);

  @override
  State<AddFinancialItemScreen> createState() => _AddFinancialItemScreenState();
}

class _AddFinancialItemScreenState extends State<AddFinancialItemScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Account? _selectedAccount;
  List<dynamic> _categories = [];
  dynamic _selectedBudgetCategory;
  dynamic _selectedExpenseCategory;
  DateTime _selectedBudgetDate = DateTime.now();
  DateTime _selectedExpenseDate = DateTime.now();
  DateTime? _budgetStartDate;
  DateTime? _budgetEndDate;
  final List<String> _budgetTags = [];
  final List<String> _expenseTags = [];
  final Set<String> _budgetSelectedTags = {};
  final Set<String> _expenseSelectedTags = {};
  final FocusNode _budgetAmountFocusNode = FocusNode();
  final FocusNode _expenseAmountFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _budgetAmountController = TextEditingController();
  final TextEditingController _budgetCommentController =
      TextEditingController();
  final TextEditingController _expenseAmountController =
      TextEditingController();
  final TextEditingController _expenseCommentController =
      TextEditingController();
  bool _isBudgetFormDirty = false;
  bool _isExpenseFormDirty = false;

  bool get _isFormDirty => _isBudgetFormDirty || _isExpenseFormDirty;

  Map<String, DateTime> _calculatePeriodDates() {
    final periodDate = widget.periodDate ?? DateTime.now();
    final tabName = widget.selectedTab ?? 'Day';

    DateTime startDate = periodDate;
    DateTime endDate = periodDate;

    switch (tabName) {
      case 'Day':
        startDate = DateTime(periodDate.year, periodDate.month, periodDate.day);
        endDate = DateTime(
          periodDate.year,
          periodDate.month,
          periodDate.day,
          23,
          59,
          59,
        );
        break;
      case 'Week':
        final dayOfWeek = periodDate.weekday;
        startDate = periodDate.subtract(Duration(days: dayOfWeek - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 6));
        endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        break;
      case 'Month':
        startDate = DateTime(periodDate.year, periodDate.month, 1);
        endDate = DateTime(
          periodDate.year,
          periodDate.month + 1,
          0,
          23,
          59,
          59,
        );
        break;
      case 'Year':
        startDate = DateTime(periodDate.year, 1, 1);
        endDate = DateTime(periodDate.year, 12, 31, 23, 59, 59);
        break;
      case 'Period':
        if (widget.customPeriodRange != null) {
          startDate = widget.customPeriodRange!.start;
          endDate = DateTime(
            widget.customPeriodRange!.end.year,
            widget.customPeriodRange!.end.month,
            widget.customPeriodRange!.end.day,
            23,
            59,
            59,
          );
        }
        break;
    }

    return {'start': startDate, 'end': endDate};
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
      animationDuration: Duration.zero,
    );
    final periodDates = _calculatePeriodDates();
    _budgetStartDate = periodDates['start'];
    _budgetEndDate = periodDates['end'];

    // Add listeners to track form changes
    _budgetAmountController.addListener(() {
      if (!_isBudgetFormDirty) {
        setState(() => _isBudgetFormDirty = true);
      }
    });

    _budgetCommentController.addListener(() {
      if (!_isBudgetFormDirty) {
        setState(() => _isBudgetFormDirty = true);
      }
    });

    _expenseAmountController.addListener(() {
      if (!_isExpenseFormDirty) {
        setState(() => _isExpenseFormDirty = true);
      }
    });

    _expenseCommentController.addListener(() {
      if (!_isExpenseFormDirty) {
        setState(() => _isExpenseFormDirty = true);
      }
    });

    _loadDefaultAccount();
  }

  Future<void> _loadDefaultAccount() async {
    final accounts = await DatabaseHelper.instance.getAllAccounts();
    if (accounts.isNotEmpty) {
      setState(() {
        _selectedAccount = accounts.first; // Load first account as default
      });
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.getAllCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        // Don't set default categories - let user select them
      });
    }
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

  @override
  void dispose() {
    _tabController.dispose();
    _budgetAmountFocusNode.dispose();
    _expenseAmountFocusNode.dispose();
    _budgetAmountController.dispose();
    _budgetCommentController.dispose();
    _expenseAmountController.dispose();
    _expenseCommentController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (_selectedAccount == null || _selectedBudgetCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account and category')),
      );
      return;
    }

    if (_budgetAmountController.text.isEmpty ||
        _budgetStartDate == null ||
        _budgetEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final budget = Budget(
      accountId: _selectedAccount!.id!,
      categoryId: _selectedBudgetCategory.id,
      amount: double.parse(_budgetAmountController.text),
      startDate: _budgetStartDate!,
      endDate: _budgetEndDate!,
      tags: _budgetSelectedTags.join(','),
      comment: _budgetCommentController.text.isNotEmpty
          ? _budgetCommentController.text
          : null,
      createdAt: DateTime.now(),
    );

    try {
      await DatabaseHelper.instance.createBudget(budget);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving budget: $e')));
      }
    }
  }

  Future<void> _saveExpense() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saving not yet implemented')),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isFormDirty) {
      return true; // Allow pop if form is not dirty
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?', style: TextStyle(fontSize: 18)),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFormDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _isFormDirty) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawerEnableOpenDragGesture: false,
        drawer: ConfigDrawer(themeProvider: widget.themeProvider),
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                FocusScope.of(context).unfocus();
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
          title: const Text('Add Financial Item'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.75),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Budget'),
                  Tab(text: 'Expense'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  AddBudgetForm(
                    selectedAccount: _selectedAccount,
                    categories: _categories,
                    selectedCategory: _selectedBudgetCategory,
                    selectedDate: _selectedBudgetDate,
                    startDate: _budgetStartDate,
                    endDate: _budgetEndDate,
                    tags: _budgetTags,
                    selectedTags: _budgetSelectedTags,
                    defaultCurrency: widget.themeProvider?.defaultCurrency,
                    themeProvider: widget.themeProvider,
                    amountFocusNode: _budgetAmountFocusNode,
                    amountController: _budgetAmountController,
                    commentController: _budgetCommentController,
                    onAccountSelected: (account) {
                      setState(() => _selectedAccount = account);
                    },
                    onCategorySelected: (category) {
                      setState(() {
                        _selectedBudgetCategory = category;
                        final categoryExists = _categories.any(
                          (cat) => cat.id == category.id,
                        );
                        if (!categoryExists) {
                          _categories.insert(0, category);
                        } else {
                          // Move existing category to front
                          _categories.removeWhere(
                            (cat) => cat.id == category.id,
                          );
                          _categories.insert(0, category);
                        }
                      });
                    },
                    onDateSelected: (date) {
                      setState(() => _selectedBudgetDate = date);
                    },
                    onStartDateSelected: (date) {
                      setState(() => _budgetStartDate = date);
                    },
                    onEndDateSelected: (date) {
                      setState(() => _budgetEndDate = date);
                    },
                    onAddTag: (tag) {
                      setState(() {
                        if (!_budgetTags.contains(tag)) {
                          _budgetTags.insert(0, tag);
                          _budgetSelectedTags.add(tag);
                        }
                      });
                    },
                    onToggleTag: (tag) {
                      setState(() {
                        if (_budgetSelectedTags.contains(tag)) {
                          _budgetSelectedTags.remove(tag);
                        } else {
                          _budgetSelectedTags.add(tag);
                        }
                      });
                    },
                    onSave: _saveBudget,
                    onCategoriesChanged: _refreshCategories,
                  ),
                  AddExpenseForm(
                    categories: _categories,
                    selectedCategory: _selectedExpenseCategory,
                    selectedDate: _selectedExpenseDate,
                    tags: _expenseTags,
                    selectedTags: _expenseSelectedTags,
                    defaultCurrency: widget.themeProvider?.defaultCurrency,
                    themeProvider: widget.themeProvider,
                    amountFocusNode: _expenseAmountFocusNode,
                    onCategorySelected: (category) {
                      setState(() {
                        _selectedExpenseCategory = category;
                        final categoryExists = _categories.any(
                          (cat) => cat.id == category.id,
                        );
                        if (!categoryExists) {
                          _categories.insert(0, category);
                        } else {
                          // Move existing category to front
                          _categories.removeWhere(
                            (cat) => cat.id == category.id,
                          );
                          _categories.insert(0, category);
                        }
                      });
                    },
                    onDateSelected: (date) {
                      setState(() => _selectedExpenseDate = date);
                    },
                    onAddTag: (tag) {
                      setState(() {
                        if (!_expenseTags.contains(tag)) {
                          _expenseTags.insert(0, tag);
                          _expenseSelectedTags.add(tag);
                        }
                      });
                    },
                    onToggleTag: (tag) {
                      setState(() {
                        if (_expenseSelectedTags.contains(tag)) {
                          _expenseSelectedTags.remove(tag);
                        } else {
                          _expenseSelectedTags.add(tag);
                        }
                      });
                    },
                    onSave: () {
                      // TODO: Implement save logic
                      Navigator.pop(context);
                    },
                    onCategoriesChanged: _refreshCategories,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
