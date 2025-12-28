import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../widgets/calendar/date_picker_dialog.dart' as custom_picker;
import '../widgets/calendar/week_picker_dialog.dart';
import '../widgets/calendar/month_picker_dialog.dart';
import '../widgets/calendar/period_picker_dialog.dart';
import '../utils/date_format_utils.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  late Map<String, DateTime> _periodDates;
  DateTimeRange? _customPeriodRange;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _periodDates = {
      'Day': today,
      'Week': today,
      'Month': today,
      'Year': today,
      'Period': today,
    };
    _customPeriodRange = null;
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
          if (offset > 0) {
            _periodDates[tabName] = DateTime(
              current.year,
              current.month + offset,
              current.day,
            );
          } else {
            _periodDates[tabName] = DateTime(
              current.year,
              current.month + offset,
              current.day,
            );
          }
          break;
        case 'Year':
          _periodDates[tabName] = DateTime(
            current.year + offset,
            current.month,
            current.day,
          );
          break;
        case 'Period':
          // Custom period navigation can be handled differently
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const tabNames = ['Day', 'Week', 'Month', 'Year', 'Period'];

    return Scaffold(
      drawer: _buildConfigDrawer(context),
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DefaultTabController(
          length: 5,
          animationDuration: Duration.zero,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              ),
            ),
            child: Column(
              children: [
                Builder(
                  builder: (tabContext) {
                    _tabController = DefaultTabController.of(tabContext);

                    return TabBar(
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                      dividerColor: Colors.transparent,
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      indicatorPadding: const EdgeInsets.only(bottom: 0),
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      onTap: (int index) async {
                        if (_tabController == null) return;

                        final tabName = tabNames[index];
                        if (tabName == 'Period') {
                          // If a period is already selected, allow normal tab switch.
                          if (_customPeriodRange != null) {
                            return;
                          }

                          // No period selected yet: keep current tab and show picker.
                          final currentTabIndex = _tabController!.index;
                          _tabController!.index = currentTabIndex;

                          final picked = await _showDateRangePicker(
                            context,
                            tabName,
                            _customPeriodRange,
                          );

                          // Switch to Period tab only when user confirms selection.
                          if (picked && mounted && _tabController != null) {
                            _tabController!.index = index;
                          }
                          return;
                        }
                      },
                      tabs: tabNames.map((name) => Tab(text: name)).toList(),
                    );
                  },
                ),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: tabNames
                        .map((name) => _buildTabContent(context, name))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Text(
                'Configuration',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
            ListTile(
              leading: const Icon(Icons.attach_money_outlined),
              title: const Text('Currency'),
              onTap: () {
                Navigator.of(context).pop();
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

  Widget _buildTabContent(BuildContext context, String tabName) {
    final periodDate = _periodDates[tabName] ?? DateTime.now();
    final periodRange = _customPeriodRange;
    String periodText;

    if (tabName == 'Period' && periodRange != null) {
      periodText = DateFormatUtils.getPeriodText(
        tabName,
        periodDate,
        customRange: periodRange,
      );
    } else if (tabName == 'Period') {
      periodText = 'Select a period';
    } else {
      periodText = DateFormatUtils.getPeriodText(tabName, periodDate);
    }

    final bool showNavigation = tabName != 'Period';

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Period header with navigation arrows
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showNavigation)
                  IconButton(
                    icon: const Icon(Icons.arrow_left),
                    onPressed: () {
                      _updatePeriod(tabName, -1);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
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
                          fontSize: 14,
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
                    icon: const Icon(Icons.arrow_right),
                    onPressed: () {
                      _updatePeriod(tabName, 1);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                  )
                else
                  const SizedBox(width: 32, height: 32),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '$tabName Previsions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '$tabName Expenses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodPlaceholder(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              final picked = await _showDateRangePicker(
                context,
                'Period',
                _customPeriodRange,
              );
              // On cancel, do nothing; remain on placeholder safely.
              if (picked && mounted) {
                // Use post frame callback to safely update tab after dialog closes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _tabController != null) {
                    // Navigate to Period tab after successful pick.
                    final periodIndex = 4; // 'Period' position in tabNames
                    if (periodIndex >= 0 &&
                        periodIndex < _tabController!.length) {
                      _tabController!.index = periodIndex;
                    }
                  }
                });
              }
            },
            child: const Text('Choose a period'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPeriodPicker(BuildContext context, String tabName) async {
    final currentDate = _periodDates[tabName] ?? DateTime.now();

    switch (tabName) {
      case 'Day':
        await _showCustomDatePicker(context, tabName, currentDate);
        break;
      case 'Week':
        await _showDatePicker(context, tabName, currentDate);
        break;
      case 'Month':
        await _showMonthPicker(context, tabName, currentDate);
        break;
      case 'Year':
        // No picker for year - navigation only via arrows
        break;
      case 'Period':
        await _showDateRangePicker(context, tabName, _customPeriodRange);
        break;
    }
  }

  Future<void> _showDatePicker(
    BuildContext context,
    String tabName,
    DateTime currentDate,
  ) async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return WeekPickerDialog(
          initialDate: currentDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          helpText: 'Select Week',
          onDateSelected: (DateTime date) {
            Navigator.pop(context, date);
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _periodDates[tabName] = selected;
      });
    }
  }

  Future<void> _showCustomDatePicker(
    BuildContext context,
    String tabName,
    DateTime currentDate,
  ) async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return custom_picker.CustomDatePickerDialog(
          initialDate: currentDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          helpText: 'Select Day',
          onDateSelected: (DateTime date) {
            Navigator.pop(context, date);
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _periodDates[tabName] = selected;
      });
    }
  }

  Future<void> _showMonthPicker(
    BuildContext context,
    String tabName,
    DateTime currentDate,
  ) async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return MonthPickerDialog(
          initialDate: currentDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          helpText: 'Select Month',
          onDateSelected: (DateTime date) {
            Navigator.pop(context, date);
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _periodDates[tabName] = DateTime(selected.year, selected.month, 1);
      });
    }
  }

  Future<void> _showYearPicker(
    BuildContext context,
    String tabName,
    DateTime currentDate,
  ) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select Year',
      selectableDayPredicate: (DateTime date) {
        return false; // Disable day selection
      },
    );

    if (selected != null) {
      setState(() {
        _periodDates[tabName] = DateTime(selected.year, 1, 1);
      });
    }
  }

  Future<bool> _showDateRangePicker(
    BuildContext context,
    String tabName,
    DateTimeRange? initialRange,
  ) async {
    final baseRange =
        initialRange ??
        DateTimeRange(
          start: DateTime.now(),
          end: DateTime.now().add(const Duration(days: 7)),
        );

    final range = await showDialog<DateTimeRange?>(
      context: context,
      builder: (BuildContext context) {
        return PeriodPickerDialog(
          initialRange: baseRange,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          helpText: 'Select Period',
          onRangeSelected: (DateTimeRange range) {
            Navigator.pop(context, range);
          },
        );
      },
    );

    if (range != null) {
      setState(() {
        _customPeriodRange = range;
        _periodDates[tabName] = range.start;
      });
      return true;
    }

    return false;
  }
}
