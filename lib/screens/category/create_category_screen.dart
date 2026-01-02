import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../models/category.dart';
import '../../theme/theme_provider.dart';
import '../../utils/color_palette.dart';
import '../../widgets/config_drawer.dart';
import '../settings/icon_catalog_screen.dart';

class CreateCategoryScreen extends StatefulWidget {
  final Category? category; // Optional category for editing
  final ThemeProvider? themeProvider;

  const CreateCategoryScreen({super.key, this.category, this.themeProvider});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  bool _isSaving = false;

  // Simple icon choices; can be extended later
  List<IconData> _icons = [
    Icons.category_outlined,
    Icons.shopping_cart_outlined,
    Icons.home_outlined,
    Icons.directions_car_outlined,
    Icons.restaurant_outlined,
    Icons.sports_esports_outlined,
    Icons.flight_outlined,
    Icons.health_and_safety_outlined,
    Icons.work_outline,
    Icons.savings_outlined,
    Icons.school_outlined,
    Icons.pets_outlined,
    Icons.card_giftcard_outlined,
    Icons.receipt_long_outlined,
    Icons.fitness_center_outlined,
    Icons.local_cafe_outlined,
  ];

  IconData? _selectedIcon;
  Color? _selectedColor;

  // Track original values for change detection
  String _originalName = '';
  IconData? _originalIcon;
  Color? _originalColor;

  @override
  void initState() {
    super.initState();
    // If editing, populate the form with category data
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedIcon = IconData(
        widget.category!.iconCode,
        fontFamily: 'MaterialIcons',
      );
      _selectedColor = Color(widget.category!.color);
      _originalName = widget.category!.name;
      _originalIcon = _selectedIcon;
      _originalColor = _selectedColor;

      // If the selected icon is not in the default list, add it at the beginning
      if (!_icons.any((icon) => icon.codePoint == _selectedIcon!.codePoint)) {
        _icons.insert(0, _selectedIcon!);
      }
    }

    // Add listener to name controller for state updates
    _nameController.addListener(() {
      setState(() {});
    });
  }

  bool get _isFormValid {
    if (widget.category != null) {
      // Editing mode: enable if form is valid (allow saving even without changes)
      return _nameController.text.trim().isNotEmpty &&
          _selectedIcon != null &&
          _selectedColor != null;
    } else {
      // Creating mode: enable if name is set, icon is selected, and color is selected
      return _nameController.text.trim().isNotEmpty &&
          _selectedIcon != null &&
          _selectedColor != null;
    }
  }

  bool get _hasUnsavedChanges {
    if (widget.category == null) {
      // Creating mode: check if any field has been modified
      return _nameController.text.trim().isNotEmpty ||
          _selectedIcon != null ||
          _selectedColor != null;
    } else {
      // Editing mode: check if any field differs from original
      return _nameController.text.trim() != _originalName ||
          _selectedIcon?.codePoint != _originalIcon?.codePoint ||
          _selectedColor?.value != _originalColor?.value;
    }
  }

  Future<bool> _confirmExit() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Discard changes?', style: TextStyle(fontSize: 18)),
          content: const Text(
            'You have unsaved changes. Do you want to discard them?',
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
        );
      },
    );

    return result ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _deleteCategory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category', style: TextStyle(fontSize: 18)),
          content: Text('Delete the "${widget.category!.name}" category?'),
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
      await DatabaseHelper.instance.deleteCategory(widget.category!.id!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      if (widget.category != null) {
        // Update existing category
        final updatedCategory = widget.category!.copyWith(
          name: _nameController.text.trim(),
          iconCode: _selectedIcon!.codePoint,
          color: _selectedColor!.value,
        );
        DatabaseHelper.instance
            .updateCategory(updatedCategory)
            .then((_) {
              Navigator.pop(context, true);
            })
            .catchError((error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update category: $error')),
              );
            })
            .whenComplete(() {
              if (mounted) {
                setState(() => _isSaving = false);
              }
            });
      } else {
        // Create new category
        DatabaseHelper.instance
            .createCategory(
              Category(
                name: _nameController.text.trim(),
                iconCode: _selectedIcon!.codePoint,
                color: _selectedColor!.value,
              ),
            )
            .then((_) {
              Navigator.pop(context, true);
            })
            .catchError((error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save category: $error')),
              );
            })
            .whenComplete(() {
              if (mounted) {
                setState(() => _isSaving = false);
              }
            });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldPop = await _confirmExit();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        drawerEnableOpenDragGesture: false,
        drawer: ConfigDrawer(themeProvider: widget.themeProvider),
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                final shouldPop = await _confirmExit();
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          title: Text(
            widget.category != null ? 'Edit Category' : 'Create Category',
          ),
          centerTitle: false,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 16.0,
            ),
            children: [
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Icon',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 22,
                crossAxisSpacing: 22,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Show first 11 icons, then '...'
                  ..._icons.take(11).map((iconData) {
                    final isSelected =
                        _selectedIcon != null &&
                        iconData.codePoint == _selectedIcon!.codePoint;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedIcon = iconData);
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.12)
                              : Theme.of(context).colorScheme.surfaceVariant,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            iconData,
                            size: 35,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.75),
                          ),
                        ),
                      ),
                    );
                  }),
                  // '+' tile to open full icon catalog
                  InkWell(
                    onTap: () async {
                      final selected = await Navigator.push<IconData>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IconCatalogScreen(),
                        ),
                      );
                      if (selected != null && mounted) {
                        setState(() {
                          _selectedIcon = selected;
                          // Replace the first icon with the selected one if it's not already in the list
                          if (!_icons.contains(selected)) {
                            _icons[0] = selected;
                          }
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add,
                          size: 28,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Color',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Wrap(
                  spacing: 18,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: ColorPalette.shared.map((color) {
                    final isSelected =
                        _selectedColor != null &&
                        color.value == _selectedColor!.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 44,
                        height: 44,
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
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              // Delete button - only show when editing
              if (widget.category != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _deleteCategory,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text(
                      'DELETE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: (!_isFormValid || _isSaving)
                        ? null
                        : _saveCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      disabledBackgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.20),
                      disabledForegroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
