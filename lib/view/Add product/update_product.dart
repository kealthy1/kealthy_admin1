import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:kealthy_admin/view/Add%20product/provider.dart';
import 'package:kealthy_admin/view/list_notifier.dart';
import 'package:lottie/lottie.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kealthy_admin/widgets/custom_textfield.dart';
import 'package:kealthy_admin/widgets/array_textfield.dart';

final documentIdProvider = StateProvider<String?>((ref) => null);

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

final organicProvider = StateProvider<String>((ref) => '');
final additivesProvider = StateProvider<String>((ref) => '');
final artificialSweetenersProvider = StateProvider<String>((ref) => '');
final glutenFreeProvider = StateProvider<String>((ref) => 'No');
final veganFriendlyProvider = StateProvider<String>((ref) => 'No');
final ketoFriendlyProvider = StateProvider<String>((ref) => 'No');
final lowGIProvider = StateProvider<String>((ref) => 'No');
final lowSugarProvider = StateProvider<String>((ref) => 'No');
final ecoFriendlyProvider = StateProvider<String>((ref) => '');
final recyclablePackagingProvider = StateProvider<String>((ref) => '');

final loadingProvider = StateProvider<bool>((ref) => false);

/// Holds the Firestore suggestion results
final searchResultsProvider =
    StateProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        (ref) => []);

class UpdateProduct extends ConsumerStatefulWidget {
  const UpdateProduct({super.key});

  @override
  ConsumerState<UpdateProduct> createState() => _UpdateProductState();
}

class _UpdateProductState extends ConsumerState<UpdateProduct> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _vendorNameController = TextEditingController();
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subCategoryController = TextEditingController();
  final TextEditingController _netQuantityController = TextEditingController();
  final TextEditingController _sohController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _manufacturerAddressController =
      TextEditingController();
  final TextEditingController _eanController = TextEditingController();
  final TextEditingController _importedByController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _manufacturedDateController =
      TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _bestBeforeController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _servingSizeController = TextEditingController();

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
      {int maxSizeInKB = 100}) async {
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

  /// Upload newly selected images to Firebase Storage
  Future<List<String>> _uploadImages() async {
    final images = ref.read(productImageProvider); // newly picked in memory
    final existingImages = ref.read(existingImageUrlsProvider);

    final uploadedUrls = <String>[];

    for (int i = 0; i < images.length; i++) {
      final imageBytes = images[i];
      if (imageBytes != null) {
        // user picked a new image for this slot
        final compressed = await compressImage(imageBytes);
        final fileName =
            'product_image_${DateTime.now().millisecondsSinceEpoch}_$i';
        final refStorage =
            FirebaseStorage.instance.ref().child('product_images/$fileName');
        final snapshot = await refStorage.putData(
          compressed,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final downloadUrl = await snapshot.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      } else {
        // no new image picked for this slot. Keep the old one if it exists
        final oldUrl = existingImages[i];
        if (oldUrl.isNotEmpty) {
          uploadedUrls.add(oldUrl);
        } else {
          // If there's no old URL, we might just skip or store an empty string
          uploadedUrls.add('');
        }
      }
    }

    return uploadedUrls;
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
    _vendorNameController.clear();
    _brandNameController.clear();
    _productNameController.clear();
    _categoryController.clear();
    _subCategoryController.clear();
    _netQuantityController.clear();
    _sohController.clear();
    _priceController.clear();
    _manufacturerAddressController.clear();
    _eanController.clear();
    _importedByController.clear();
    _originController.clear();
    _manufacturedDateController.clear();
    _expiryController.clear();
    _bestBeforeController.clear();
    _servingSizeController.clear();

    ref.read(selectedCategoryProvider.notifier).state = '';
    ref.read(selectedSubCategoryProvider.notifier).state = '';

    ref.read(fssaiProvider.notifier).clearItems();
    ref.read(productImageProvider.notifier).clear();
    ref.read(existingImageUrlsProvider.notifier).clearAll();

    ref.read(documentIdProvider.notifier).state = null; // Riverpod state update
  }

  /// When user clicks on a suggestion, fill in the fields
  void _onSuggestionSelected(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    ref.read(documentIdProvider.notifier).state = doc.id;
    final data = doc.data();
    _searchController.text = data["Name"] ?? "";

    _vendorNameController.text = data["Vendor Name"] ?? "";
    _brandNameController.text = data["Brand Name"] ?? "";
    _productNameController.text = data["Name"] ?? "";
    ref.read(selectedCategoryProvider.notifier).state = data["Category"] ?? '';
    ref.read(selectedSubCategoryProvider.notifier).state =
        data["Subcategory"] ?? '';
    _netQuantityController.text = data["Qty"] ?? "";
    _manufacturerAddressController.text = data["Manufacturer Address"] ?? "";
    _eanController.text = data["EAN"] ?? "";
    _importedByController.text = data["Imported&Marketed By"] ?? "";
    _expiryController.text = data["Expiry"] ?? "";
    _bestBeforeController.text = data["Best Before"] ?? "";
    _originController.text = data["Orgin"] ?? "";
    _servingSizeController.text = data["Serving size"] ?? "";
    _sohController.text = (data["SOH"] ?? 0.0).toString();
    _priceController.text = (data["Price"] ?? 0.0).toString();

    // FSSAI list
    final fssaiList = List<String>.from(data["FSSAI"] ?? []);
    ref.read(fssaiProvider.notifier).setItems(fssaiList);

    // Clear newly picked images
    ref.read(productImageProvider.notifier).clear();

    // Show doc's existing images in the UI
    final existingUrls = List<String>.from(data["ImageUrl"] ?? []);
    ref.read(existingImageUrlsProvider.notifier).setExistingUrls(existingUrls);
    print("Existing Image URLs: $existingUrls");

    _showMessage("Product fetched successfully!");
    ref.read(searchResultsProvider.notifier).state = [];
  }

  bool _validateFields() {
    if (_productNameController.text.isEmpty) {
      _showMessage("Product Name is required.");
      return false;
    }

    if (double.tryParse(_priceController.text.trim()) == null) {
      _showMessage("Price must be a valid number.");
      return false;
    }

    if (int.tryParse(_sohController.text.trim()) == null) {
      _showMessage("SOH (Stock on Hand) must be a valid number.");
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

      // Upload images if any newly picked
      final newImageUrls = await _uploadImages();
      final fssai = ref.read(fssaiProvider);

      final productData = {
        "Vendor Name": _vendorNameController.text,
        "Brand Name": _brandNameController.text,
        "Name": _productNameController.text,
        "Category": ref.read(selectedCategoryProvider),
        "Subcategory": ref.read(selectedSubCategoryProvider),
        "Qty": _netQuantityController.text,
        "Manufacturer Address": _manufacturerAddressController.text,
        "EAN": _eanController.text,
        "Imported&Marketed By": _importedByController.text,
        "Orgin": _originController.text,
        "Manufactured date": _manufacturedDateController.text,
        "Expiry": _expiryController.text,
        "Best Before": _bestBeforeController.text,
        "Type": _typeController.text,
        "Serving size": _servingSizeController.text,
        "FSSAI": fssai,

        // ✅ Add these two lines to update SOH and Price
        "SOH": int.parse(_sohController.text.trim()),
        "Price": double.parse(_priceController.text.trim()),
      };

      if (newImageUrls.isNotEmpty) {
        productData["ImageUrl"] = newImageUrls;
      }

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
        title: const Text('Update Product'),
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
                    // SEARCH TEXT FIELD
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

                    const SizedBox(height: 24),

                    // MAIN FIELDS
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        CustomTextFieldWithTitle(
                          title: 'Vendor Name',
                          hint: 'Enter Vendor Name',
                          controller: _vendorNameController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Brand Name',
                          hint: 'Enter Brand Name',
                          controller: _brandNameController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Product Name',
                          hint: 'Enter Product Name',
                          controller: _productNameController,
                        ),
                        Consumer(builder: (context, ref, _) {
                          final categoriesAsync = ref.watch(categoriesProvider);
                          final selectedCategory =
                              ref.watch(selectedCategoryProvider);

                          final isLoading = categoriesAsync.isLoading;
                          final categories = categoriesAsync.value ?? [];

                          final isValid = categories.contains(selectedCategory);

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Category',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Stack(
                                  alignment: Alignment.centerRight,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey, width: 1),
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: DropdownButton<String>(
                                        value:
                                            isValid ? selectedCategory : null,
                                        isExpanded: true,
                                        hint: const Text('Select Category',
                                            style:
                                                TextStyle(color: Colors.black)),
                                        underline: const SizedBox.shrink(),
                                        items: categories.map((cat) {
                                          return DropdownMenuItem<String>(
                                            value: cat,
                                            child: Text(cat),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            ref
                                                .read(selectedCategoryProvider
                                                    .notifier)
                                                .state = value;
                                            ref
                                                .read(
                                                    selectedSubCategoryProvider
                                                        .notifier)
                                                .state = '';
                                          }
                                        },
                                      ),
                                    ),
                                    if (isLoading)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 40),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                        Consumer(builder: (context, ref, _) {
                          final selectedCategory =
                              ref.watch(selectedCategoryProvider);
                          final selectedSubCategory =
                              ref.watch(selectedSubCategoryProvider);
                          final subcatsAsync = ref
                              .watch(subcategoriesProvider(selectedCategory));

                          final isLoading = subcatsAsync.isLoading;
                          final subcategories = subcatsAsync.value ?? [];

                          final isValid =
                              subcategories.contains(selectedSubCategory);

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Subcategory',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Stack(
                                  alignment: Alignment.centerRight,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey, width: 1),
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: DropdownButton<String>(
                                        value: isValid
                                            ? selectedSubCategory
                                            : null,
                                        isExpanded: true,
                                        hint: const Text('Select Subcategory',
                                            style:
                                                TextStyle(color: Colors.black)),
                                        underline: const SizedBox.shrink(),
                                        items: subcategories.map((sub) {
                                          return DropdownMenuItem<String>(
                                            value: sub,
                                            child: Text(sub),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            ref
                                                .read(
                                                    selectedSubCategoryProvider
                                                        .notifier)
                                                .state = value;
                                          }
                                        },
                                      ),
                                    ),
                                    if (isLoading)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 40),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                        CustomTextFieldWithTitle(
                          title: 'Net Quantity',
                          hint: 'Enter Net Quantity',
                          controller: _netQuantityController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'SOH',
                          hint: 'Enter Stock on Hand',
                          controller: _sohController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Orgin',
                          hint: 'Enter Value',
                          controller: _originController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Price',
                          hint: 'Enter Price',
                          controller: _priceController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Manufacturer Address',
                          hint: 'Enter Address',
                          controller: _manufacturerAddressController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'EAN',
                          hint: 'Enter EAN',
                          controller: _eanController,
                        ),
                        CustomTextFieldWithTitle(
                          enabled: false,
                          title: 'Imported & Marketed By',
                          hint: 'Enter Value',
                          controller: _importedByController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Expiry',
                          hint: 'Enter Expiry',
                          controller: _expiryController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Best Before',
                          hint: 'Enter Value',
                          controller: _bestBeforeController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Serving Size',
                          hint: 'Enter Value',
                          controller: _servingSizeController,
                        ),

                        // Arrays
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ArrayInputWithTitle(
                            title: 'FSSAI',
                            hintText: 'Enter FSSAI',
                            provider: fssaiProvider,
                          ),
                        ),
                      ]
                          .map(
                            (field) => SizedBox(
                              width: screenWidth / 3 - 32,
                              child: field,
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 24),

                    // UPDATE BUTTON
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                            'Update Product',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (ref.watch(documentIdProvider) != null)
                          ElevatedButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text("Confirm Deletion"),
                                    ],
                                  ),
                                  content: const Text(
                                    "Are you sure you want to delete this product permanently? This action cannot be undone.",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text(
                                          "Cancel",
                                          style: TextStyle(color: Colors.black),
                                        )),
                                    ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text(
                                          "Delete",
                                          style: TextStyle(color: Colors.white),
                                        )),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final docId = ref.read(documentIdProvider);
                                if (docId != null) {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('Products')
                                        .doc(docId)
                                        .delete();
                                    _showMessage(
                                        "Product deleted successfully!");
                                    _clearAllFields();
                                  } catch (e) {
                                    _showMessage(
                                        "Failed to delete product: $e");
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'Delete Product',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),

          // LOADING OVERLAY
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
