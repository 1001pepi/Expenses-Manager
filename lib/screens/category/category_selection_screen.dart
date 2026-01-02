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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Select Category'),
        centerTitle: false,
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
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.8,
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
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: Center(
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              child: Icon(
                                Icons.add,
                                size: 30,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
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
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? categoryColor.withOpacity(0.25)
                                  : categoryColor.withOpacity(0.15),
                              border: Border.all(
                                color: categoryColor,
                                width: isSelected ? 3.0 : 0.5,
                              ),
                            ),
                            padding: EdgeInsets.all(isSelected ? 14 : 12),
                            child: Icon(
                              iconData,
                              size: 38,
                              color: categoryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2.0,
                            ),
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.white,
                                    Colors.white,
                                    Colors.white.withOpacity(0),
                                  ],
                                  stops: const [0.0, 0.95, 1.0],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.dstIn,
                              child: Text(
                                category.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? categoryColor
                                      : Theme.of(context).colorScheme.onSurface
                                            .withOpacity(0.75),
                                ),
                              ),
                            ),
                          ),
                        ],
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
