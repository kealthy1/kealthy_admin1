import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:kealthy_admin/view/list_notifier.dart';
import 'package:lottie/lottie.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

final documentIdProvider = StateProvider<String?>((ref) => null);

/// A notifier for storing up to 4 image bytes
class ProductImageNotifier extends StateNotifier<List<Uint8List?>> {
  ProductImageNotifier() : super(List.filled(4, null));

  void updateImage(int index, Uint8List? imageBytes) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) imageBytes else state[i],
    ];
  }

  void clear() {
    state = List.filled(4, null);
  }
}

class ExistingImageUrlsNotifier extends StateNotifier<List<String>> {
  ExistingImageUrlsNotifier() : super(List.filled(4, ''));

  /// Update the entire list with the doc's existing URLs
  void setExistingUrls(List<String> urls) {
    // Create a fixed-length list of 4 items, or fill with ''
    final updated = List<String>.filled(4, '', growable: false);
    for (int i = 0; i < urls.length && i < 4; i++) {
      updated[i] = urls[i];
    }
    state = updated;
  }

  /// Update a specific index if you want
  void updateUrl(int index, String url) {
    final newState = [...state];
    newState[index] = url;
    state = newState;
  }

  void clearAll() {
    state = List.filled(4, '');
  }
}

/// Providers for various fields
final productImageProvider =
    StateNotifierProvider<ProductImageNotifier, List<Uint8List?>>(
        (ref) => ProductImageNotifier());

final existingImageUrlsProvider =
    StateNotifierProvider<ExistingImageUrlsNotifier, List<String>>(
        (ref) => ExistingImageUrlsNotifier());

final ingredientsProvider =
    StateNotifierProvider<ListNotifier, List<String>>((ref) => ListNotifier());

final fssaiProvider =
    StateNotifierProvider<ListNotifier, List<String>>((ref) => ListNotifier());

// Providers for Deal of the Day and Deal of the Week dropdowns
final dealOfTheDayProvider = StateProvider<String>((ref) => 'false');
final dealOfTheWeekProvider = StateProvider<String>((ref) => 'false');

final loadingProvider = StateProvider<bool>((ref) => false);

/// Holds the Firestore suggestion results
final searchResultsProvider =
    StateProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        (ref) => []);

class OffersPage extends ConsumerStatefulWidget {
  const OffersPage({super.key});

  @override
  ConsumerState<OffersPage> createState() => _UpdateProductState();
}

class _UpdateProductState extends ConsumerState<OffersPage> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _offerPriceController = TextEditingController();
  final TextEditingController _offerSohController = TextEditingController();
  final TextEditingController _offerEndDateController = TextEditingController();

  /// A helper function to show a message (SnackBar or Toast)
  void _showMessage(String message) {
    if (kIsWeb) {
      // Show a SnackBar on web
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } else {
      // Use Fluttertoast on mobile
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.blueGrey,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  /// Picks an image from file picker and stores in productImageProvider
  Future<void> _pickImage(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // <-- Make sure this is TRUE so .bytes is actually filled
    );
    if (result != null && result.files.isNotEmpty) {
      final imageBytes = result.files.first.bytes;
      if (imageBytes != null) {
        ref.read(productImageProvider.notifier).updateImage(index, imageBytes);
      }
    }
  }

  /// Compress the image to ~200KB or less
  Future<Uint8List> compressImage(Uint8List originalBytes,
      {int maxSizeInKB = 200}) async {
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) return originalBytes;

    int quality = 90;
    Uint8List? compressed;
    do {
      compressed = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
      quality -= 10;
    } while (compressed.lengthInBytes > maxSizeInKB * 1024 && quality > 10);

    return compressed;
  }

  /// CLIENT-SIDE SUBSTRING SEARCH
  /// Fetch a limited set of Products (e.g., 50), then filter for docs whose
  /// 'Name' contains the typed query (case-insensitive).
  Future<void> _searchSuggestions(String query) async {
    final lowerQuery = query.trim().toLowerCase();

    if (lowerQuery.isEmpty) {
      // Clear any suggestions if user cleared the text
      ref.read(searchResultsProvider.notifier).state = [];
      return;
    }

    try {
      // Remove the limit entirely OR set a large limit if needed
      final snapshot = await FirebaseFirestore.instance
          .collection('Products')
          // .limit(50) // remove the limit if your data set is small enough
          .get();

      // Filter in memory for "contains substring"
      final matched = snapshot.docs.where((doc) {
        final name = (doc["Name"] ?? "").toString().toLowerCase().trim();
        return name.contains(lowerQuery);
      }).toList();

      // Update the Riverpod provider with the results
      ref.read(searchResultsProvider.notifier).state = matched;
    } catch (e) {
      _showMessage("Error searching product: $e");
    }
  }

  void _clearAllFields() {
    _searchController.clear();
    _offerPriceController.clear();
    _offerSohController.clear();
    _offerEndDateController.clear();

    ref.read(productImageProvider.notifier).clear();
    ref.read(existingImageUrlsProvider.notifier).clearAll();

    ref.read(documentIdProvider.notifier).state = null; // Riverpod state update
  }

  /// When user clicks on a suggestion, fill in the fields
  void _onSuggestionSelected(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    ref.read(documentIdProvider.notifier).state = doc.id;
    final data = doc.data();
    _searchController.text = data["Name"] ?? "";

    // Insert logic to update deal dropdowns based on Firestore flags
    final isDealOfDay = data["deal_of_the_day"] == true;
    final isDealOfWeek = data["deal_of_the_week"] == true;
    ref.read(dealOfTheDayProvider.notifier).state = isDealOfDay.toString();
    ref.read(dealOfTheWeekProvider.notifier).state = isDealOfWeek.toString();

    _offerPriceController.text = (data["offer_price"] ?? "").toString();
    _offerSohController.text = (data["offer_soh"] ?? "").toString();
    final rawDate = data["offer_end_date"];
    if (rawDate is Timestamp) {
      final date = rawDate.toDate();
      _offerEndDateController.text =
          "${date.day} ${_monthName(date.month)} ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')} UTC+5:30";
    } else {
      _offerEndDateController.text = "";
    }

    // Clear newly picked images
    ref.read(productImageProvider.notifier).clear();

    // Show doc's existing images in the UI
    final existingUrls = List<String>.from(data["ImageUrl"] ?? []);
    ref.read(existingImageUrlsProvider.notifier).setExistingUrls(existingUrls);
    print("Existing Image URLs: $existingUrls");

    _showMessage("Product fetched successfully!");
    ref.read(searchResultsProvider.notifier).state = [];
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month];
  }

  bool _validateFields() {
    if (_searchController.text.trim().isEmpty) {
      _showMessage("Please enter a product name to search.");
      return false;
    }

    if (_offerPriceController.text.trim().isEmpty) {
      _showMessage("Offer Price cannot be empty.");
      return false;
    }

    if (_offerSohController.text.trim().isEmpty) {
      _showMessage("Offer SOH cannot be empty.");
      return false;
    }
    if (_offerEndDateController.text.trim().isEmpty) {
      _showMessage("Offer End Date cannot be empty.");
      return false;
    }

    return true;
  }

  Future<void> _updateProduct() async {
    final documentId = ref.read(documentIdProvider);
    if (documentId == null) {
      _showMessage("No product selected or product not found!");
      return;
    }
    if (!_validateFields()) return;

    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Updating...', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );

    try {
      ref.read(loadingProvider.notifier).state = true;

      final dateFormat = DateFormat("d MMM yyyy 'at' HH:mm:ss 'UTC+5:30'");
      final parsedDate = dateFormat.parse(_offerEndDateController.text.trim());

      final productData = {
        "offer_price": double.parse(_offerPriceController.text.trim()),
        "offer_soh": int.parse(_offerSohController.text.trim()),
        "offer_end_date": Timestamp.fromDate(parsedDate),
        "deal_of_the_day": ref.read(dealOfTheDayProvider) == 'true',
        "deal_of_the_week": ref.read(dealOfTheWeekProvider) == 'true',
      };

      await FirebaseFirestore.instance
          .collection('Products')
          .doc(documentId)
          .update(productData);

      Navigator.of(context).pop(); // close the loading dialog
      ref.read(loadingProvider.notifier).state = false;
      _clearAllFields();

      _showSuccessAnimation();
      _showMessage("Product updated successfully!");
    } catch (e) {
      Navigator.of(context).pop(); // close the loading dialog
      ref.read(loadingProvider.notifier).state = false;
      _showMessage("Error updating product: $e");
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Lottie.asset(
              'lib/assets/animations/Animation - 1731992471934.json',
              repeat: false,
              onLoaded: (composition) {
                Future.delayed(composition.duration, () {
                  Navigator.of(context).pop(); // Close animation
                });
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch search results from Riverpod
    final searchResults = ref.watch(searchResultsProvider);
    final isLoading = ref.watch(loadingProvider);
    ref.watch(productImageProvider);
    final localImages = ref.watch(productImageProvider);
    final existingImages = ref.watch(existingImageUrlsProvider);

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Add Offers'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => _searchSuggestions(value),
                      decoration: const InputDecoration(
                        labelText: 'Enter Product name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                    // SUGGESTIONS CONTAINER
                    if (searchResults.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: searchResults.map((doc) {
                            final productName = doc["Name"] ?? "Unknown";
                            return InkWell(
                              onTap: () => _onSuggestionSelected(doc),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(productName),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // IMAGE PICKING
                    Wrap(
                      spacing: 18,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: List.generate(4, (index) {
                        final labels = [
                          'Front View',
                          'Back View',
                          'Canva image 1',
                          'Canva image 2'
                        ];

                        Widget child;
                        if (localImages[index] != null) {
                          // Display memory bytes
                          child = Image.memory(localImages[index]!,
                              fit: BoxFit.cover);
                        } else if (existingImages[index].isNotEmpty) {
                          // Show doc's existing image from Firestore
                          child = Image.network(
                            existingImages[index],
                            fit: BoxFit.cover,
                          );
                        } else {
                          // No new or existing image
                          child = const Icon(Icons.add_a_photo);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              labels[index],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _pickImage(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                height: screenWidth * 0.2,
                                width: screenWidth * 0.23,
                                child: child,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // MAIN FIELDS
                    DropdownButtonFormField<String>(
                      value: ref.watch(dealOfTheDayProvider) == 'true'
                          ? 'Deal of the Day'
                          : ref.watch(dealOfTheWeekProvider) == 'true'
                              ? 'Deal of the Week'
                              : null,
                      decoration: const InputDecoration(
                        labelText: 'Highlight Offer',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Deal of the Day', 'Deal of the Week']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(dealOfTheDayProvider.notifier).state =
                              (val == 'Deal of the Day').toString();
                          ref.read(dealOfTheWeekProvider.notifier).state =
                              (val == 'Deal of the Week').toString();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _offerPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Offer Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _offerSohController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Offer SOH',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _offerEndDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Offer End Date',
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          final now = DateTime.now();
                          final formatted =
                              "${picked.day} ${_monthName(picked.month)} ${picked.year} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} UTC+5:30";
                          _offerEndDateController.text = formatted;
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // UPDATE BUTTON
                    ElevatedButton(
                      onPressed: _updateProduct,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
