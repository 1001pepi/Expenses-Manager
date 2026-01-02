import 'package:flutter/material.dart';
import 'package:world_countries/world_countries.dart';
import '../../theme/theme_provider.dart';
import '../../database/database_helper.dart';
import '../../models/account.dart';
import 'currency_selection_screen.dart';
import '../../widgets/config_drawer.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const SettingsScreen({Key? key, required this.themeProvider})
    : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawerEnableOpenDragGesture: false,
      drawer: ConfigDrawer(themeProvider: widget.themeProvider),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Open menu',
          ),
        ),
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          // Appearance Section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            trailing: Switch(
              value: widget.themeProvider.themeMode == ThemeMode.dark,
              onChanged: (value) {
                widget.themeProvider.toggleTheme();
              },
            ),
            onTap: () {
              widget.themeProvider.toggleTheme();
            },
          ),
          const Divider(),

          // General Settings Section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Text(
              'General Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money_outlined),
            title: const Text(
              'Default Currency',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Builder(
              builder: (context) {
                try {
                  final currency = FiatCurrency.list.firstWhere(
                    (c) => c.code == widget.themeProvider.defaultCurrency,
                  );
                  return Text('${currency.name} (${currency.code})');
                } catch (_) {
                  return Text(widget.themeProvider.defaultCurrency);
                }
              },
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CurrencySelectionScreen(
                    selectedCurrency: widget.themeProvider.defaultCurrency,
                    onCurrencySelected: (currency) {
                      setState(() {
                        widget.themeProvider.setDefaultCurrency(currency);
                      });
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          FutureBuilder<List<Account>>(
            future: DatabaseHelper.instance.getAllAccounts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(
                  leading: Icon(Icons.account_balance_wallet_outlined),
                  title: Text('Loading accounts...'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('No accounts available'),
                  onTap: null,
                );
              }

              final accounts = snapshot.data!;
              final defaultAccountId = widget.themeProvider.defaultAccountId;
              final selectedAccount = defaultAccountId != null
                  ? accounts.firstWhere(
                      (acc) => acc.id == defaultAccountId,
                      orElse: () => accounts.first,
                    )
                  : accounts.first;

              return ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text(
                  'Default Account',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(selectedAccount.name),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        'Select Default Account',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(8, 16, 24, 16),
                      content: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: accounts.map((account) {
                              return RadioListTile<int>(
                                title: Text(account.name),
                                subtitle: Text(
                                  account.currency,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                value: account.id!,
                                groupValue:
                                    widget.themeProvider.defaultAccountId ??
                                    accounts.first.id,
                                onChanged: (value) {
                                  setState(() {
                                    widget.themeProvider.setDefaultAccount(
                                      value,
                                    );
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
