import 'package:flutter/material.dart';
import '../screens/account/accounts_screen.dart';
import '../screens/category/category_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../theme/theme_provider.dart';

class ConfigDrawer extends StatelessWidget {
  final ThemeProvider? themeProvider;
  final Future<bool> Function()? onWillNavigate;

  const ConfigDrawer({Key? key, this.themeProvider, this.onWillNavigate})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Text(
                'Expenses Manager',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () async {
                // Check if navigation is allowed
                if (onWillNavigate != null) {
                  final canNavigate = await onWillNavigate!();
                  if (!canNavigate) return;
                }

                // Get the root navigator for navigation
                final rootNavigator = Navigator.of(
                  context,
                  rootNavigator: true,
                );
                // Pop the drawer
                Navigator.of(context).pop();
                // Use root navigator to go back to home after drawer closes
                rootNavigator.popUntil((route) {
                  return route.isFirst;
                });
              },
            ),
            if (themeProvider != null)
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Accounts'),
                onTap: () async {
                  // Check if navigation is allowed
                  if (onWillNavigate != null) {
                    final canNavigate = await onWillNavigate!();
                    if (!canNavigate) return;
                  }

                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          AccountsScreen(themeProvider: themeProvider!),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categories'),
              onTap: () async {
                // Check if navigation is allowed
                if (onWillNavigate != null) {
                  final canNavigate = await onWillNavigate!();
                  if (!canNavigate) return;
                }
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        CategoryScreen(themeProvider: themeProvider),
                  ),
                );
              },
            ),
            if (themeProvider != null)
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () async {
                  // Check if navigation is allowed
                  if (onWillNavigate != null) {
                    final canNavigate = await onWillNavigate!();
                    if (!canNavigate) return;
                  }
                  Navigator.of(context).pop();

                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          SettingsScreen(themeProvider: themeProvider!),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Backup / Export'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
