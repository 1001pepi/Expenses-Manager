import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:world_countries/world_countries.dart';

import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/expense.dart';
import '../../theme/theme_provider.dart';
import '../../database/database_helper.dart';
import 'expense_details_screen.dart';
import '../shared/add_financial_item_screen.dart';

class ExpenseGroupListScreen extends StatefulWidget {
  const ExpenseGroupListScreen({
    super.key,
    required this.expenses,
    required this.account,
    required this.category,
    required this.themeProvider,
    required this.selectedTab,
    required this.periodDate,
    required this.periodRange,
  });

  final List<Expense> expenses;
  final Account? account;
  final Category? category;
  final ThemeProvider themeProvider;
  final String selectedTab;
  final DateTime periodDate;
  final DateTimeRange? periodRange;

  @override
  State<ExpenseGroupListScreen> createState() => _ExpenseGroupListScreenState();
}

class _ExpenseGroupListScreenState extends State<ExpenseGroupListScreen> {
  late List<Expense> _expenses;
  bool _hasChanges = false;
  bool _sortAscending = false; // false = newest first, true = oldest first

  @override
  void initState() {
    super.initState();
    _expenses = [...widget.expenses]..sort((a, b) => b.date.compareTo(a.date));
  }

  String _currencySymbol(String? code) {
    if (code == null || code.isEmpty) return '';
    final currency = FiatCurrency.list.firstWhere(
      (c) => c.code == code,
      orElse: () => FiatCurrency.list.first,
    );
    return currency.symbol ?? '';
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(amount);
  }

  String _formatDateHeader(DateTime date) {
    // Format: "02 January 2025"
    final day = DateFormat('dd').format(date);
    final month = DateFormat('MMMM').format(date);
    final year = DateFormat('yyyy').format(date);
    return '$day $month $year';
  }

  Map<String, List<Expense>> _groupExpensesByDate() {
    final Map<String, List<Expense>> grouped = {};
    for (final expense in _expenses) {
      final dateKey = DateFormat('yyyy-MM-dd').format(expense.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(expense);
    }
    return grouped;
  }

  bool _isExpenseInPeriod(DateTime expenseDate) {
    final periodDate = widget.periodDate;
    switch (widget.selectedTab) {
      case 'Day':
        return expenseDate.year == periodDate.year &&
            expenseDate.month == periodDate.month &&
            expenseDate.day == periodDate.day;
      case 'Week':
        final weekday = periodDate.weekday;
        final startOfWeek = periodDate.subtract(Duration(days: weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return expenseDate.isAfter(
              startOfWeek.subtract(const Duration(days: 1)),
            ) &&
            expenseDate.isBefore(endOfWeek.add(const Duration(days: 1)));
      case 'Month':
        return expenseDate.year == periodDate.year &&
            expenseDate.month == periodDate.month;
      case 'Year':
        return expenseDate.year == periodDate.year;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = widget.category != null
        ? Color(widget.category!.color)
        : Theme.of(context).colorScheme.primary;
    final categoryIcon = widget.category != null
        ? IconData(widget.category!.iconCode, fontFamily: 'MaterialIcons')
        : Icons.category;

    final groupedExpenses = _groupExpensesByDate();
    final sortedDates = groupedExpenses.keys.toList()
      ..sort((a, b) => _sortAscending ? a.compareTo(b) : b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _hasChanges),
        ),
        title: Text(widget.category?.name ?? 'Expenses'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Date'),
                    const SizedBox(width: 4),
                    Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _expenses.isEmpty
          ? Center(
              child: Text(
                'No expenses in this group',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: sortedDates.length,
              itemBuilder: (context, dateIndex) {
                final dateKey = sortedDates[dateIndex];
                final expensesForDate = groupedExpenses[dateKey]!;
                final dateHeader = _formatDateHeader(
                  expensesForDate.first.date,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    Padding(
                      padding: EdgeInsets.only(
                        left: 4,
                        top: dateIndex == 0 ? 0 : 16,
                        bottom: 12,
                      ),
                      child: Text(
                        dateHeader,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                    // Expenses for this date
                    ...expensesForDate.map((expense) {
                      final amountText = _formatAmount(expense.amount);

                      return FutureBuilder<List<Account>>(
                        future: DatabaseHelper.instance.getAllAccounts(),
                        builder: (context, accountSnapshot) {
                          final accounts = accountSnapshot.data ?? [];
                          Account? expenseAccount;
                          if (accounts.isNotEmpty) {
                            expenseAccount = accounts.firstWhere(
                              (a) => a.id == expense.accountId,
                              orElse: () => widget.account ?? accounts.first,
                            );
                          }
                          final expenseCurrency = expenseAccount != null
                              ? _currencySymbol(expenseAccount.currency)
                              : '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () async {
                                final updated = await Navigator.push<dynamic>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ExpenseDetailsScreen(
                                      expense: expense,
                                      account: expenseAccount,
                                      category: widget.category,
                                      themeProvider: widget.themeProvider,
                                    ),
                                  ),
                                );

                                if (updated == 'deleted' && mounted) {
                                  // Expense was deleted, remove from list
                                  setState(() {
                                    _expenses.removeWhere(
                                      (e) => e.id == expense.id,
                                    );
                                    _hasChanges = true;
                                  });

                                  // If list is empty, pop back to home
                                  if (_expenses.isEmpty) {
                                    Navigator.pop(context, true);
                                  }
                                  return;
                                } else if (updated == true && mounted) {
                                  // Expense was edited, set changes flag and pop back
                                  _hasChanges = true;
                                  Navigator.pop(context, true);
                                  return;
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceVariant,
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
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: categoryColor,
                                      child: Icon(
                                        categoryIcon,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  widget.category?.name ??
                                                      'Expense',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '$expenseCurrency$amountText',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            expenseAccount?.name ?? 'Account',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.65),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ],
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, right: 8.0),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddFinancialItemScreen(
                  initialTabIndex: 1, // Expense tab
                  themeProvider: widget.themeProvider,
                  selectedTab: widget.selectedTab,
                  periodDate: widget.periodDate,
                  customPeriodRange: widget.periodRange,
                  defaultExpenseCategory: widget.category,
                  defaultExpenseDate: DateTime.now(),
                ),
              ),
            );

            if (result == true && mounted) {
              // An expense was added, refresh the list
              _hasChanges = true;
              final allExpenses = await DatabaseHelper.instance
                  .getAllExpenses();
              final updatedExpenses = allExpenses.where((expense) {
                // Filter by category if specified
                if (widget.category != null &&
                    expense.categoryId != widget.category!.id) {
                  return false;
                }
                // Filter by account if specified
                if (widget.account != null &&
                    expense.accountId != widget.account!.id) {
                  return false;
                }
                // Filter by period
                if (widget.periodRange != null) {
                  return expense.date.isAfter(
                        widget.periodRange!.start.subtract(
                          const Duration(days: 1),
                        ),
                      ) &&
                      expense.date.isBefore(
                        widget.periodRange!.end.add(const Duration(days: 1)),
                      );
                } else {
                  // Use periodDate and selectedTab to filter
                  return _isExpenseInPeriod(expense.date);
                }
              }).toList();

              setState(() {
                _expenses = updatedExpenses
                  ..sort((a, b) => b.date.compareTo(a.date));
              });
            }
          },
          child: const Icon(Icons.add),
          tooltip: 'Add Expense',
        ),
      ),
    );
  }
}
