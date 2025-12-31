import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/category.dart';
import '../utils/color_palette.dart';
import 'icon_catalog_screen.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
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

  IconData _selectedIcon = Icons.category_outlined;
  Color _selectedColor = ColorPalette.shared.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      DatabaseHelper.instance
          .createCategory(
            Category(
              name: _nameController.text.trim(),
              iconCode: _selectedIcon.codePoint,
              color: _selectedColor.value,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Category'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
          children: [
            TextFormField(
              controller: _nameController,
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                  final isSelected = iconData == _selectedIcon;
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
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Wrap(
                spacing: 18,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: ColorPalette.shared.map((color) {
                  final isSelected = color.value == _selectedColor.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 80),
            Center(
              child: SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
    );
  }
}
