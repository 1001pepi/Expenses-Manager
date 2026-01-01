import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:world_countries/world_countries.dart';

import '../models/account.dart';
import '../models/category.dart' as app;
import '../models/expense.dart';
import '../theme/theme_provider.dart';
import '../database/database_helper.dart';
import 'edit_expense_screen.dart';

class ExpenseDetailsScreen extends StatelessWidget {
  final Expense expense;
  final Account? account;
  final app.Category? category;
  final ThemeProvider themeProvider;

  const ExpenseDetailsScreen({
    super.key,
    required this.expense,
    required this.account,
    required this.category,
    required this.themeProvider,
  });

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
    final categoryColor = category != null
        ? Color(category!.color)
        : Theme.of(context).colorScheme.primary;
    final categoryIcon = category != null
        ? IconData(category!.iconCode, fontFamily: 'MaterialIcons')
        : Icons.category;
    final currencySymbol = _currencySymbol(account?.currency);

    Future<void> _confirmDelete() async {
      if (expense.id == null) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete expense?', style: TextStyle(fontSize: 18)),
          content: const Text(
            'This action will permanently remove this expense.',
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
        await DatabaseHelper.instance.deleteExpense(expense.id!);
        if (context.mounted) {
          Navigator.pop(context, true);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditExpenseScreen(
                    expense: expense,
                    themeProvider: themeProvider,
                  ),
                ),
              );
              if (updated == true && context.mounted) {
                final allExpenses = await DatabaseHelper.instance
                    .getAllExpenses();
                final updatedExpense = allExpenses.firstWhere(
                  (e) => e.id == expense.id,
                  orElse: () => expense,
                );
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => ExpenseDetailsScreen(
                        expense: updatedExpense,
                        account: account,
                        category: category,
                        themeProvider: themeProvider,
                      ),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      transitionsBuilder: (_, __, ___, child) => child,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
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
                        categoryName: category?.name ?? 'Expense',
                        accountName: account?.name ?? 'Account',
                        amountText:
                            '$currencySymbol${_formatAmount(expense.amount)}',
                        date: _formatDate(expense.date),
                        tags: expense.tags,
                        comment: expense.comment ?? '',
                        photos: [expense.photo1Path, expense.photo2Path],
                        onDelete: _confirmDelete,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 20),
                      child: Text(
                        'Created at ${_formatDate(expense.createdAt)}',
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
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final Color categoryColor;
  final IconData categoryIcon;
  final String categoryName;
  final String accountName;
  final String amountText;
  final String date;
  final String tags;
  final String comment;
  final List<String?> photos;
  final Future<void> Function() onDelete;

  const _HeroHeader({
    required this.categoryColor,
    required this.categoryIcon,
    required this.categoryName,
    required this.accountName,
    required this.amountText,
    required this.date,
    required this.tags,
    required this.comment,
    required this.photos,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    void _openImage(String path) {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, __, ___) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                child: kIsWeb
                    ? Image.network(path, fit: BoxFit.contain)
                    : Image.file(File(path), fit: BoxFit.contain),
              ),
            ),
          ),
          transitionsBuilder: (_, __, ___, child) => child,
        ),
      );
    }

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
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: categoryColor),
              const SizedBox(width: 8),
              Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.split(',').where((t) => t.trim().isNotEmpty).map((
                t,
              ) {
                final tag = t.trim();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: categoryColor.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: categoryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 14),
            _CommentCard(text: comment, accent: categoryColor),
          ],
          if (photos.any((p) => p != null)) ...[
            const SizedBox(height: 14),
            Text(
              'Photos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: photos.whereType<String>().map((path) {
                final imageWidget = kIsWeb
                    ? Image.network(
                        path,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(path),
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      );
                return GestureDetector(
                  onTap: () => _openImage(path),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: imageWidget,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 18),
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
