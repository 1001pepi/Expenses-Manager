import 'package:flutter/material.dart';
import 'package:world_countries/world_countries.dart';
import '../models/account.dart';
import '../database/database_helper.dart';
import '../theme/theme_provider.dart';
import '../widgets/config_drawer.dart';
import 'currency_selection_screen.dart';
import '../utils/color_palette.dart';

class AddAccountScreen extends StatefulWidget {
  final Account? account; // Optional account for editing
  final ThemeProvider? themeProvider;

  const AddAccountScreen({super.key, this.account, this.themeProvider});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currencyController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Color? _selectedColor;

  // Track original values for change detection
  String _originalName = '';
  String _originalCurrency = '';
  Color? _originalColor;

  @override
  void initState() {
    super.initState();
    // If editing, populate the form with account data
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _currencyController.text = widget.account!.currency;
      _selectedColor = Color(widget.account!.color);
      _originalName = widget.account!.name;
      _originalCurrency = widget.account!.currency;
      _originalColor = Color(widget.account!.color);
    } else {
      // Set default currency from ThemeProvider
      _currencyController.text = widget.themeProvider?.defaultCurrency ?? 'EUR';
      _originalCurrency = widget.themeProvider?.defaultCurrency ?? 'EUR';
    }

    // Add listener to name controller for state updates
    _nameController.addListener(() {
      setState(() {});
    });

    // Request focus on name field after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }

  bool get _isFormValid {
    if (widget.account != null) {
      // Editing mode: enable if form is valid (allow saving even without changes)
      return _nameController.text.trim().isNotEmpty && _selectedColor != null;
    } else {
      // Creating mode: enable if name is set and color is selected
      return _nameController.text.trim().isNotEmpty && _selectedColor != null;
    }
  }

  bool get _hasUnsavedChanges {
    if (widget.account == null) return false; // No changes in create mode
    return _nameController.text != _originalName ||
        _currencyController.text != _originalCurrency ||
        _selectedColor != _originalColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currencyController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?', style: TextStyle(fontSize: 18)),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account', style: TextStyle(fontSize: 18)),
          content: Text('Delete the "${widget.account!.name}" account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteAccount(widget.account!.id!);
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    }
  }

  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate() &&
        _currencyController.text.isNotEmpty) {
      if (widget.account != null) {
        // Update existing account
        final updatedAccount = widget.account!.copyWith(
          name: _nameController.text,
          currency: _currencyController.text,
          color: _selectedColor!.value,
        );
        await DatabaseHelper.instance.updateAccount(updatedAccount);
      } else {
        // Create new account
        final account = Account(
          name: _nameController.text,
          currency: _currencyController.text,
          color: _selectedColor!.value,
        );
        await DatabaseHelper.instance.createAccount(account);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasUnsavedChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawerEnableOpenDragGesture: false,
        drawer: ConfigDrawer(
          themeProvider: widget.themeProvider,
          onWillNavigate: () async {
            if (_hasUnsavedChanges) {
              return await _onWillPop();
            }
            return true;
          },
        ),
        appBar: AppBar(
          leading: widget.account != null
              ? Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
          title: Text(widget.account != null ? 'Edit Account' : 'Add Account'),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: InputBorder.none,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an account name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Currency',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        CurrencySelectionScreen(
                                          selectedCurrency:
                                              _currencyController.text,
                                          onCurrencySelected:
                                              (selectedCurrency) {
                                                setState(() {
                                                  _currencyController.text =
                                                      selectedCurrency;
                                                });
                                              },
                                        ),
                              ),
                            );
                          },
                          child: Builder(
                            builder: (context) {
                              final currency = FiatCurrency.list.firstWhere(
                                (c) => c.code == _currencyController.text,
                                orElse: () => FiatCurrency.list.first,
                              );
                              return Text(
                                '${_currencyController.text} (${currency.symbol ?? ''})',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Color',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: ColorPalette.shared.map((color) {
                        final isSelected =
                            _selectedColor != null &&
                            color.value == _selectedColor!.value;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    // Delete button - only show for custom accounts (not "main")
                    if (widget.account != null &&
                        widget.account!.name != 'main')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),
                          TextButton(
                            onPressed: _deleteAccount,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'DELETE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 64.0,
                ),
                child: Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: !_isFormValid ? null : _saveAccount,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        disabledBackgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                        disabledForegroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.5),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
