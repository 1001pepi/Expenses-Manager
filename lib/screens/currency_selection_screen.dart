import 'package:flutter/material.dart';
import 'package:world_countries/world_countries.dart';

class CurrencySelectionScreen extends StatefulWidget {
  final String? selectedCurrency;
  final void Function(String) onCurrencySelected;

  const CurrencySelectionScreen({
    Key? key,
    this.selectedCurrency,
    required this.onCurrencySelected,
  }) : super(key: key);

  @override
  State<CurrencySelectionScreen> createState() =>
      _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late List<FiatCurrency> _sortedCurrencies;

  @override
  void initState() {
    super.initState();
    _sortedCurrencies = _getSortedCurrencies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FiatCurrency> _getSortedCurrencies() {
    final currencies = FiatCurrency.list.toList();

    // Sort alphabetically by name
    currencies.sort((a, b) => a.name.compareTo(b.name));

    // Find the selected currency
    final selectedIndex = widget.selectedCurrency != null
        ? currencies.indexWhere((c) => c.code == widget.selectedCurrency)
        : -1;

    // If found, move it to the top
    if (selectedIndex > 0) {
      final selected = currencies.removeAt(selectedIndex);
      currencies.insert(0, selected);
    }

    return currencies;
  }

  List<FiatCurrency> _getFilteredCurrencies() {
    if (_searchQuery.isEmpty) {
      return _sortedCurrencies;
    }

    final query = _searchQuery.toLowerCase();
    return _sortedCurrencies.where((currency) {
      return currency.name.toLowerCase().contains(query) ||
          currency.code.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCurrencies = _getFilteredCurrencies();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Currency'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: UnderlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCurrencies.length,
              itemBuilder: (context, index) {
                final currency = filteredCurrencies[index];
                final isSelected = widget.selectedCurrency == currency.code;

                return InkWell(
                  onTap: () {
                    widget.onCurrencySelected(currency.code);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1)
                          : null,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Currency code in a badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            currency.code,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Currency name and symbol
                        Expanded(
                          child: Text(
                            '${currency.name} (${currency.symbol ?? ''})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
