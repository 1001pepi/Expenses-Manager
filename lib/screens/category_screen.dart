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

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(category.color).withOpacity(0.15),
                  child: Icon(
                    IconData(category.iconCode, fontFamily: 'MaterialIcons'),
                    color: Color(category.color),
                  ),
                ),
                title: Text(category.name),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: categories.length,
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: FloatingActionButton(
          onPressed: _openCreateCategory,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
