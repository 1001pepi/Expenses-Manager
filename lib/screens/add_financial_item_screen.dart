import 'package:flutter/material.dart';
import 'package:world_countries/world_countries.dart';
import '../theme/theme_provider.dart';
import '../models/account.dart';
import '../database/database_helper.dart';

class AddFinancialItemScreen extends StatefulWidget {
  final int initialTabIndex;
  final ThemeProvider? themeProvider;

  AddFinancialItemScreen({
    Key? key,
    this.initialTabIndex = 0,
    this.themeProvider,
  }) : super(key: key);

  @override
  State<AddFinancialItemScreen> createState() => _AddFinancialItemScreenState();
}

class _AddFinancialItemScreenState extends State<AddFinancialItemScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Account? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
      animationDuration: Duration.zero,
    );
    _loadDefaultAccount();
  }

  Future<void> _loadDefaultAccount() async {
    final accounts = await DatabaseHelper.instance.getAllAccounts();
    if (accounts.isNotEmpty) {
      setState(() {
        _selectedAccount = accounts.first; // Load first account as default
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
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
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.75),
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.tab,
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
              children: [_buildBudgetForm(), _buildExpenseForm()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetForm() {
    final currencyCode =
        _selectedAccount?.currency ??
        widget.themeProvider?.defaultCurrency ??
        'USD';
    final currency = FiatCurrency.list.firstWhere(
      (c) => c.code == currencyCode,
      orElse: () => FiatCurrency.list.first,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amount row with currency icon and calculator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 120,
                    child: TextField(
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currency.symbol ?? currencyCode,
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      const IconData(0xe121, fontFamily: 'MaterialIcons'),
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      // TODO: Open calculator
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final accounts = await DatabaseHelper.instance
                      .getAllAccounts();
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Select Account'),
                          contentPadding: const EdgeInsets.fromLTRB(
                            12,
                            12,
                            12,
                            4,
                          ),
                          content: SizedBox(
                            width: double.maxFinite,
                            height: 260,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              itemCount: accounts.length,
                              itemBuilder: (context, index) {
                                final account = accounts[index];
                                final isSelected =
                                    _selectedAccount?.id == account.id;
                                final currency = FiatCurrency.list.firstWhere(
                                  (c) => c.code == account.currency,
                                  orElse: () => FiatCurrency.list.first,
                                );
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Color(account.color),
                                    child: Text(
                                      account.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  title: Text(account.name),
                                  subtitle: Text(
                                    '${account.currency} (${currency.symbol ?? ''})',
                                  ),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedAccount = account;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Text(
                  _selectedAccount?.name ?? 'Select Account',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement save logic
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Budget'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseForm() {
    final currencyCode = widget.themeProvider?.defaultCurrency ?? 'USD';
    final currency = FiatCurrency.list.firstWhere(
      (c) => c.code == currencyCode,
      orElse: () => FiatCurrency.list.first,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amount row with currency icon and calculator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 120,
                    child: TextField(
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currency.symbol ?? currencyCode,
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      const IconData(0xe121, fontFamily: 'MaterialIcons'),
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      // TODO: Open calculator
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Expense Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Date',
              border: OutlineInputBorder(),
            ),
            readOnly: true,
            onTap: () async {
              await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              // TODO: Handle date selection
            },
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement save logic
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Expense'),
          ),
        ],
      ),
    );
  }
}
