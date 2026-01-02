import 'package:flutter/material.dart';
import 'package:world_countries/world_countries.dart';
import '../../screens/shared/calculator_screen.dart';

class AmountInputField extends StatelessWidget {
  final String currencyCode;
  final FocusNode? focusNode;
  final TextEditingController? controller;

  const AmountInputField({
    Key? key,
    required this.currencyCode,
    this.focusNode,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currency = FiatCurrency.list.firstWhere(
      (c) => c.code == currencyCode,
      orElse: () => FiatCurrency.list.first,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
              onPressed: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalculatorScreen(),
                  ),
                );
                if (result != null && controller != null) {
                  controller!.text = result;
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
