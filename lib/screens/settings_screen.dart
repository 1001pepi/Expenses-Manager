import 'package:flutter/material.dart';
import 'package:world_countries/world_countries.dart';
import '../theme/theme_provider.dart';
import 'currency_selection_screen.dart';

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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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

          // Currency Section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Text(
              'Currency',
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
        ],
      ),
    );
  }
}
