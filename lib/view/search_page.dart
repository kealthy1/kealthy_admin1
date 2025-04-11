import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy_admin/view/list_notifier.dart';

class LocalFilterSearchPage extends ConsumerWidget {
  const LocalFilterSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1) Read the search text
    final searchText = ref.watch(searchTextProvider);
    // 2) Fetch all products once
    final allProductsAsync = ref.watch(allProductsProvider);

    // We'll use a TextEditingController to let the user type search text
    final searchController = TextEditingController(text: searchText);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Filter Search'),
      ),
      body: allProductsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text("Error: $error")),
        data: (allProducts) {
          // "allProducts" is a List<Map<String, dynamic>>
          // 3) Local filter based on searchText
          final filteredProducts = _getFilteredResults(allProducts, searchText);

          return Column(
            children: [
              // === SEARCH TEXT FIELD ===
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Type product name (local filter)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // Update the searchTextProvider as user types
                    ref.read(searchTextProvider.notifier).state = value;
                  },
                ),
              ),

              // === RESULTS LIST ===
              Expanded(
                child: filteredProducts.isEmpty
                    ? const Center(child: Text("No matching products"))
                    : ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final name = product["Name"] ?? "Unnamed";
                          final brand = product["Brand Name"] ?? "Unknown Brand";
                          final code = product["Product Code"] ?? "No Code";

                          return ListTile(
                            title: Text(name),
                            subtitle: Text("Brand: $brand\nCode: $code"),
                            onTap: () {
                              // Do something when tapped 
                              // e.g., navigate to an update page
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Helper to filter the allProducts list based on user input
  List<Map<String, dynamic>> _getFilteredResults(
    List<Map<String, dynamic>> allProducts,
    String searchText,
  ) {
    if (searchText.isEmpty) {
      return allProducts;
    }

    final lowerText = searchText.toLowerCase();

    // returns only the products whose 'Name' 
    // contains the typed text (case-insensitive)
    return allProducts.where((product) {
      final name = product["Name"]?.toString().toLowerCase() ?? "";
      return name.contains(lowerText);
    }).toList();
  }
}