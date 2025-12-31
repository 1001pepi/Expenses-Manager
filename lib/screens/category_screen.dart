import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/category.dart';
import 'create_category_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = DatabaseHelper.instance.getAllCategories();
  }

  void _refreshCategories() {
    setState(() {
      _categoriesFuture = DatabaseHelper.instance.getAllCategories();
    });
  }

  Future<void> _openCreateCategory() async {
    final created = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CreateCategoryScreen(),
      ),
    );
    if (created == true) {
      _refreshCategories();
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
        title: const Text('Categories'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load categories: ${snapshot.error}'),
            );
          }

          final categories = snapshot.data ?? [];
          // Sort categories alphabetically by name
          categories.sort((a, b) => a.name.compareTo(b.name));

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No categories yet'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _openCreateCategory,
                    child: const Text('Create your first category'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 24,
              childAspectRatio: 0.8,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final categoryColor = Color(category.color);
              final categoryIcon = IconData(
                category.iconCode,
                fontFamily: 'MaterialIcons',
              );
              return GestureDetector(
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateCategoryScreen(category: category),
                    ),
                  );
                  if (result == true) {
                    _refreshCategories();
                  }
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: categoryColor.withOpacity(0.15),
                          border: Border.all(
                            color: categoryColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            categoryIcon,
                            size: 38,
                            color: categoryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0),
                              ],
                              stops: const [0.75, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: Text(
                            category.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: FloatingActionButton(
          onPressed: _openCreateCategory,
          elevation: 4,
          child: const Icon(Icons.add, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
