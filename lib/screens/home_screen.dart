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
import 'budget_details_screen.dart';
import 'edit_budget_screen.dart';
import 'add_financial_item_screen.dart';

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

  List<int> _allocatePercentages(List<Budget> budgets, double total) {
    if (total <= 0 || budgets.isEmpty) {
      return List<int>.filled(budgets.length, 0);
    }

    final allocations = <int>[];
    final remainders = <Map<String, dynamic>>[];
    int floorSum = 0;

    for (int i = 0; i < budgets.length; i++) {
      final raw = (budgets[i].amount / total) * 100;
      final base = raw.floor();
      allocations.add(base);
      floorSum += base;
      remainders.add({'index': i, 'remainder': raw - base});
    }

    int remaining = 100 - floorSum;
    remainders.sort(
      (a, b) => (b['remainder'] as double).compareTo(a['remainder'] as double),
    );

    for (int j = 0; j < remainders.length && remaining > 0; j++) {
      final idx = remainders[j]['index'] as int;
      allocations[idx] += 1;
      remaining -= 1;
    }

    return allocations;
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

        final totalBudgetAmount = filteredBudgets.fold<double>(
          0,
          (sum, budget) => sum + budget.amount,
        );

        final percentAllocations = _allocatePercentages(
          filteredBudgets,
          totalBudgetAmount,
        );

        final primaryAccount = filteredBudgets.isNotEmpty
            ? accountMap[filteredBudgets[0].accountId]
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
                  'No Budget',
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
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _BudgetPieChart(
                total: totalBudgetAmount,
                slices: [
                  for (final b in filteredBudgets)
                    _PieSliceData(
                      value: b.amount,
                      color: Color(
                        categoryMap[b.categoryId]?.color ??
                            Theme.of(context).colorScheme.primary.value,
                      ),
                    ),
                ],
                label:
                    '$totalCurrencySymbol${_formatAmount(totalBudgetAmount)}',
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
                itemCount: filteredBudgets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final budget = filteredBudgets[index];
                  final category = categoryMap[budget.categoryId];
                  final account = accountMap[budget.accountId];
                  final categoryColor = category != null
                      ? Color(category.color)
                      : Theme.of(context).colorScheme.primary;
                  final categoryIcon = category != null
                      ? IconData(category.iconCode, fontFamily: 'MaterialIcons')
                      : Icons.category;
                  final currencySymbol = _currencySymbol(account?.currency);
                  final amountText = _formatAmount(budget.amount);
                  final percentValue = index < percentAllocations.length
                      ? percentAllocations[index]
                      : 0;
                  final percentText = '$percentValue%';

                  final cardColor = Theme.of(
                    context,
                  ).colorScheme.surfaceVariant;
                  return GestureDetector(
                    onTap: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BudgetDetailsScreen(
                            budget: budget,
                            account: account,
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
                                            account?.name ?? 'Account',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.left,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
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
                                            '$currencySymbol$amountText',
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
    return FutureBuilder(
      future: Future.wait([
        DatabaseHelper.instance.getAllExpenses(),
        DatabaseHelper.instance.getAllCategories(),
        DatabaseHelper.instance.getAllAccounts(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final expenses = snapshot.data?[0] as List<Expense>? ?? [];
        final categories = snapshot.data?[1] as List<Category>? ?? [];
        final accounts = snapshot.data?[2] as List<Account>? ?? [];

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

        final totalExpenseAmount = filteredExpenses.fold<double>(
          0,
          (sum, expense) => sum + expense.amount,
        );

        final primaryAccount = filteredExpenses.isNotEmpty
            ? accountMap[filteredExpenses[0].accountId]
            : null;
        final totalCurrencySymbol = _currencySymbol(primaryAccount?.currency);

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
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Expenses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '$totalCurrencySymbol${_formatAmount(totalExpenseAmount)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
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
                itemCount: filteredExpenses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final expense = filteredExpenses[index];
                  final category = categoryMap[expense.categoryId];
                  final account = accountMap[expense.accountId];
                  final categoryColor = category != null
                      ? Color(category.color)
                      : Theme.of(context).colorScheme.primary;
                  final categoryIcon = category != null
                      ? IconData(category.iconCode, fontFamily: 'MaterialIcons')
                      : Icons.category;
                  final currencySymbol = _currencySymbol(account?.currency);
                  final amountText = _formatAmount(expense.amount);

                  final cardColor = Theme.of(
                    context,
                  ).colorScheme.surfaceVariant;
                  return GestureDetector(
                    onTap: () async {
                      // TODO: Navigate to expense details/edit screen
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
                          final nameWidth = rowWidth * 0.40;
                          final accountWidth = rowWidth * 0.18;
                          final gapMedium = rowWidth * 0.03;
                          final amountWidth = rowWidth * 0.20;

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
                                            category?.name ?? 'Expense',
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
                                            account?.name ?? 'Account',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.left,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: gapMedium),
                                        SizedBox(
                                          width: amountWidth,
                                          child: Text(
                                            '$currencySymbol$amountText',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormatUtils.formatDate(
                                            expense.date,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                        if (expense.photo1Path != null ||
                                            expense.photo2Path != null) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.photo,
                                            size: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (expense.tags.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tags: ${expense.tags}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (expense.comment != null &&
                                        expense.comment!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        expense.comment!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
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

      final buffer = StringBuffer();
      for (int i = 0; i < integerPart.length; i++) {
        if (i > 0 && (integerPart.length - i) % 3 == 0) {
          buffer.write(',');
        }
        buffer.write(integerPart[i]);
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

          final overlaps =
              !budget.startDate.isAfter(rangeEnd) &&
              !budget.endDate.isBefore(rangeStart);
          return overlaps;
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

  Future<DateTime?> _pickSingleDate(
    BuildContext context,
    DateTime initialDate,
  ) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<DateTimeRange?> _showDateRangePicker(
    BuildContext context, {
    DateTimeRange? initialRange,
  }) async {
    final now = DateTime.now();
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange:
          initialRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day + 6),
          ),
    );
  }
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
  });

  final double total;
  final List<_PieSliceData> slices;
  final String label;

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
              color: Theme.of(context).colorScheme.primary,
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
