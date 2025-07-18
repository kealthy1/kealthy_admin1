import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final selectedCategoryProvider = StateProvider<String>((ref) => '');
final selectedSubCategoryProvider = StateProvider<String>((ref) => '');

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final selected = ref.watch(selectedCategoryProvider);
  final snapshot = await FirebaseFirestore.instance.collection('categories').get();

  final categories = snapshot.docs.map((doc) => doc['Categories'] as String).toSet().toList();

  // Ensure selected value is present (for edit/search case)
  if (selected.isNotEmpty && !categories.contains(selected)) {
    categories.insert(0, selected);
  }

  return categories;
});

final subcategoriesProvider =
    FutureProvider.family<List<String>, String>((ref, category) async {
  final selectedSub = ref.watch(selectedSubCategoryProvider);

  if (category.isEmpty) return [if (selectedSub.isNotEmpty) selectedSub];

  final query = await FirebaseFirestore.instance
      .collection('SubCategory')
      .where('Category', isEqualTo: category)
      .get();

  final subcategories = query.docs.map((doc) => doc['Subcategory'] as String).toSet().toList();

  // Ensure selected subcategory is present
  if (selectedSub.isNotEmpty && !subcategories.contains(selectedSub)) {
    subcategories.insert(0, selectedSub);
  }

  return subcategories;
});