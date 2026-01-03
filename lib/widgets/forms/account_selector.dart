import 'package:flutter/material.dart';
import 'package:world_countries/world_countries.dart';
import '../../models/account.dart';
import '../../database/database_helper.dart';

class AccountSelector extends StatelessWidget {
  final Account? selectedAccount;
  final Function(Account) onAccountSelected;

  const AccountSelector({
    Key? key,
    required this.selectedAccount,
    required this.onAccountSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Account',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              TextSpan(
                text: ' *',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final accounts = await DatabaseHelper.instance.getAllAccounts();
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Select Account'),
                    contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    content: SizedBox(
                      width: double.maxFinite,
                      height: 260,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          final isSelected = selectedAccount?.id == account.id;
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
                              onAccountSelected(account);
                              Navigator.pop(dialogContext);
                            },
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                    ],
                  );
                },
              );
            }
          },
          child: Text(
            selectedAccount?.name ?? 'Select Account',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
