import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:world_countries/world_countries.dart';

import '../../models/account.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../theme/theme_provider.dart';
import '../../database/database_helper.dart';
import 'budget_details_screen.dart';

class BudgetGroupListScreen extends StatefulWidget {
  const BudgetGroupListScreen({
    super.key,
    required this.budgets,
    required this.account,
    required this.category,
    required this.themeProvider,
    this.isMergedByAccount = false,
  });

  final List<Budget> budgets;
  final Account? account;
  final Category? category;
  final ThemeProvider themeProvider;
  final bool isMergedByAccount;

  @override
  State<BudgetGroupListScreen> createState() => _BudgetGroupListScreenState();
}

class _BudgetGroupListScreenState extends State<BudgetGroupListScreen> {
  late List<Budget> _budgets;

  @override
  void initState() {
    super.initState();
    _budgets = [...widget.budgets]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
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

    // Use account name as title when merged by account, otherwise category name
    final screenTitle = widget.isMergedByAccount
        ? (widget.account?.name ?? 'Budgets')
        : (widget.category?.name ?? 'Budgets');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(screenTitle),
      ),
      body: _budgets.isEmpty
          ? Center(
              child: Text(
                'No budgets in this group',
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
              itemCount: _budgets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final budget = _budgets[index];
                final amountText = _formatAmount(budget.amount);
                final dateRange =
                    '${_formatDate(budget.startDate)} → ${_formatDate(budget.endDate)}';

                return FutureBuilder<List<dynamic>>(
                  future: Future.wait([
                    DatabaseHelper.instance.getAllAccounts(),
                    DatabaseHelper.instance.getAllCategories(),
                  ]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final accounts = snapshot.data![0] as List<Account>;
                    final categories = snapshot.data![1] as List<Category>;

                    Account? budgetAccount;
                    if (accounts.isNotEmpty) {
                      budgetAccount = accounts.firstWhere(
                        (a) => a.id == budget.accountId,
                        orElse: () => widget.account ?? accounts.first,
                      );
                    }
                    final budgetCurrency = budgetAccount != null
                        ? _currencySymbol(budgetAccount.currency)
                        : '';

                    // Get the actual category for this budget
                    Category? budgetCategory;
                    if (widget.isMergedByAccount && categories.isNotEmpty) {
                      budgetCategory = categories.firstWhere(
                        (c) => c.id == budget.categoryId,
                        orElse: () => widget.category ?? categories.first,
                      );
                    } else {
                      budgetCategory = widget.category;
                    }

                    final displayCategoryColor = budgetCategory != null
                        ? Color(budgetCategory.color)
                        : (widget.isMergedByAccount && widget.account != null
                              ? Color(widget.account!.color)
                              : categoryColor);
                    final displayCategoryIcon = budgetCategory != null
                        ? IconData(
                            budgetCategory.iconCode,
                            fontFamily: 'MaterialIcons',
                          )
                        : categoryIcon;
                    final displayCategoryName =
                        budgetCategory?.name ?? 'Budget';

                    return GestureDetector(
                      onTap: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BudgetDetailsScreen(
                              budget: budget,
                              account: budgetAccount,
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
                              backgroundColor: widget.isMergedByAccount
                                  ? displayCategoryColor
                                  : categoryColor,
                              child: widget.isMergedByAccount
                                  ? Icon(
                                      displayCategoryIcon,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : Icon(
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
                                          widget.isMergedByAccount
                                              ? displayCategoryName
                                              : (widget.category?.name ??
                                                    'Budget'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$budgetCurrency$amountText',
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
                                          dateRange,
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
                                        budgetAccount?.name ?? 'Account',
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
