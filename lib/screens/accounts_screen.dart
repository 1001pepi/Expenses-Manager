import 'package:flutter/material.dart';
import 'package:world_countries/world_countries.dart';
import '../theme/theme_provider.dart';
import '../models/account.dart';
import '../database/database_helper.dart';
import '../widgets/config_drawer.dart';
import 'add_account_screen.dart';

class AccountsScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const AccountsScreen({super.key, required this.themeProvider});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Account> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final accounts = await DatabaseHelper.instance.getAllAccounts();
    setState(() {
      _accounts = accounts;
      _isLoading = false;
    });
  }

  Future<void> _navigateToAddAccount() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddAccountScreen(themeProvider: widget.themeProvider),
      ),
    );

    if (result == true) {
      _loadAccounts(); // Reload accounts after adding new one
    }
  }

  Future<void> _navigateToEditAccount(Account account) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddAccountScreen(
              account: account,
              themeProvider: widget.themeProvider,
            ),
      ),
    );

    if (result == true) {
      _loadAccounts(); // Reload accounts after editing
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: false,
      drawer: ConfigDrawer(themeProvider: widget.themeProvider),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              FocusScope.of(context).unfocus();
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ),
        title: const Text('Accounts'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
          ? const Center(
              child: Text(
                'No accounts yet.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 16.0, left: 8.0),
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                final currency = FiatCurrency.list.firstWhere(
                  (c) => c.code == account.currency,
                  orElse: () => FiatCurrency.list.first,
                );
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(account.color),
                    child: Text(
                      account.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(account.name),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Text(
                      '${account.currency} (${currency.symbol ?? ''})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  onTap: () => _navigateToEditAccount(account),
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton(
          onPressed: _navigateToAddAccount,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
