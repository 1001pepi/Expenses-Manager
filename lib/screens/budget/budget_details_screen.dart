import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:world_countries/world_countries.dart';

import '../../models/account.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../theme/theme_provider.dart';
import '../../database/database_helper.dart';
import 'edit_budget_screen.dart';

class BudgetDetailsScreen extends StatefulWidget {
  final Budget budget;
  final Account? account;
  final Category? category;
  final ThemeProvider themeProvider;

  const BudgetDetailsScreen({
    super.key,
    required this.budget,
    required this.account,
    required this.category,
    required this.themeProvider,
  });

  @override
  State<BudgetDetailsScreen> createState() => _BudgetDetailsScreenState();
}

class _BudgetDetailsScreenState extends State<BudgetDetailsScreen> {
  late Budget _budget;
  late Account? _account;
  late Category? _category;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
    _account = widget.account;
    _category = widget.category;
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
    final categoryColor = _category != null
        ? Color(_category!.color)
        : Theme.of(context).colorScheme.primary;
    final categoryIcon = _category != null
        ? IconData(_category!.iconCode, fontFamily: 'MaterialIcons')
        : Icons.category;
    final currencySymbol = _currencySymbol(_account?.currency);

    Future<void> _confirmDelete() async {
      if (_budget.id == null) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete budget?', style: TextStyle(fontSize: 18)),
          content: const Text(
            'This action will permanently remove this budget.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await DatabaseHelper.instance.deleteBudget(_budget.id!);
        if (context.mounted) {
          Navigator.pop(context, true);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => EditBudgetScreen(
                    budget: _budget,
                    themeProvider: widget.themeProvider,
                  ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  transitionsBuilder: (_, __, ___, child) => child,
                ),
              );
              if (updated == true && context.mounted) {
                // Fetch the updated budget, account, and category
                final allBudgets = await DatabaseHelper.instance
                    .getAllBudgets();
                final updatedBudgetMap = allBudgets.firstWhere(
                  (b) => b['id'] == _budget.id,
                  orElse: () => _budget.toMap(),
                );
                final updatedBudget = Budget.fromMap(
                  updatedBudgetMap as Map<String, dynamic>,
                );
                final updatedAccount = await DatabaseHelper.instance.getAccount(
                  updatedBudget.accountId,
                );
                final updatedCategory = await DatabaseHelper.instance
                    .getCategory(updatedBudget.categoryId);

                setState(() {
                  _budget = updatedBudget;
                  _account = updatedAccount;
                  _category = updatedCategory;
                  _hasChanges = true;
                });
              }
            },
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pop(_hasChanges);
          return false;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: SizedBox(
                  height: constraints.maxHeight - 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: _HeroHeader(
                          categoryColor: categoryColor,
                          categoryIcon: categoryIcon,
                          categoryName: _category?.name ?? 'Budget',
                          accountName: _account?.name ?? 'Account',
                          amountText:
                              '$currencySymbol${_formatAmount(_budget.amount)}',
                          startDate: _formatDate(_budget.startDate),
                          endDate: _formatDate(_budget.endDate),
                          tags: _budget.tags,
                          comment: _budget.comment ?? '',
                          onDelete: _confirmDelete,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 20),
                        child: Text(
                          'Created at ${_formatDate(_budget.createdAt)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.65),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final Color categoryColor;
  final IconData categoryIcon;
  final String categoryName;
  final String accountName;
  final String amountText;
  final String startDate;
  final String endDate;
  final String tags;
  final String comment;
  final Future<void> Function() onDelete;

  const _HeroHeader({
    required this.categoryColor,
    required this.categoryIcon,
    required this.categoryName,
    required this.accountName,
    required this.amountText,
    required this.startDate,
    required this.endDate,
    required this.tags,
    required this.comment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            categoryColor.withOpacity(0.14),
            categoryColor.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: categoryColor.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: categoryColor,
                child: Icon(categoryIcon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      accountName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: categoryColor.withOpacity(0.18)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _DateChip(
                    label: 'Start',
                    value: startDate,
                    icon: Icons.calendar_month,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateChip(
                    label: 'End',
                    value: endDate,
                    icon: Icons.calendar_month,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .split(',')
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty)
                  .map((tag) {
                    return _TagChip(label: tag, color: categoryColor);
                  })
                  .toList(),
            ),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 14),
            _CommentCard(text: comment, accent: categoryColor),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                tooltip: 'Delete',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final String text;
  final Color accent;

  const _CommentCard({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DateChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
