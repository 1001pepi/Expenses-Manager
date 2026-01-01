import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../theme/theme_provider.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../database/database_helper.dart';
import 'add_budget_form.dart';
import 'add_expense_form.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _budgetAmountController = TextEditingController();
  final TextEditingController _budgetCommentController =
      TextEditingController();
  final TextEditingController _expenseAmountController =
      TextEditingController();
  final TextEditingController _expenseCommentController =
      TextEditingController();
  bool _isBudgetFormDirty = false;
  final List<XFile?> _expensePhotos = [null, null];
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
    _tabController.addListener(_refreshSaveState);
    _tabController.animation?.addListener(_refreshSaveState);
    final periodDates = _calculatePeriodDates();
    _budgetStartDate = periodDates['start'];
    _budgetEndDate = periodDates['end'];

    // Add listeners to track form changes
    _budgetAmountController.addListener(() {
      if (!_isBudgetFormDirty) _isBudgetFormDirty = true;
      _refreshSaveState();
    });

    _budgetCommentController.addListener(() {
      if (!_isBudgetFormDirty) {
        setState(() => _isBudgetFormDirty = true);
      }
    });

    _expenseAmountController.addListener(() {
      if (!_isExpenseFormDirty) {
        _isExpenseFormDirty = true;
      }
      _refreshSaveState();
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

  void _unfocusFields() {
    FocusScope.of(context).unfocus();
  }

  void _refreshSaveState() {
    if (mounted) setState(() {});
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
    _tabController.removeListener(_refreshSaveState);
    _tabController.animation?.removeListener(_refreshSaveState);
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
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        Navigator.pop(context, true);
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
    if (_selectedAccount == null || _selectedExpenseCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account and category')),
      );
      return;
    }

    if (_expenseAmountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    final expense = Expense(
      accountId: _selectedAccount!.id!,
      categoryId: _selectedExpenseCategory.id,
      amount: double.parse(_expenseAmountController.text),
      date: _selectedExpenseDate,
      tags: _expenseSelectedTags.join(','),
      comment: _expenseCommentController.text.isNotEmpty
          ? _expenseCommentController.text
          : null,
      photo1Path: _expensePhotos[0]?.path,
      photo2Path: _expensePhotos[1]?.path,
      createdAt: DateTime.now(),
    );

    try {
      await DatabaseHelper.instance.createExpense(expense);
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving expense: $e')));
      }
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

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBudgetTab = _tabController.index == 0;
    final isSaveEnabled =
      isBudgetTab ? _isBudgetFormValid : _isExpenseFormValid;
    final saveAction = isBudgetTab ? _saveBudget : _saveExpense;

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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
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
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          onPanDown: (_) => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  indicatorSize: TabBarIndicatorSize.tab,
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
                  // Allow horizontal swipe between Budget and Expense
                  physics: null,
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
                        _unfocusFields();
                        setState(() => _selectedAccount = account);
                        _refreshSaveState();
                      },
                      onCategorySelected: (category) {
                        _unfocusFields();
                        setState(() {
                          _selectedBudgetCategory = category;
                          final categoryExists = _categories.any(
                            (cat) => cat.id == category.id,
                          );
                          if (!categoryExists) {
                            _categories.insert(0, category);
                          } else {
                            // Only move to front if not already in first 7
                            final categoryIndex = _categories.indexWhere(
                              (cat) => cat.id == category.id,
                            );
                            if (categoryIndex >= 7) {
                              _categories.removeAt(categoryIndex);
                              _categories.insert(0, category);
                            }
                          }
                        });
                        _refreshSaveState();
                      },
                      onDateSelected: (date) {
                        _unfocusFields();
                        setState(() => _selectedBudgetDate = date);
                        _refreshSaveState();
                      },
                      onStartDateSelected: (date) {
                        _unfocusFields();
                        setState(() => _budgetStartDate = date);
                        _refreshSaveState();
                      },
                      onEndDateSelected: (date) {
                        _unfocusFields();
                        setState(() => _budgetEndDate = date);
                        _refreshSaveState();
                      },
                      onAddTag: (tag) {
                        _unfocusFields();
                        setState(() {
                          if (!_budgetTags.contains(tag)) {
                            _budgetTags.insert(0, tag);
                            _budgetSelectedTags.add(tag);
                          }
                        });
                        _refreshSaveState();
                      },
                      onToggleTag: (tag) {
                        _unfocusFields();
                        setState(() {
                          if (_budgetSelectedTags.contains(tag)) {
                            _budgetSelectedTags.remove(tag);
                          } else {
                            _budgetSelectedTags.add(tag);
                          }
                        });
                        _refreshSaveState();
                      },
                      onSave: _saveBudget,
                      onCategoriesChanged: _refreshCategories,
                    ),
                    AddExpenseForm(
                      selectedAccount: _selectedAccount,
                      photos: _expensePhotos,
                      categories: _categories,
                      selectedCategory: _selectedExpenseCategory,
                      selectedDate: _selectedExpenseDate,
                      tags: _expenseTags,
                      selectedTags: _expenseSelectedTags,
                      defaultCurrency: widget.themeProvider?.defaultCurrency,
                      themeProvider: widget.themeProvider,
                      amountFocusNode: _expenseAmountFocusNode,
                      amountController: _expenseAmountController,
                      commentController: _expenseCommentController,
                      onAccountSelected: (account) {
                        _unfocusFields();
                        setState(() {
                          _selectedAccount = account;
                        });
                        _refreshSaveState();
                      },
                      onPhotoTap: (slot) {
                        _unfocusFields();
                        _showExpensePhotoOptions(slot);
                      },
                      onPhotoDelete: (slot) {
                        _unfocusFields();
                        setState(() {
                          _expensePhotos[slot] = null;
                        });
                        _refreshSaveState();
                      },
                      onCategorySelected: (category) {
                        _unfocusFields();
                        setState(() {
                          _selectedExpenseCategory = category;
                          final categoryExists = _categories.any(
                            (cat) => cat.id == category.id,
                          );
                          if (!categoryExists) {
                            _categories.insert(0, category);
                          } else {
                            // Only move to front if not already in first 7
                            final categoryIndex = _categories.indexWhere(
                              (cat) => cat.id == category.id,
                            );
                            if (categoryIndex >= 7) {
                              _categories.removeAt(categoryIndex);
                              _categories.insert(0, category);
                            }
                          }
                        });
                        _refreshSaveState();
                      },
                      onDateSelected: (date) {
                        _unfocusFields();
                        setState(() => _selectedExpenseDate = date);
                        _refreshSaveState();
                      },
                      onAddTag: (tag) {
                        _unfocusFields();
                        setState(() {
                          if (!_expenseTags.contains(tag)) {
                            _expenseTags.insert(0, tag);
                            _expenseSelectedTags.add(tag);
                          }
                        });
                        _refreshSaveState();
                      },
                      onToggleTag: (tag) {
                        _unfocusFields();
                        setState(() {
                          if (_expenseSelectedTags.contains(tag)) {
                            _expenseSelectedTags.remove(tag);
                          } else {
                            _expenseSelectedTags.add(tag);
                          }
                        });
                        _refreshSaveState();
                      },
                      onSave: _saveExpense,
                      onCategoriesChanged: _refreshCategories,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          width: 200,
          child: FloatingActionButton.extended(
            onPressed: isSaveEnabled
                ? () async {
                    FocusScope.of(context).unfocus();
                    await saveAction();
                  }
                : null,
            elevation: isSaveEnabled ? 2 : 0,
            disabledElevation: 0,
            backgroundColor: isSaveEnabled
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withOpacity(0.2),
            foregroundColor: isSaveEnabled
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.primary.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            extendedPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            label: const Text(
              'Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  bool get _isBudgetFormValid {
    return _selectedAccount != null &&
        _selectedBudgetCategory != null &&
        _budgetAmountController.text.trim().isNotEmpty &&
        _budgetStartDate != null &&
        _budgetEndDate != null;
  }

  bool get _isExpenseFormValid {
    return _selectedExpenseCategory != null &&
        _expenseAmountController.text.trim().isNotEmpty;
  }

  Future<void> _showExpensePhotoOptions(int slot) async {
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
                    await _pickExpensePhoto(slot, ImageSource.camera);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickExpensePhoto(slot, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickExpensePhoto(int slot, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null && mounted) {
        setState(() {
          _expensePhotos[slot] = picked;
        });
        _refreshSaveState();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to pick photo: $e')),
        );
      }
    }
  }
}
