import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../theme/theme_provider.dart';
import '../utils/date_format_utils.dart';
import '../widgets/config_drawer.dart';
import 'add_financial_item_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.themeProvider,
  });

  final String title;
  final ThemeProvider themeProvider;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late Map<String, DateTime> _periodDates;
  DateTimeRange? _customPeriodRange;
  String _selectedTab = 'Day';
  late TabController _mainTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(
      length: 2,
      vsync: this,
      animationDuration: Duration.zero,
    );
    final today = DateTime.now();
    _periodDates = {
      'Day': today,
      'Week': today,
      'Month': DateTime(today.year, today.month, 1),
      'Year': DateTime(today.year, 1, 1),
      'Period': today,
    };
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  void _updatePeriod(String tabName, int offset) {
    setState(() {
      final current = _periodDates[tabName] ?? DateTime.now();
      switch (tabName) {
        case 'Day':
          _periodDates[tabName] = current.add(Duration(days: offset));
          break;
        case 'Week':
          _periodDates[tabName] = current.add(Duration(days: offset * 7));
          break;
        case 'Month':
          _periodDates[tabName] = DateTime(
            current.year,
            current.month + offset,
            1,
          );
          break;
        case 'Year':
          _periodDates[tabName] = DateTime(current.year + offset, 1, 1);
          break;
        case 'Period':
          if (_customPeriodRange != null) {
            final spanDays = _customPeriodRange!.duration.inDays + 1;
            final delta = Duration(days: offset * spanDays);
            _customPeriodRange = DateTimeRange(
              start: _customPeriodRange!.start.add(delta),
              end: _customPeriodRange!.end.add(delta),
            );
          }
          break;
      }
    });
  }

  void _resetToCurrentPeriod(String tabName) {
    setState(() {
      final now = DateTime.now();
      switch (tabName) {
        case 'Day':
          _periodDates[tabName] = now;
          break;
        case 'Week':
          _periodDates[tabName] = now;
          break;
        case 'Month':
          _periodDates[tabName] = DateTime(now.year, now.month, 1);
          break;
        case 'Year':
          _periodDates[tabName] = DateTime(now.year, 1, 1);
          break;
        case 'Period':
          _customPeriodRange = null;
          _periodDates[tabName] = now;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const tabNames = ['Day', 'Week', 'Month', 'Year', 'Period'];

    return Scaffold(
      drawerEnableOpenDragGesture: false,
      drawer: ConfigDrawer(themeProvider: widget.themeProvider),
      appBar: AppBar(title: Text(widget.title), centerTitle: true),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _mainTabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.75),
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Budget'),
                Tab(text: 'Expenses'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMainTabContent(context, tabNames, 'Budget'),
                _buildMainTabContent(context, tabNames, 'Expenses'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 100),
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    AddFinancialItemScreen(
                      initialTabIndex: _mainTabController.index,
                      themeProvider: widget.themeProvider,
                      selectedTab: _selectedTab,
                      periodDate: _periodDates[_selectedTab],
                      customPeriodRange: _customPeriodRange,
                    ),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildMainTabContent(
    BuildContext context,
    List<String> tabNames,
    String mainTab,
  ) {
    final selectedTab = _selectedTab;
    final periodDate = _periodDates[selectedTab] ?? DateTime.now();
    final periodRange = _customPeriodRange;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildCustomMenu(context, tabNames),
          const SizedBox(height: 6),
          _buildPeriodHeader(context, selectedTab, periodDate, periodRange),
          const SizedBox(height: 6),
          Expanded(
            child: mainTab == 'Budget'
                ? _buildBudgetsContent(
                    context,
                    selectedTab,
                    periodDate,
                    periodRange,
                  )
                : _buildExpensesContent(
                    context,
                    selectedTab,
                    periodDate,
                    periodRange,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomMenu(BuildContext context, List<String> tabNames) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: tabNames.map((name) {
          final isSelected = _selectedTab == name;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.12)
                      : Colors.transparent,
                  foregroundColor: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.75),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () async {
                  if (name == 'Period') {
                    if (_customPeriodRange == null) {
                      final picked = await _showDateRangePicker(
                        context,
                        initialRange: _customPeriodRange,
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _customPeriodRange = picked;
                          _selectedTab = 'Period';
                        });
                      }
                      return;
                    }
                    if (mounted) setState(() => _selectedTab = 'Period');
                    return;
                  }

                  if (mounted) setState(() => _selectedTab = name);
                },
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPeriodHeader(
    BuildContext context,
    String tabName,
    DateTime periodDate,
    DateTimeRange? periodRange,
  ) {
    String periodText;

    if (tabName == 'Period' && periodRange != null) {
      if (periodRange.start.year == 2000 && periodRange.end.year >= 2100) {
        periodText = 'All time';
      } else {
        periodText = DateFormatUtils.getPeriodText(
          tabName,
          periodDate,
          customRange: periodRange,
        );
      }
    } else if (tabName == 'Period') {
      periodText = 'Select a period';
    } else {
      periodText = DateFormatUtils.getPeriodText(tabName, periodDate);
    }

    final bool showNavigation = tabName != 'Period';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showNavigation)
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _updatePeriod(tabName, -1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 26,
            )
          else
            const SizedBox(width: 32, height: 32),
          Expanded(
            child: GestureDetector(
              onTap: () => _showPeriodPicker(context, tabName),
              child: Center(
                child: Text(
                  periodText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (showNavigation)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _updatePeriod(tabName, 1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 26,
            )
          else
            const SizedBox(width: 32, height: 32),
          if (showNavigation)
            IconButton(
              icon: const Icon(Icons.today),
              tooltip: 'Today',
              onPressed: () => _resetToCurrentPeriod(tabName),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 22,
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetsContent(
    BuildContext context,
    String tabName,
    DateTime periodDate,
    DateTimeRange? periodRange,
  ) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        DatabaseHelper.instance.getAllBudgets(),
        DatabaseHelper.instance.getAllCategories(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading budgets: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        final results = snapshot.data ?? [<dynamic>[], <Category>[]];
        final budgetMaps = results[0] as List<dynamic>;
        final categories = results.length > 1
            ? results[1] as List<Category>
            : <Category>[];
        final categoryMap = {
          for (final c in categories)
            if (c.id != null) c.id!: c,
        };

        final filteredBudgets = _filterBudgetsByPeriod(
          budgetMaps,
          tabName,
          periodDate,
          periodRange,
        );

        if (filteredBudgets.isEmpty) {
          return Center(
            child: Text(
              'No budgets for this period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          itemCount: filteredBudgets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final budget = filteredBudgets[index];
            final category = categoryMap[budget.categoryId];
            final categoryColor = category != null
                ? Color(category.color)
                : Theme.of(context).colorScheme.primary;
            final categoryIcon = category != null
                ? IconData(category.iconCode, fontFamily: 'MaterialIcons')
                : Icons.category;

            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: categoryColor,
                    child: Icon(categoryIcon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Budget: ${budget.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (budget.tags.isNotEmpty)
                              Flexible(
                                child: Text(
                                  'Tags: ${budget.tags}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Period: ${DateFormatUtils.formatDate(budget.startDate)} - ${DateFormatUtils.formatDate(budget.endDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        if (budget.comment != null &&
                            budget.comment!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                budget.comment!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExpensesContent(
    BuildContext context,
    String selectedTab,
    DateTime periodDate,
    DateTimeRange? periodRange,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expenses', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8.0),
                Text(
                  'Manage and track your expenses by adding detailed records and categories.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 12.0),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddFinancialItemScreen(
                          themeProvider: widget.themeProvider,
                          selectedTab: selectedTab,
                          periodDate: periodDate,
                          customPeriodRange: periodRange,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          _buildInfoCard(
            context,
            icon: Icons.info_outline,
            title: 'Coming soon',
            subtitle:
                'Expenses tracking will be available in a future update. You can still add expenses via the button above.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Budget> _filterBudgetsByPeriod(
    List<dynamic> budgets,
    String tabName,
    DateTime periodDate,
    DateTimeRange? periodRange,
  ) {
    DateTime endOfDay(DateTime d) =>
        DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

    return budgets
        .map((budgetMap) => Budget.fromMap(budgetMap as Map<String, dynamic>))
        .where((budget) {
          late DateTime rangeStart;
          late DateTime rangeEnd;

          switch (tabName) {
            case 'Period':
              if (periodRange == null) return false;
              rangeStart = DateTime(
                periodRange.start.year,
                periodRange.start.month,
                periodRange.start.day,
              );
              rangeEnd = endOfDay(periodRange.end);
              break;
            case 'Day':
              rangeStart = DateTime(
                periodDate.year,
                periodDate.month,
                periodDate.day,
              );
              rangeEnd = endOfDay(periodDate);
              break;
            case 'Week':
              rangeStart = periodDate.subtract(
                Duration(days: periodDate.weekday - 1),
              );
              rangeEnd = endOfDay(rangeStart.add(const Duration(days: 6)));
              break;
            case 'Month':
              rangeStart = DateTime(periodDate.year, periodDate.month, 1);
              rangeEnd = endOfDay(
                DateTime(periodDate.year, periodDate.month + 1, 0),
              );
              break;
            case 'Year':
              rangeStart = DateTime(periodDate.year, 1, 1);
              rangeEnd = endOfDay(DateTime(periodDate.year + 1, 1, 0));
              break;
            default:
              return false;
          }

          final overlaps =
              !budget.startDate.isAfter(rangeEnd) &&
              !budget.endDate.isBefore(rangeStart);
          return overlaps;
        })
        .toList();
  }

  Future<void> _showPeriodPicker(BuildContext context, String tabName) async {
    final currentDate = _periodDates[tabName] ?? DateTime.now();

    switch (tabName) {
      case 'Day':
        final pickedDay = await _pickSingleDate(context, currentDate);
        if (pickedDay != null && mounted) {
          setState(() => _periodDates[tabName] = pickedDay);
        }
        break;
      case 'Week':
        final pickedWeek = await _pickSingleDate(context, currentDate);
        if (pickedWeek != null && mounted) {
          setState(() => _periodDates[tabName] = pickedWeek);
        }
        break;
      case 'Month':
        final pickedMonth = await _pickSingleDate(context, currentDate);
        if (pickedMonth != null && mounted) {
          setState(
            () => _periodDates[tabName] = DateTime(
              pickedMonth.year,
              pickedMonth.month,
              1,
            ),
          );
        }
        break;
      case 'Year':
        final pickedYear = await _pickSingleDate(context, currentDate);
        if (pickedYear != null && mounted) {
          setState(
            () => _periodDates[tabName] = DateTime(pickedYear.year, 1, 1),
          );
        }
        break;
      case 'Period':
        final pickedRange = await _showDateRangePicker(
          context,
          initialRange: _customPeriodRange,
        );
        if (pickedRange != null && mounted) {
          setState(() {
            _customPeriodRange = pickedRange;
            _selectedTab = 'Period';
          });
        }
        break;
    }
  }

  Future<DateTime?> _pickSingleDate(
    BuildContext context,
    DateTime initialDate,
  ) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<DateTimeRange?> _showDateRangePicker(
    BuildContext context, {
    DateTimeRange? initialRange,
  }) async {
    final now = DateTime.now();
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange:
          initialRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day + 6),
          ),
    );
  }
}
