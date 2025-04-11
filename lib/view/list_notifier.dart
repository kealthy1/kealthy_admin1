import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListNotifier extends StateNotifier<List<String>> {
  ListNotifier() : super([]);

  void addItem(String item) => state = [...state, item];
  void removeItem(int index) => state = [...state]..removeAt(index);
  void setItems(List<String> items) => state = items;
  void clearItems() {
  state = [];
}

}

final allProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('Products').get();
  final products = snapshot.docs.map((doc) {
    return {
      "id": doc.id,
      ...doc.data(),
    };
  }).toList();
  return products;
});

/// Track the user’s typed text in a typeahead or textfield.
final searchTextProvider = StateProvider<String>((ref) => "");