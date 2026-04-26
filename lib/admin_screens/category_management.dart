import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryManagement extends StatefulWidget {
  const CategoryManagement({super.key});

  @override
  State<CategoryManagement> createState() => _CategoryManagementState();
}

class _CategoryManagementState extends State<CategoryManagement> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  List<dynamic> categories = [];
  String search = '';
  bool showDeleted = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    setState(() => _isLoading = true);

    try {
      var query = supabase.from('categories').select();

      if (showDeleted) {
        query = query.eq('is_deleted', true);
      } else {
        query = query.eq('is_deleted', false);
      }

      if (search.isNotEmpty) {
        query = query.ilike('name', '%$search%');
      }

      final response = await query.order('name');

      setState(() {
        categories = response;
      });
    } catch (e) {
      showMessage('Error loading categories: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> addCategory() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name == null || name.isEmpty) return;

    try {
      await supabase.from('categories').insert({
        'name': name,
        'is_deleted': false,
      });

      showMessage('Category added');
      fetchCategories();
    } catch (e) {
      showMessage('Add failed: $e');
    }
  }

  Future<void> editCategory(Map category) async {
    final controller = TextEditingController(text: category['name']);

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name == null || name.isEmpty) return;

    try {
      await supabase
          .from('categories')
          .update({'name': name})
          .eq('category_id', category['category_id']);

      showMessage('Category updated');
      fetchCategories();
    } catch (e) {
      showMessage('Update failed: $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await supabase
          .from('categories')
          .update({'is_deleted': true})
          .eq('category_id', id);

      showMessage('Category deleted');
      fetchCategories();
    } catch (e) {
      showMessage('Delete failed: $e');
    }
  }

  Future<void> restoreCategory(int id) async {
    try {
      await supabase
          .from('categories')
          .update({'is_deleted': false})
          .eq('category_id', id);

      showMessage('Category restored');
      fetchCategories();
    } catch (e) {
      showMessage('Restore failed: $e');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        backgroundColor: const Color(0xFF5B6FF5),
        actions: [
          IconButton(onPressed: fetchCategories, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addCategory,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search category...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                search = value;
                fetchCategories();
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Show Deleted'),
            value: showDeleted,
            onChanged: (value) {
              setState(() => showDeleted = value);
              fetchCategories();
            },
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : categories.isEmpty
                ? const Center(child: Text('No categories found'))
                : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final c = categories[index];

                return Card(
                  child: ListTile(
                    title: Text(c['name']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!c['is_deleted']) ...[
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => editCategory(c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                deleteCategory(c['category_id']),
                          ),
                        ] else ...[
                          IconButton(
                            icon: const Icon(Icons.restore),
                            onPressed: () =>
                                restoreCategory(c['category_id']),
                          ),
                        ]
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