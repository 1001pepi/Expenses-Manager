import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:world_countries/world_countries.dart';

import '../database/database_helper.dart';
import '../widgets/calendar/date_picker_dialog.dart';
import '../widgets/calendar/week_picker_dialog.dart';
import '../widgets/calendar/month_picker_dialog.dart';
import '../widgets/calendar/period_picker_dialog.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../theme/theme_provider.dart';
import '../utils/date_format_utils.dart';
import '../widgets/config_drawer.dart';
import 'budget/budget_details_screen.dart';
import 'shared/add_financial_item_screen.dart';
import 'expense/expense_group_list_screen.dart';
import 'budget/budget_group_list_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.themeProvider,
  });

  final String title;
  final ThemeProvider themeProvider;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late Map<String, DateTime> _periodDates;
  DateTimeRange? _customPeriodRange;
  String _selectedTab = 'Month';
  late TabController _mainTabController;
  List<dynamic>? _cachedBudgetData;
  List<dynamic>? _cachedExpenseData;
  bool _mergeByCategory = false;
  bool _showRemaining = false;

  // Groups expenses by category and account for aggregated list view.
  List<_ExpenseGroup> _groupExpenses(List<Expense> expenses) {
    final Map<String, _ExpenseGroup> grouped = {};

    for (final expense in expenses) {
      final key = '${expense.categoryId}_${expense.accountId}';
      grouped.putIfAbsent(
        key,
        () => _ExpenseGroup(
          categoryId: expense.categoryId,
          accountId: expense.accountId,
          expenses: [],
        ),
      );
      grouped[key]!.expenses.add(expense);
    }

    return grouped.values.toList();
  }

  List<_ExpenseGroup> _groupExpensesByCategory(List<Expense> expenses) {
    final Map<int?, _ExpenseGroup> grouped = {};
    for (final expense in expenses) {
      final key = expense.categoryId;
      grouped.putIfAbsent(
        key,
        () => _ExpenseGroup(
          categoryId: expense.categoryId,
          accountId: null,
          expenses: [],
        ),
      );
      grouped[key]!.expenses.add(expense);
    }
    return grouped.values.toList();
  }

  List<_RemainingGroup> _calculateRemainingByCategory(
    List<Budget> budgets,
    List<Expense> expenses,
  ) {
    // Group budgets by category and account
    final Map<String, double> budgetsByCategoryAccount = {};
    for (final budget in budgets) {
      final key = '${budget.categoryId}_${budget.accountId}';
      budgetsByCategoryAccount[key] =
          (budgetsByCategoryAccount[key] ?? 0) + budget.amount;
    }

    // Group expenses by category and account
    final Map<String, double> expensesByCategoryAccount = {};
    for (final expense in expenses) {
      final key = '${expense.categoryId}_${expense.accountId}';
      expensesByCategoryAccount[key] =
          (expensesByCategoryAccount[key] ?? 0) + expense.amount;
    }

    // Create remaining groups for each category-account combination with a budget
    final List<_RemainingGroup> remaining = [];
    for (final entry in budgetsByCategoryAccount.entries) {
      final key = entry.key;
      final parts = key.split('_');
      final categoryId = int.tryParse(parts[0]);
      final accountId = int.tryParse(parts[1]);
      final budgetAmount = entry.value;
      final spentAmount = expensesByCategoryAccount[key] ?? 0;
      remaining.add(
        _RemainingGroup(
          categoryId: categoryId,
          accountId: accountId,
          budgetAmount: budgetAmount,
          spentAmount: spentAmount,
        ),
      );
    }

    return remaining;
  }

  List<_RemainingGroup> _mergeRemainingByCategory(
    List<_RemainingGroup> remainingGroups,
  ) {
    final Map<int?, _RemainingGroup> merged = {};
    for (final group in remainingGroups) {
      if (merged.containsKey(group.categoryId)) {
        final existing = merged[group.categoryId]!;
        merged[group.categoryId] = _RemainingGroup(
          categoryId: group.categoryId,
          accountId: null, // null indicates merged accounts
          budgetAmount: existing.budgetAmount + group.budgetAmount,
          spentAmount: existing.spentAmount + group.spentAmount,
        );
      } else {
        merged[group.categoryId] = _RemainingGroup(
          categoryId: group.categoryId,
          accountId: null,
          budgetAmount: group.budgetAmount,
          spentAmount: group.spentAmount,
        );
      }
    }
    return merged.values.toList();
  }

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(
      length: 2,
      vsync: this,
      animationDuration: Duration.zero,
    );
    final today = DateTime.now();
    _periodDates = {
      'Day': today,
      'Week': today,
      'Month': DateTime(today.year, today.month, 1),
      'Year': DateTime(today.year, 1, 1),
      'Period': today,
    };
  }

  List<_BudgetGroup> _groupBudgetsByCategory(List<Budget> budgets) {
    final Map<int?, _BudgetGroup> grouped = {};
    for (final budget in budgets) {
      final key = budget.categoryId;
      grouped.putIfAbsent(
        key,
        () => _BudgetGroup(
          categoryId: budget.categoryId,
          accountId: null,
          budgets: [],
        ),
      );
      grouped[key]!.budgets.add(budget);
    }
    return grouped.values.toList();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  void _updatePeriod(String tabName, int offset) {
    setState(() {
      final current = _periodDates[tabName] ?? DateTime.now();
      switch (tabName) {
        case 'Day':
          _periodDates[tabName] = current.add(Duration(days: offset));
          break;
        case 'Week':
          _periodDates[tabName] = current.add(Duration(days: offset * 7));
          break;
        case 'Month':
          _periodDates[tabName] = DateTime(
            current.year,
            current.month + offset,
            1,
          );
          break;
        case 'Year':
          _periodDates[tabName] = DateTime(current.year + offset, 1, 1);
          break;
        case 'Period':
          if (_customPeriodRange != null) {
            final spanDays = _customPeriodRange!.duration.inDays + 1;
            final delta = Duration(days: offset * spanDays);
            _customPeriodRange = DateTimeRange(
              start: _customPeriodRange!.start.add(delta),
              end: _customPeriodRange!.end.add(delta),
            );
          }
          break;
      }
    });
  }

  void _resetToCurrentPeriod(String tabName) {
    setState(() {
      final now = DateTime.now();
      switch (tabName) {
        case 'Day':
          _periodDates[tabName] = now;
          break;
        case 'Week':
          _periodDates[tabName] = now;
          break;
        case 'Month':
          _periodDates[tabName] = DateTime(now.year, now.month, 1);
          break;
        case 'Year':
          _periodDates[tabName] = DateTime(now.year, 1, 1);
          break;
        case 'Period':
          _customPeriodRange = null;
          _periodDates[tabName] = now;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const tabNames = ['Day', 'Week', 'Month', 'Year', 'Period'];

    return Scaffold(
      drawerEnableOpenDragGesture: false,
      drawer: ConfigDrawer(themeProvider: widget.themeProvider),
      appBar: AppBar(title: Text(widget.title), centerTitle: true),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _mainTabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.75),
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Budgets'),
                Tab(text: 'Expenses'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                _buildMainTabContent(context, tabNames, 'Budget'),
                _buildMainTabContent(context, tabNames, 'Expenses'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 100),
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    AddFinancialItemScreen(
                      initialTabIndex: _mainTabController.index,
                      themeProvider: widget.themeProvider,
                      selectedTab: _selectedTab,
                      periodDate: _periodDates[_selectedTab],
                      customPeriodRange: _customPeriodRange,
                    ),
              ),
            );

            if (result == true && mounted) {
              setState(() {});
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildMainTabContent(
    BuildContext context,
    List<String> tabNames,
    String mainTab,
  ) {
    final selectedTab = _selectedTab;
    final periodDate = _periodDates[selectedTab] ?? DateTime.now();
    final periodRange = _customPeriodRange;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildCustomMenu(context, tabNames),
          const SizedBox(height: 6),
          _buildPeriodHeader(context, selectedTab, periodDate, periodRange),
          const SizedBox(height: 6),
          Expanded(
            child: mainTab == 'Budget'
                ? _buildBudgetsContent(
                    context,
                    selectedTab,
                    periodDate,
                    periodRange,
                  )
                : _buildExpensesContent(
                    context,
                    selectedTab,
                    periodDate,
                    periodRange,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomMenu(BuildContext context, List<String> tabNames) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: tabNames.map((name) {
          final isSelected = _selectedTab == name;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.12)
                      : Colors.transparent,
                  foregroundColor: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.75),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () async {
                  if (name == 'Period') {
                    if (_customPeriodRange == null) {
                      final now = DateTime.now();
                      final picked = await showDialog<DateTimeRange>(
                        context: context,
                        builder: (context) => PeriodPickerDialog(
                          initialRange: DateTimeRange(
                            start: DateTime(now.year, now.month, now.day),
                            end: DateTime(now.year, now.month, now.day + 6),
                          ),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          helpText: 'Select Period',
                          onRangeSelected: (_) {},
                        ),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _customPeriodRange = picked;
                          _selectedTab = 'Period';
                        });
                      }
                      return;
                    }
                    if (mounted) setState(() => _selectedTab = 'Period');
                    return;
                  }

                  if (mounted) setState(() => _selectedTab = name);
                },
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPeriodHeader(
    BuildContext context,
    String tabName,
    DateTime periodDate,
    DateTimeRange? periodRange,
  ) {
    String periodText;

    if (tabName == 'Period' && periodRange != null) {
      if (periodRange.start.year == 2000 && periodRange.end.year >= 2100) {
        periodText = 'All time';
      } else {
        periodText = DateFormatUtils.getPeriodText(
          tabName,
          periodDate,
          customRange: periodRange,
        );
      }
    } else if (tabName == 'Period') {
      periodText = 'Select a period';
    } else {
      periodText = DateFormatUtils.getPeriodText(tabName, periodDate);
    }

    final bool showNavigation = tabName != 'Period';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showNavigation)
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _updatePeriod(tabName, -1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 24,
            )
          else
            const SizedBox(width: 28, height: 28),
          Expanded(
            child: GestureDetector(
              onTap: () => _showPeriodPicker(context, tabName),
              child: Center(
                child: Text(
                  periodText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (showNavigation)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _updatePeriod(tabName, 1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 24,
            )
          else
            const SizedBox(width: 28, height: 28),
          if (showNavigation)
            IconButton(
              icon: const Icon(Icons.today),
              tooltip: 'Today',
              onPressed: () => _resetToCurrentPeriod(tabName),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetsContent(
    BuildContext context,
    String tabName,
    DateTime periodDate,
    DateTimeRange? periodRange,
  ) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        DatabaseHelper.instance.getAllBudgets(),
        DatabaseHelper.instance.getAllCategories(),
        DatabaseHelper.instance.getAllAccounts(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading budgets: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        List<dynamic>? results;
        if (snapshot.hasData) {
          results = snapshot.data;
          _cachedBudgetData = results;
        } else if ((snapshot.connectionState == ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.active) &&
            _cachedBudgetData != null) {
          results = _cachedBudgetData;
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return const Center(child: Text('No data'));
        }

        results = results ?? [<dynamic>[], <Category>[], <Account>[]];
        final budgetMaps = results[0] as List<dynamic>;
        final categories = results.length > 1
            ? results[1] as List<Category>
            : <Category>[];
        final accounts = results.length > 2
            ? results[2] as List<Account>
            : <Account>[];
        final categoryMap = {
          for (final c in categories)
            if (c.id != null) c.id!: c,
        };
        final accountMap = {
          for (final a in accounts)
            if (a.id != null) a.id!: a,
        };

        final filteredBudgets = _filterBudgetsByPeriod(
          budgetMaps,
          tabName,
          periodDate,
          periodRange,
        );

        filteredBudgets.sort((a, b) => b.amount.compareTo(a.amount));

        final displayBudgets =
            (_mergeByCategory
                  ? _groupBudgetsByCategory(filteredBudgets)
                  : filteredBudgets
                        .map(
                          (b) => _BudgetGroup(
                            categoryId: b.categoryId,
                            accountId: b.accountId,
                            budgets: [b],
                          ),
                        )
                        .toList())
              ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

        final totalBudgetAmount = displayBudgets.fold<double>(
          0,
          (sum, group) => sum + group.totalAmount,
        );

        final categorySlices = _groupBudgetsByCategory(filteredBudgets)
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

        final percentAllocations = <int>[];
        if (totalBudgetAmount > 0 && displayBudgets.isNotEmpty) {
          final remainders = <Map<String, dynamic>>[];
          int floorSum = 0;

          for (int i = 0; i < displayBudgets.length; i++) {
            final raw =
                (displayBudgets[i].totalAmount / totalBudgetAmount) * 100;
            final base = raw.floor();
            percentAllocations.add(base);
            floorSum += base;
            remainders.add({'index': i, 'remainder': raw - base});
          }

          int remaining = 100 - floorSum;
          remainders.sort(
            (a, b) =>
                (b['remainder'] as double).compareTo(a['remainder'] as double),
          );

          for (int j = 0; j < remainders.length && remaining > 0; j++) {
            final idx = remainders[j]['index'] as int;
            percentAllocations[idx] += 1;
            remaining -= 1;
          }
        }

        final primaryAccount = filteredBudgets.isNotEmpty
            ? accountMap[filteredBudgets.first.accountId]
            : null;
        final totalCurrencySymbol = _currencySymbol(primaryAccount?.currency);

        if (filteredBudgets.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(32.0, 80.0, 32.0, 32.0),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Budgets',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You haven\'t set any budget for this period.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0.0, bottom: 8.0),
              child: _BudgetPieChart(
                total: totalBudgetAmount,
                slices: [
                  for (final g in categorySlices)
                    _PieSliceData(
                      value: g.totalAmount,
                      color: Color(
                        categoryMap[g.categoryId]?.color ??
                            Theme.of(context).colorScheme.primary.value,
                      ),
                    ),
                ],
                label:
                    '$totalCurrencySymbol${_formatAmount(totalBudgetAmount)}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() => _mergeByCategory = !_mergeByCategory);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _mergeByCategory
                          ? Theme.of(
                              context,
                            ).colorScheme.primaryContainer.withOpacity(0.55)
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary
                            .withOpacity(_mergeByCategory ? 0.5 : 0.25),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _mergeByCategory,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(
                            horizontal: -4,
                            vertical: -4,
                          ),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.45),
                            width: 1.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          fillColor: MaterialStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(MaterialState.selected)) {
                              return Theme.of(context).colorScheme.primary;
                            }
                            if (states.contains(MaterialState.pressed) ||
                                states.contains(MaterialState.hovered)) {
                              return Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.3);
                            }
                            return Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.12);
                          }),
                          checkColor: Theme.of(context).colorScheme.onPrimary,
                          onChanged: (val) {
                            setState(() => _mergeByCategory = val ?? false);
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Merge accounts',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _mergeByCategory
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(
                  left: 4,
                  right: 4,
                  top: 4,
                  bottom: 100,
                ),
                itemCount: displayBudgets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final group = displayBudgets[index];
                  final category = categoryMap[group.categoryId];
                  final account = accountMap[group.accountId];
                  final accountForDisplay =
                      _mergeByCategory && group.budgets.length == 1
                      ? accountMap[group.budgets.first.accountId]
                      : account;
                  final categoryColor = category != null
                      ? Color(category.color)
                      : Theme.of(context).colorScheme.primary;
                  final categoryIcon = category != null
                      ? IconData(category.iconCode, fontFamily: 'MaterialIcons')
                      : Icons.category;
                  final rowCurrencySymbol = accountForDisplay != null
                      ? _currencySymbol(accountForDisplay.currency)
                      : totalCurrencySymbol;
                  final amountText = _formatAmount(group.totalAmount);
                  final percentValue = index < percentAllocations.length
                      ? percentAllocations[index]
                      : 0;
                  final percentText = '$percentValue%';

                  final cardColor = Theme.of(
                    context,
                  ).colorScheme.surfaceVariant;
                  return GestureDetector(
                    onTap: () async {
                      if (group.budgets.length > 1) {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BudgetGroupListScreen(
                              budgets: group.budgets,
                              account: account,
                              category: category,
                              themeProvider: widget.themeProvider,
                            ),
                          ),
                        );

                        if (updated == true && mounted) {
                          setState(() {});
                        }
                        return;
                      }

                      final targetBudget = group.budgets.first;
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BudgetDetailsScreen(
                            budget: targetBudget,
                            account: accountForDisplay,
                            category: category,
                            themeProvider: widget.themeProvider,
                          ),
                        ),
                      );
                      if (updated == true && mounted) {
                        setState(() {});
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.12),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.shadow.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final rowWidth = constraints.maxWidth;
                          final iconWidth = rowWidth * 0.10;
                          final gapSmall = rowWidth * 0.035;
                          final nameWidth = rowWidth * 0.37;
                          final accountWidth = rowWidth * 0.16;
                          final percentWidth = rowWidth * 0.12;
                          final gapMedium = rowWidth * 0.03;
                          final amountWidth = rowWidth * 0.15;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: iconWidth,
                                child: Center(
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: categoryColor,
                                    child: Icon(
                                      categoryIcon,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: gapSmall),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: nameWidth,
                                          child: Text(
                                            category?.name ?? 'Budget',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: accountWidth,
                                          child: Text(
                                            _mergeByCategory &&
                                                    group.budgets.length > 1
                                                ? 'Merged'
                                                : _mergeByCategory &&
                                                      group.budgets.length == 1
                                                ? (accountForDisplay?.name ??
                                                      'Account')
                                                : account?.name ?? 'Account',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color:
                                                  _mergeByCategory &&
                                                      group.budgets.length > 1
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.secondary
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: gapSmall),
                                        SizedBox(
                                          width: percentWidth,
                                          child: Text(
                                            percentText,
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.85),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: gapMedium),
                                        SizedBox(
                                          width: amountWidth,
                                          child: Text(
                                            '$rowCurrencySymbol$amountText',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpensesContent(
    BuildContext context,
    String selectedTab,
    DateTime periodDate,
    DateTimeRange? periodRange,
  ) {
    final theme = Theme.of(context);
    return FutureBuilder(
      future: _showRemaining
          ? Future.wait([
              DatabaseHelper.instance.getAllExpenses(),
              DatabaseHelper.instance.getAllCategories(),
              DatabaseHelper.instance.getAllAccounts(),
              DatabaseHelper.instance.getAllBudgets(),
            ])
          : Future.wait([
              DatabaseHelper.instance.getAllExpenses(),
              DatabaseHelper.instance.getAllCategories(),
              DatabaseHelper.instance.getAllAccounts(),
            ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<dynamic>? results;
        if (snapshot.hasData) {
          results = snapshot.data;
          _cachedExpenseData = results;
        } else if ((snapshot.connectionState == ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.active) &&
            _cachedExpenseData != null) {
          results = _cachedExpenseData;
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return const Center(child: Text('No data'));
        }

        results = results ?? [<Expense>[], <Category>[], <Account>[]];
        final expenses = results[0] as List<Expense>;
        final categories = results.length > 1
            ? results[1] as List<Category>
            : <Category>[];
        final accounts = results.length > 2
            ? results[2] as List<Account>
            : <Account>[];

        // Convert budget maps to Budget objects if available
        // Keep raw budget maps for filtering
        final budgetMaps = _showRemaining && results.length > 3
            ? results[3] as List<dynamic>
            : <dynamic>[];

        final categoryMap = {
          for (final c in categories)
            if (c.id != null) c.id!: c,
        };
        final accountMap = {
          for (final a in accounts)
            if (a.id != null) a.id!: a,
        };

        final filteredExpenses = _filterExpensesByPeriod(
          expenses,
          selectedTab,
          periodDate,
          periodRange,
        );

        filteredExpenses.sort((a, b) => b.date.compareTo(a.date));

        // Filter budgets by period if showing remaining view
        final filteredBudgets = _showRemaining
            ? _filterBudgetsByPeriod(
                budgetMaps,
                selectedTab,
                periodDate,
                periodRange,
              )
            : <Budget>[];

        final groupedExpenses =
            (_mergeByCategory
                  ? _groupExpensesByCategory(filteredExpenses)
                  : _groupExpenses(filteredExpenses))
              ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

        final categorySlices = _groupExpensesByCategory(filteredExpenses)
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        final totalExpenseAmount = groupedExpenses.fold<double>(
          0,
          (sum, group) => sum + group.totalAmount,
        );

        // Calculate remaining budget groups
        final remainingGroups = _showRemaining
            ? () {
                final groups = _calculateRemainingByCategory(
                  filteredBudgets,
                  filteredExpenses,
                );
                final processedGroups = _mergeByCategory
                    ? _mergeRemainingByCategory(groups)
                    : groups;
                return processedGroups
                  ..sort((a, b) => b.remaining.compareTo(a.remaining));
              }()
            : <_RemainingGroup>[];

        final percentAllocations = <int>[];
        if (totalExpenseAmount > 0 && groupedExpenses.isNotEmpty) {
          final remainders = <Map<String, dynamic>>[];
          int floorSum = 0;

          for (int i = 0; i < groupedExpenses.length; i++) {
            final raw =
                (groupedExpenses[i].totalAmount / totalExpenseAmount) * 100;
            final base = raw.floor();
            percentAllocations.add(base);
            floorSum += base;
            remainders.add({'index': i, 'remainder': raw - base});
          }

          int remaining = 100 - floorSum;
          remainders.sort(
            (a, b) =>
                (b['remainder'] as double).compareTo(a['remainder'] as double),
          );

          for (int j = 0; j < remainders.length && remaining > 0; j++) {
            final idx = remainders[j]['index'] as int;
            percentAllocations[idx] += 1;
            remaining -= 1;
          }
        }

        final primaryAccount = filteredExpenses.isNotEmpty
            ? accountMap[filteredExpenses.first.accountId]
            : null;
        final totalCurrencySymbol = _currencySymbol(primaryAccount?.currency);

        // Calculate total remaining for pie chart when showing remaining view
        final totalRemaining = _showRemaining
            ? remainingGroups.fold<double>(
                0,
                (sum, group) => sum + group.remaining,
              )
            : 0.0;

        if (filteredExpenses.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(32.0, 80.0, 32.0, 32.0),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Expenses',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You haven\'t recorded any expenses for this period.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0.0, bottom: 6.0),
              child: _BudgetPieChart(
                total: _showRemaining ? totalRemaining : totalExpenseAmount,
                slices: _showRemaining
                    ? [
                        for (final g in remainingGroups)
                          if (g.remaining > 0)
                            _PieSliceData(
                              value: g.remaining,
                              color: Color(
                                categoryMap[g.categoryId]?.color ??
                                    Theme.of(context).colorScheme.primary.value,
                              ),
                            ),
                      ]
                    : [
                        for (final g in categorySlices)
                          _PieSliceData(
                            value: g.totalAmount,
                            color: Color(
                              categoryMap[g.categoryId]?.color ??
                                  Theme.of(context).colorScheme.primary.value,
                            ),
                          ),
                      ],
                label: _showRemaining
                    ? '$totalCurrencySymbol${_formatAmount(totalRemaining)}'
                    : '$totalCurrencySymbol${_formatAmount(totalExpenseAmount)}',
                labelColor: _showRemaining && totalRemaining < 0
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() => _mergeByCategory = !_mergeByCategory);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _mergeByCategory
                              ? Theme.of(
                                  context,
                                ).colorScheme.primaryContainer.withOpacity(0.55)
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary
                                .withOpacity(_mergeByCategory ? 0.5 : 0.25),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _mergeByCategory,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: const VisualDensity(
                                horizontal: -4,
                                vertical: -4,
                              ),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.45),
                                width: 1.3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              fillColor: MaterialStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(MaterialState.selected)) {
                                  return Theme.of(context).colorScheme.primary;
                                }
                                if (states.contains(MaterialState.pressed) ||
                                    states.contains(MaterialState.hovered)) {
                                  return Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.3);
                                }
                                return Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.12);
                              }),
                              checkColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              onChanged: (val) {
                                setState(() => _mergeByCategory = val ?? false);
                              },
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Merge accounts',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: _mergeByCategory
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() => _showRemaining = !_showRemaining);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _showRemaining
                              ? Theme.of(
                                  context,
                                ).colorScheme.primaryContainer.withOpacity(0.55)
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary
                                .withOpacity(_showRemaining ? 0.5 : 0.25),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _showRemaining,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: const VisualDensity(
                                horizontal: -4,
                                vertical: -4,
                              ),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.45),
                                width: 1.3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              fillColor: MaterialStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(MaterialState.selected)) {
                                  return Theme.of(context).colorScheme.primary;
                                }
                                if (states.contains(MaterialState.pressed) ||
                                    states.contains(MaterialState.hovered)) {
                                  return Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.3);
                                }
                                return Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.12);
                              }),
                              checkColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              onChanged: (val) {
                                setState(() => _showRemaining = val ?? false);
                              },
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Remaining',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: _showRemaining
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _showRemaining
                  ? _buildRemainingList(
                      remainingGroups,
                      categoryMap,
                      accountMap,
                      totalCurrencySymbol,
                      theme,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(
                        left: 4,
                        right: 4,
                        top: 4,
                        bottom: 100,
                      ),
                      itemCount: groupedExpenses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final group = groupedExpenses[index];
                        final category = categoryMap[group.categoryId];
                        final account = accountMap[group.accountId];
                        final accountForDisplay =
                            _mergeByCategory && group.expenses.length == 1
                            ? accountMap[group.expenses.first.accountId]
                            : account;
                        final categoryColor = category != null
                            ? Color(category.color)
                            : Theme.of(context).colorScheme.primary;
                        final categoryIcon = category != null
                            ? IconData(
                                category.iconCode,
                                fontFamily: 'MaterialIcons',
                              )
                            : Icons.category;
                        final rowCurrencySymbol = accountForDisplay != null
                            ? _currencySymbol(accountForDisplay.currency)
                            : totalCurrencySymbol;
                        final amountText = _formatAmount(group.totalAmount);

                        final cardColor = theme.colorScheme.surfaceVariant;
                        return GestureDetector(
                          onTap: () async {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExpenseGroupListScreen(
                                  expenses: group.expenses,
                                  account: account,
                                  category: category,
                                  themeProvider: widget.themeProvider,
                                  selectedTab: selectedTab,
                                  periodDate: periodDate,
                                  periodRange: periodRange,
                                ),
                              ),
                            );
                            if (updated == true && mounted) setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.12),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.shadow.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final rowWidth = constraints.maxWidth;
                                final iconWidth = rowWidth * 0.10;
                                final gapSmall = rowWidth * 0.035;
                                final nameWidth = rowWidth * 0.37;
                                final accountWidth = rowWidth * 0.16;
                                final percentWidth = rowWidth * 0.12;
                                final gapMedium = rowWidth * 0.03;
                                final amountWidth = rowWidth * 0.15;

                                final percentValue =
                                    index < percentAllocations.length
                                    ? percentAllocations[index]
                                    : 0;
                                final percentText = '$percentValue%';

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: iconWidth,
                                      child: Center(
                                        child: CircleAvatar(
                                          radius: 18,
                                          backgroundColor: categoryColor,
                                          child: Icon(
                                            categoryIcon,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: gapSmall),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: nameWidth,
                                                child: Text(
                                                  category?.name ?? 'Expense',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: accountWidth,
                                                child: Builder(
                                                  builder: (context) {
                                                    // Check if expenses come from different accounts
                                                    final hasMultipleAccounts =
                                                        _mergeByCategory &&
                                                        group
                                                            .expenses
                                                            .isNotEmpty &&
                                                        group.expenses
                                                                .map(
                                                                  (e) => e
                                                                      .accountId,
                                                                )
                                                                .toSet()
                                                                .length >
                                                            1;

                                                    final displayText =
                                                        hasMultipleAccounts
                                                        ? 'Merged'
                                                        : (accountForDisplay
                                                                  ?.name ??
                                                              'Account');

                                                    return Text(
                                                      displayText,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign: TextAlign.left,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                        color:
                                                            hasMultipleAccounts
                                                            ? Theme.of(context)
                                                                  .colorScheme
                                                                  .secondary
                                                            : Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                    0.8,
                                                                  ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: gapSmall),
                                              SizedBox(
                                                width: percentWidth,
                                                child: Text(
                                                  percentText,
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.85),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: gapMedium),
                                              SizedBox(
                                                width: amountWidth,
                                                child: Text(
                                                  '$rowCurrencySymbol$amountText',
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _formatAmount(double amount) {
    String addCommas(String value) {
      final parts = value.split('.');
      final integerPart = parts[0];
      final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

      // Handle negative sign separately
      final isNegative = integerPart.startsWith('-');
      final absoluteInteger = isNegative
          ? integerPart.substring(1)
          : integerPart;

      final buffer = StringBuffer();
      if (isNegative) {
        buffer.write('-');
      }

      for (int i = 0; i < absoluteInteger.length; i++) {
        if (i > 0 && (absoluteInteger.length - i) % 3 == 0) {
          buffer.write(',');
        }
        buffer.write(absoluteInteger[i]);
      }
      return buffer.toString() + decimalPart;
    }

    if (amount % 1 == 0) {
      return addCommas(amount.toStringAsFixed(0));
    }

    final trimmed = amount.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
    final cleaned = trimmed.endsWith('.')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return addCommas(cleaned);
  }

  Widget _buildRemainingList(
    List<_RemainingGroup> remainingGroups,
    Map<int?, Category> categoryMap,
    Map<int?, Account> accountMap,
    String totalCurrencySymbol,
    ThemeData theme,
  ) {
    if (remainingGroups.isEmpty) {
      return Center(
        child: Text(
          'No budgets for this period',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 100),
      itemCount: remainingGroups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final remaining = remainingGroups[index];
        final category = categoryMap[remaining.categoryId];
        final account = accountMap[remaining.accountId];
        final categoryColor = category != null
            ? Color(category.color)
            : Theme.of(context).colorScheme.primary;
        final categoryIcon = category != null
            ? IconData(category.iconCode, fontFamily: 'MaterialIcons')
            : Icons.category;

        final budgetText = _formatAmount(remaining.budgetAmount);
        final spentText = _formatAmount(remaining.spentAmount);
        final remainingText = _formatAmount(remaining.remaining);

        final cardColor = theme.colorScheme.surfaceVariant;
        final isOverBudget = remaining.remaining < 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rowWidth = constraints.maxWidth;
              final iconWidth = rowWidth * 0.10;
              final gapSmall = rowWidth * 0.035;
              final nameWidth = rowWidth * 0.32;
              final budgetWidth = rowWidth * 0.18;
              final spentWidth = rowWidth * 0.18;
              final remainingWidth = rowWidth * 0.17;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: iconWidth,
                    child: Center(
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: categoryColor,
                        child: Icon(
                          categoryIcon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: gapSmall),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: nameWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                category?.name ?? 'Category',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (remaining.accountId != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  account?.name ?? 'Account',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.65),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(
                          width: budgetWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Budget',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                '$totalCurrencySymbol$budgetText',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: spentWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Spent',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                '$totalCurrencySymbol$spentText',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: remainingWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Remaining',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                '$totalCurrencySymbol$remainingText',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isOverBudget
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _currencySymbol(String? code) {
    if (code == null || code.isEmpty) return '';

    final currency = FiatCurrency.list.firstWhere(
      (c) => c.code == code,
      orElse: () => FiatCurrency.list.first,
    );

    return currency.symbol ?? '';
  }

  List<Budget> _filterBudgetsByPeriod(
    List<dynamic> budgets,
    String tabName,
    DateTime periodDate,
    DateTimeRange? periodRange,
  ) {
    DateTime endOfDay(DateTime d) =>
        DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

    return budgets
        .map((budgetMap) => Budget.fromMap(budgetMap as Map<String, dynamic>))
        .where((budget) {
          late DateTime rangeStart;
          late DateTime rangeEnd;

          switch (tabName) {
            case 'Period':
              if (periodRange == null) return false;
              rangeStart = DateTime(
                periodRange.start.year,
                periodRange.start.month,
                periodRange.start.day,
              );
              rangeEnd = endOfDay(periodRange.end);
              break;
            case 'Day':
              rangeStart = DateTime(
                periodDate.year,
                periodDate.month,
                periodDate.day,
              );
              rangeEnd = endOfDay(periodDate);
              break;
            case 'Week':
              final weekStart = periodDate.subtract(
                Duration(days: periodDate.weekday - 1),
              );
              rangeStart = DateTime(
                weekStart.year,
                weekStart.month,
                weekStart.day,
              );
              rangeEnd = endOfDay(rangeStart.add(const Duration(days: 6)));
              break;
            case 'Month':
              rangeStart = DateTime(periodDate.year, periodDate.month, 1);
              rangeEnd = endOfDay(
                DateTime(periodDate.year, periodDate.month + 1, 0),
              );
              break;
            case 'Year':
              rangeStart = DateTime(periodDate.year, 1, 1);
              rangeEnd = endOfDay(DateTime(periodDate.year + 1, 1, 0));
              break;
            default:
              return false;
          }

          // Normalize budget dates to start/end of day for comparison
          final budgetStart = DateTime(
            budget.startDate.year,
            budget.startDate.month,
            budget.startDate.day,
          );
          final budgetEnd = DateTime(
            budget.endDate.year,
            budget.endDate.month,
            budget.endDate.day,
            23,
            59,
            59,
            999,
          );

          final budgetStartInRange =
              !budgetStart.isBefore(rangeStart) &&
              !budgetStart.isAfter(rangeEnd);
          final budgetEndInRange =
              !budgetEnd.isBefore(rangeStart) && !budgetEnd.isAfter(rangeEnd);
          return budgetStartInRange && budgetEndInRange;
        })
        .toList();
  }

  List<Expense> _filterExpensesByPeriod(
    List<Expense> expenses,
    String tabName,
    DateTime periodDate,
    DateTimeRange? periodRange,
  ) {
    DateTime endOfDay(DateTime d) =>
        DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

    return expenses.where((expense) {
      late DateTime rangeStart;
      late DateTime rangeEnd;

      switch (tabName) {
        case 'Period':
          if (periodRange == null) return false;
          rangeStart = DateTime(
            periodRange.start.year,
            periodRange.start.month,
            periodRange.start.day,
          );
          rangeEnd = endOfDay(periodRange.end);
          break;
        case 'Day':
          rangeStart = DateTime(
            periodDate.year,
            periodDate.month,
            periodDate.day,
          );
          rangeEnd = endOfDay(periodDate);
          break;
        case 'Week':
          rangeStart = periodDate.subtract(
            Duration(days: periodDate.weekday - 1),
          );
          rangeEnd = endOfDay(rangeStart.add(const Duration(days: 6)));
          break;
        case 'Month':
          rangeStart = DateTime(periodDate.year, periodDate.month, 1);
          rangeEnd = endOfDay(
            DateTime(periodDate.year, periodDate.month + 1, 0),
          );
          break;
        case 'Year':
          rangeStart = DateTime(periodDate.year, 1, 1);
          rangeEnd = endOfDay(DateTime(periodDate.year + 1, 1, 0));
          break;
        default:
          return false;
      }

      return !expense.date.isBefore(rangeStart) &&
          !expense.date.isAfter(rangeEnd);
    }).toList();
  }

  Future<void> _showPeriodPicker(BuildContext context, String tabName) async {
    final currentDate = _periodDates[tabName] ?? DateTime.now();

    switch (tabName) {
      case 'Day':
        final pickedDay = await showDialog<DateTime>(
          context: context,
          builder: (context) => CustomDatePickerDialog(
            initialDate: currentDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            helpText: 'Select Day',
            onDateSelected: (_) {},
          ),
        );
        if (pickedDay != null && mounted) {
          setState(() => _periodDates[tabName] = pickedDay);
        }
        break;
      case 'Week':
        final pickedWeek = await showDialog<DateTime>(
          context: context,
          builder: (context) => WeekPickerDialog(
            initialDate: currentDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            helpText: 'Select Week',
            onDateSelected: (_) {},
          ),
        );
        if (pickedWeek != null && mounted) {
          setState(() => _periodDates[tabName] = pickedWeek);
        }
        break;
      case 'Month':
        final pickedMonth = await showDialog<DateTime>(
          context: context,
          builder: (context) => MonthPickerDialog(
            initialDate: currentDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            helpText: 'Select Month',
            onDateSelected: (_) {},
          ),
        );
        if (pickedMonth != null && mounted) {
          setState(
            () => _periodDates[tabName] = DateTime(
              pickedMonth.year,
              pickedMonth.month,
              1,
            ),
          );
        }
        break;
      case 'Year':
        // Year selection disabled - do nothing
        break;
      case 'Period':
        final now = DateTime.now();
        final pickedRange = await showDialog<DateTimeRange>(
          context: context,
          builder: (context) => PeriodPickerDialog(
            initialRange:
                _customPeriodRange ??
                DateTimeRange(
                  start: DateTime(now.year, now.month, now.day),
                  end: DateTime(now.year, now.month, now.day + 6),
                ),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            helpText: 'Select Period',
            onRangeSelected: (_) {},
          ),
        );
        if (pickedRange != null && mounted) {
          setState(() {
            _customPeriodRange = pickedRange;
            _selectedTab = 'Period';
          });
        }
        break;
    }
  }
}

class _ExpenseGroup {
  _ExpenseGroup({
    required this.categoryId,
    required this.accountId,
    required this.expenses,
  });

  final int? categoryId;
  final int? accountId;
  final List<Expense> expenses;

  double get totalAmount => expenses.fold(0, (sum, e) => sum + e.amount);
}

class _BudgetGroup {
  _BudgetGroup({
    required this.categoryId,
    required this.accountId,
    required this.budgets,
  });

  final int? categoryId;
  final int? accountId;
  final List<Budget> budgets;

  double get totalAmount => budgets.fold(0, (sum, b) => sum + b.amount);
}

class _RemainingGroup {
  _RemainingGroup({
    required this.categoryId,
    required this.accountId,
    required this.budgetAmount,
    required this.spentAmount,
  });

  final int? categoryId;
  final int? accountId;
  final double budgetAmount;
  final double spentAmount;

  double get remaining => budgetAmount - spentAmount;
}

class _PieSliceData {
  const _PieSliceData({required this.value, required this.color});

  final double value;
  final Color color;
}

class _BudgetPieChart extends StatelessWidget {
  const _BudgetPieChart({
    required this.total,
    required this.slices,
    required this.label,
    this.labelColor,
  });

  final double total;
  final List<_PieSliceData> slices;
  final String label;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final hasData = total > 0 && slices.any((s) => s.value > 0);
    final chartSize = 220.0;

    return SizedBox(
      height: chartSize,
      width: chartSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(chartSize, chartSize),
            painter: _PieChartPainter(
              slices: slices,
              total: hasData ? total : 1,
              baseColor: Theme.of(context).colorScheme.surfaceVariant,
              shadowColor: Theme.of(
                context,
              ).colorScheme.shadow.withOpacity(hasData ? 0.12 : 0.08),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: labelColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({
    required this.slices,
    required this.total,
    required this.baseColor,
    required this.shadowColor,
  });

  final List<_PieSliceData> slices;
  final double total;
  final Color baseColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.30;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth);

    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawArc(rect, 0, 2 * math.pi, false, shadowPaint);
    canvas.drawArc(rect, 0, 2 * math.pi, false, basePaint);

    double startAngle = -math.pi / 2;
    for (final slice in slices) {
      if (slice.value <= 0 || total <= 0) continue;
      final sweepAngle = (slice.value / total) * 2 * math.pi;
      final slicePaint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, slicePaint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    if (oldDelegate.total != total ||
        oldDelegate.slices.length != slices.length) {
      return true;
    }
    for (int i = 0; i < slices.length; i++) {
      if (slices[i].value != oldDelegate.slices[i].value ||
          slices[i].color != oldDelegate.slices[i].color) {
        return true;
      }
    }
    return false;
  }
}
