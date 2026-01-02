import 'package:flutter/material.dart';
import '../screens/account/accounts_screen.dart';
import '../screens/category/category_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../theme/theme_provider.dart';

class ConfigDrawer extends StatelessWidget {
  final ThemeProvider? themeProvider;
  final Future<bool> Function()? onWillNavigate;

  const ConfigDrawer({super.key, this.themeProvider, this.onWillNavigate});

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
                // Pop the drawer first
                Navigator.of(context).pop();

                // Check if navigation is allowed
                if (onWillNavigate != null) {
                  final canNavigate = await onWillNavigate!();
                  if (!canNavigate) return;
                }

                if (!context.mounted) return;

                // Wait for drawer close animation
                await Future.delayed(const Duration(milliseconds: 50));

                if (!context.mounted) return;

                // Get the root navigator for navigation
                Navigator.of(context, rootNavigator: true).popUntil((route) {
                  return route.isFirst;
                });
              },
            ),
            if (themeProvider != null)
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Accounts'),
                onTap: () async {
                  // Pop the drawer first
                  Navigator.of(context).pop();

                  // Check if navigation is allowed
                  if (onWillNavigate != null) {
                    final canNavigate = await onWillNavigate!();
                    if (!canNavigate) return;
                  }

                  if (!context.mounted) return;

                  // Wait for drawer close animation
                  await Future.delayed(const Duration(milliseconds: 250));

                  if (!context.mounted) return;

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
                // Pop the drawer first
                Navigator.of(context).pop();

                // Check if navigation is allowed
                if (onWillNavigate != null) {
                  final canNavigate = await onWillNavigate!();
                  if (!canNavigate) return;
                }

                if (!context.mounted) return;

                // Wait for drawer close animation
                await Future.delayed(const Duration(milliseconds: 250));

                if (!context.mounted) return;

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
                  // Pop the drawer first
                  Navigator.of(context).pop();

                  // Check if navigation is allowed
                  if (onWillNavigate != null) {
                    final canNavigate = await onWillNavigate!();
                    if (!canNavigate) return;
                  }

                  if (!context.mounted) return;

                  // Wait for drawer close animation
                  await Future.delayed(const Duration(milliseconds: 250));

                  if (!context.mounted) return;

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
