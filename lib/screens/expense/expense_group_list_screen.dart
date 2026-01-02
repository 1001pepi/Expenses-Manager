import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:world_countries/world_countries.dart';

import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/expense.dart';
import '../../theme/theme_provider.dart';
import '../../database/database_helper.dart';
import 'expense_details_screen.dart';

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

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MMM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = widget.category != null
        ? Color(widget.category!.color)
        : Theme.of(context).colorScheme.primary;
    final categoryIcon = widget.category != null
        ? IconData(widget.category!.iconCode, fontFamily: 'MaterialIcons')
        : Icons.category;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(widget.category?.name ?? 'Expenses'),
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
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: _expenses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                final amountText = _formatAmount(expense.amount);
                final dateText = _formatDate(expense.date);

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

                    return GestureDetector(
                      onTap: () async {
                        final updated = await Navigator.push<bool>(
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

                        if (updated == true && mounted) {
                          Navigator.pop(context, true);
                          return;
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.category?.name ?? 'Expense',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          dateText,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.75),
                                          ),
                                        ),
                                      ),
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
