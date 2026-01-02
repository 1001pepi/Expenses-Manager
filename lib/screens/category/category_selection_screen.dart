import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../database/database_helper.dart';
import '../../widgets/config_drawer.dart';
import '../../theme/theme_provider.dart';
import 'create_category_screen.dart';

class CategorySelectionScreen extends StatefulWidget {
  final Category? initialSelection;
  final ThemeProvider? themeProvider;

  const CategorySelectionScreen({
    super.key,
    this.initialSelection,
    this.themeProvider,
  });

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  Category? _selectedCategory;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialSelection;
    _categoriesFuture = _loadCategories();
  }

  void _refreshCategories() {
    setState(() {
      _categoriesFuture = _loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: false,
      drawer: ConfigDrawer(themeProvider: widget.themeProvider),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              FocusScope.of(context).unfocus();
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text('Select Category'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Category>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final categories = snapshot.data ?? [];

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 22,
                    mainAxisSpacing: 22,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    // Add + tile as last item
                    if (index == categories.length) {
                      return InkWell(
                        onTap: () async {
                          final created = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateCategoryScreen(
                                themeProvider: widget.themeProvider,
                              ),
                            ),
                          );
                          if (created == true) {
                            _refreshCategories();
                          }
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.add,
                              size: 38,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      );
                    }

                    final category = categories[index];
                    final isSelected = _selectedCategory?.id == category.id;
                    final iconData = IconData(
                      category.iconCode,
                      fontFamily: 'MaterialIcons',
                    );
                    final categoryColor = Color(category.color);

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedCategory = category);
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: categoryColor.withOpacity(0.15),
                          border: Border.all(
                            color: categoryColor,
                            width: isSelected ? 2.5 : 0.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(iconData, size: 32, color: categoryColor),
                            const SizedBox(height: 4),
                            Text(
                              category.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: Duration.zero,
        child: _selectedCategory != null
            ? SizedBox(
                key: const ValueKey('select-fab'),
                width: 200,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pop(context, _selectedCategory);
                  },
                  label: const Text('Select'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('empty-fab')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<List<Category>> _loadCategories() async {
    return await DatabaseHelper.instance.getAllCategories();
  }
}
