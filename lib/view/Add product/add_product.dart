import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kealthy_admin/view/Add%20product/provider.dart';
import 'package:kealthy_admin/view/excel_upload.dart';
import 'package:kealthy_admin/view/list_notifier.dart';
import 'package:kealthy_admin/view/yesno.dart';
import 'package:kealthy_admin/widgets/array_textfield.dart';
import 'package:kealthy_admin/widgets/custom_dropdown.dart';
import 'package:kealthy_admin/widgets/custom_textfield.dart';
import 'package:lottie/lottie.dart';
import 'package:image/image.dart' as img;

// // Providers for Ingredients and Micro-nutrients
// final ingredientsProvider =
//     StateNotifierProvider<ListNotifier, List<String>>((ref) => ListNotifier());

class ProductImageNotifier extends StateNotifier<List<Uint8List?>> {
  ProductImageNotifier() : super(List.filled(4, null));

  void updateImage(int index, Uint8List? imageBytes) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) imageBytes else state[i],
    ];
  }
}

class DropdownNotifier extends StateNotifier<String> {
  DropdownNotifier() : super('Add a product');

  void updateSelection(String newValue) {
    state = newValue;
  }
}

// Riverpod provider for dropdown state
final dropdownProvider = StateNotifierProvider<DropdownNotifier, String>(
    (ref) => DropdownNotifier());

// Riverpod provider for ProductImageNotifier
final productImageProvider =
    StateNotifierProvider<ProductImageNotifier, List<Uint8List?>>(
        (ref) => ProductImageNotifier());

final loadingProvider = StateProvider<bool>((ref) => false);

class AddProduct extends ConsumerStatefulWidget {
  const AddProduct({super.key});

  @override
  _AddProductState createState() => _AddProductState();
}

class _AddProductState extends ConsumerState<AddProduct> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  // Controllers for product details
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _vendorNameController = TextEditingController();
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subCategoryController = TextEditingController();
  final TextEditingController _netQuantityController = TextEditingController();
  final TextEditingController _energyController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbohydratesController =
      TextEditingController();
  final TextEditingController _sugarsController = TextEditingController();
  final TextEditingController _addedSugarsController = TextEditingController();
  final TextEditingController _dietaryFiberController = TextEditingController();
  final TextEditingController _totalFatController = TextEditingController();
  final TextEditingController _transFatController = TextEditingController();
  final TextEditingController _saturatedFatController = TextEditingController();
  final TextEditingController _unsaturatedFatController =
      TextEditingController();
  final TextEditingController _cholesterolController = TextEditingController();
  final TextEditingController _caffeinController = TextEditingController();
  final TextEditingController _sodiumController = TextEditingController();
  final TextEditingController _ironController = TextEditingController();
  final TextEditingController _calciumController = TextEditingController();
  final TextEditingController _copperController = TextEditingController();
  final TextEditingController _magnesiumController = TextEditingController();
  final TextEditingController _phosphorusController = TextEditingController();
  final TextEditingController _potassiumController = TextEditingController();
  final TextEditingController _zincController = TextEditingController();
  final TextEditingController _manganeseController = TextEditingController();
  final TextEditingController _seleniumController = TextEditingController();
  final TextEditingController _vitaminB2Controller = TextEditingController();
  final TextEditingController _vitaminB6Controller = TextEditingController();
  final TextEditingController _vitaminAController = TextEditingController();
  final TextEditingController _whatIsItController = TextEditingController();
  final TextEditingController _whatIsItUsedForController =
      TextEditingController();
  final TextEditingController _sohController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final TextEditingController _manufacturerAddressController =
      TextEditingController();
  final TextEditingController _eanController = TextEditingController();
  final TextEditingController _importedByController = TextEditingController(
      text:
          'COTOLORE ENTERPRISES LLP15/293-C, Muriyankara - Pinarmunda RoadPeringala, Ernakulam - 683565');
  final TextEditingController _originController =
      TextEditingController(text: 'India');
  final TextEditingController _bestBeforeController = TextEditingController();
  final TextEditingController _servingSizeController = TextEditingController();

// State management for list-based data (ingredients and micronutrients)
  final ingredientsProvider = StateNotifierProvider<ListNotifier, List<String>>(
      (ref) => ListNotifier());

  final fssaiProvider = StateNotifierProvider<ListNotifier, List<String>>(
      (ref) => ListNotifier());

// Boolean properties managed by Riverpod StateProvider
  final _organicProvider = StateProvider<String>((ref) => '');
  final _additivesProvider = StateProvider<String>((ref) => '');
  final _artificialSweetenersProvider = StateProvider<String>((ref) => '');
  final _glutenFreeProvider = StateProvider<String>((ref) => 'No');
  final _veganFriendlyProvider = StateProvider<String>((ref) => 'No');
  final _ketoFriendlyProvider = StateProvider<String>((ref) => 'No');
  final _lowGIProvider = StateProvider<String>((ref) => 'No');
  final _lowSugarProvider = StateProvider<String>((ref) => 'No');
  final _ecoFriendlyProvider = StateProvider<String>((ref) => '');
  final _recyclablePackagingProvider = StateProvider<String>((ref) => '');

  // List to store selected images
  final List<Uint8List?> _selectedImages = List.filled(4, null);

  // Function to pick image for web
  Future<void> _pickImage(int index, WidgetRef ref) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      final imageBytes = result.files.first.bytes;
      if (imageBytes != null) {
        ref.read(productImageProvider.notifier).updateImage(index, imageBytes);
        _selectedImages[index] =
            imageBytes; // Update the local _selectedImages list
      }
    } else {
      Fluttertoast.showToast(
        msg: "No image selected",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
  // Controllers for form fields
  // (existing controllers)

  // State for file upload

  Future<Uint8List> compressImage(Uint8List originalBytes,
      {int maxSizeInKB = 100}) async {
    // Decode image
    img.Image? image = img.decodeImage(originalBytes);
    if (image == null) return originalBytes;

    // Start compression loop
    int quality = 90;
    Uint8List? compressedBytes;
    do {
      compressedBytes =
          Uint8List.fromList(img.encodeJpg(image, quality: quality));
      quality -= 10;
    } while (
        compressedBytes.lengthInBytes > maxSizeInKB * 1024 && quality > 10);

    return compressedBytes;
  }

  // Upload images to Firebase Storage and return their URLs
  // Upload images to Firebase Storage and return their URLs
  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    for (int i = 0; i < _selectedImages.length; i++) {
      if (_selectedImages[i] != null) {
        // Compress the image before uploading
        Uint8List compressedImage = await compressImage(_selectedImages[i]!);

        String fileName =
            'product_image_${DateTime.now().millisecondsSinceEpoch}_$i';
        Reference ref =
            FirebaseStorage.instance.ref().child('product_images/$fileName');
        UploadTask uploadTask = ref.putData(
          compressedImage,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
    }
    return imageUrls;
  }

  Future<void> _addProductToFirebase(WidgetRef ref) async {
    // Show loading dialog
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
              Text('Uploading...', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );

    try {
      ref.read(loadingProvider.notifier).state = true;

      final ingredients = ref.read(ingredientsProvider);
      final fssai = ref.read(fssaiProvider);
      List<String> imageUrls = await _uploadImages();

      final productData = {
        // 🔹 Strings
        "Product Code": _productCodeController.text,
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
        "Best Before": _bestBeforeController.text,
        "Serving size": _servingSizeController.text,
        "What is it?": _whatIsItController.text,
        "What is it used for?": _whatIsItUsedForController.text,
        "Ingredients": ingredients,
        "FSSAI": fssai,
        "ImageUrl": imageUrls,
        "Energy (kcal)": _energyController.text,
        "Protein (g)": _proteinController.text,
        "Total Carbohydrates (g)": _carbohydratesController.text,
        "Sugars (g)": _sugarsController.text,
        "Added Sugars (g)": _addedSugarsController.text,
        "Dietary Fiber (g)": _dietaryFiberController.text,
        "Total Fat (g)": _totalFatController.text,
        "Trans Fat (g)": _transFatController.text,
        "Saturated Fat (g)": _saturatedFatController.text,
        "Unsaturated Fat (g)": _unsaturatedFatController.text,
        "Cholesterol (mg)": _cholesterolController.text,
        "Caffeine Content (mg)": _caffeinController.text,
        "Sodium (mg)": _sodiumController.text,
        "Iron (mg)": _ironController.text,
        "Calcium (mg)": _calciumController.text,
        "Copper (mg)": _copperController.text,
        "Magnesium (mg)": _magnesiumController.text,
        "Phosphorus (mg)": _phosphorusController.text,
        "Potassium (mg)": _potassiumController.text,
        "Zinc (mg)": _zincController.text,
        "Manganese (mg)": _manganeseController.text,
        "Selenium (mcg)": _seleniumController.text,
        "Vitamin B2": _vitaminB2Controller.text,
        "Vitamin B6 (Pyridoxine)": _vitaminB6Controller.text,
        "Vitamin A": _vitaminAController.text,
        "SOH": double.tryParse(_sohController.text) ?? 0.0,
        "Price": double.tryParse(_priceController.text) ?? 0.0,
        "Organic": ref.read(_organicProvider),
        "Additives/Preservatives": ref.read(_additivesProvider),
        "Artificial Sweeteners or Colors":
            ref.read(_artificialSweetenersProvider),
        "Gluten-free": ref.read(_glutenFreeProvider),
        "Vegan-Friendly": ref.read(_veganFriendlyProvider),
        "Keto Friendly": ref.read(_ketoFriendlyProvider),
        "Low GI": ref.read(_lowGIProvider),
        "Low Sugar (less than 5g per serving)": ref.read(_lowSugarProvider),
        "Eco-Friendly": ref.read(_ecoFriendlyProvider),
        "Recyclable Packaging": ref.read(_recyclablePackagingProvider),
        "timestamp": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('Products').add(productData);

      ref.read(loadingProvider.notifier).state = false;
      Navigator.of(context).pop();

      _clearFields(ref);
      _showSuccessAnimation(context);

      Fluttertoast.showToast(
        msg: "Product added successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      ref.read(loadingProvider.notifier).state = false;
      Navigator.of(context).pop();

      Fluttertoast.showToast(
        msg: "Error adding product: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _clearFields(WidgetRef ref) {
    _productCodeController.clear();
    _vendorNameController.clear();
    _brandNameController.clear();
    _productNameController.clear();
    _categoryController.clear();
    _subCategoryController.clear();
    _netQuantityController.clear();
    _energyController.clear();
    _proteinController.clear();
    _carbohydratesController.clear();
    _sugarsController.clear();
    _addedSugarsController.clear();
    _dietaryFiberController.clear();
    _totalFatController.clear();
    _transFatController.clear();
    _saturatedFatController.clear();
    _unsaturatedFatController.clear();
    _cholesterolController.clear();
    _caffeinController.clear();
    _sodiumController.clear();
    _calciumController.clear();
    _copperController.clear();
    _ironController.clear();
    _magnesiumController.clear();
    _manganeseController.clear();
    _phosphorusController.clear();
    _zincController.clear();
    _seleniumController.clear();
    _vitaminAController.clear();
    _vitaminB2Controller.clear();
    _vitaminB6Controller.clear();
    _potassiumController.clear();
    _whatIsItController.clear();
    _whatIsItUsedForController.clear();

    _sohController.clear();
    _priceController.clear();

    ref.read(selectedCategoryProvider.notifier).state = '';
    ref.read(selectedSubCategoryProvider.notifier).state = '';

    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    ref.read(ingredientsProvider.notifier).state = [];
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    ref.read(fssaiProvider.notifier).state = [];
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    ref.read(productImageProvider.notifier).state = List.filled(4, null);

    // Reset booleans
    ref.read(_organicProvider.notifier).state = '';
    ref.read(_additivesProvider.notifier).state = '';
    ref.read(_artificialSweetenersProvider.notifier).state = '';
    ref.read(_glutenFreeProvider.notifier).state = 'No';
    ref.read(_veganFriendlyProvider.notifier).state = 'No';
    ref.read(_ketoFriendlyProvider.notifier).state = 'No';
    ref.read(_lowGIProvider.notifier).state = 'No';
    ref.read(_lowSugarProvider.notifier).state = 'No';
    ref.read(_ecoFriendlyProvider.notifier).state = '';
    ref.read(_recyclablePackagingProvider.notifier).state = '';
  }

  void _showSuccessAnimation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            width: 200,
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Lottie.asset(
                'lib/assets/animations/Animation - 1731992471934.json', // Your Lottie animation file
                repeat: false,
                onLoaded: (composition) {
                  Future.delayed(composition.duration, () {
                    Navigator.of(context).pop(); // Close the animation dialog
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }

  bool _validateFields() {
    final images = ref.read(productImageProvider);

    // Validate that all images are selected
    for (int i = 0; i < images.length; i++) {
      if (images[i] == null) {
        _showToast("Please upload the ${_getImageLabel(i)} image");
        return false;
      }
    }

    // Validate required string fields
    final requiredFields = {
      "Product Code": _productCodeController.text,
      "Vendor Name": _vendorNameController.text,
      "Brand Name": _brandNameController.text,
      "Product Name": _productNameController.text,
      "Category": ref.read(selectedCategoryProvider),
      "Subcategory": ref.read(selectedSubCategoryProvider),
      "Net Quantity": _netQuantityController.text,
      "Energy": _energyController.text,
      "Protein": _proteinController.text,
      "Carbohydrates": _carbohydratesController.text,
      "Sugars": _sugarsController.text,
      "Added Sugars": _addedSugarsController.text,
      "Dietary Fiber": _dietaryFiberController.text,
      "Total Fat": _totalFatController.text,
      "Trans Fat": _transFatController.text,
      "Saturated Fat": _saturatedFatController.text,
      "Unsaturated Fat": _unsaturatedFatController.text,
      "Cholesterol": _cholesterolController.text,
      "Caffein": _caffeinController.text,
      "EAN": _eanController.text,
      "Best Before": _bestBeforeController.text,
      "Serving size": _servingSizeController.text,
    };

    for (var entry in requiredFields.entries) {
      if (entry.value.isEmpty) {
        _showToast("Please enter the ${entry.key} value");
        return false;
      }
    }

    if (_sohController.text.isNotEmpty &&
        double.tryParse(_sohController.text) == null) {
      _showToast("Please enter a numeric value for the SOH field");
      return false;
    }

    if (_priceController.text.isNotEmpty &&
        double.tryParse(_priceController.text) == null) {
      _showToast("Please enter a numeric value for the Price field");
      return false;
    }

    // Validate ingredients array
    if (ref.read(ingredientsProvider).isEmpty) {
      _showToast("Please add at least one Ingredient");
      return false;
    }

    if (ref.read(fssaiProvider).isEmpty) {
      _showToast("Please add fssai no.");
      return false;
    }

    return true;
  }

  String _getImageLabel(int index) {
    const labels = ['Front View', 'Back View', 'Description', 'Ingredients'];
    return labels[index];
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final images = ref.watch(productImageProvider);
    final selectedOption = ref.watch(dropdownProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text('Add Product', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Text(
                      'Select an option',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Dropdown Menu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Container(
                      width: screenWidth * 0.28,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius:
                            BorderRadius.circular(10), // Rounded corners
                        color: Colors.white, // Background color
                      ),
                      child: DropdownButton<String>(
                        dropdownColor: Colors.white,
                        focusColor: Colors.white,
                        value: selectedOption,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            ref
                                .read(dropdownProvider.notifier)
                                .updateSelection(newValue);
                          }
                        },
                        items: <String>['Add a product', 'Add an excel']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        underline: Container(), // Remove default underline
                        isExpanded: true, // Makes the dropdown full width
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Conditional UI based on dropdown selection
                if (selectedOption == 'Add a product') ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Enter product data',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Wrap(
                      spacing: 18, // Horizontal space between containers
                      runSpacing: 16, // Vertical space between rows
                      alignment: WrapAlignment.center,
                      children: List.generate(4, (index) {
                        final labels = [
                          'Front View',
                          'Back View',
                          'Canva image 1',
                          'Canva image 2'
                        ];
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              labels[index],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _pickImage(index, ref),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                height: screenWidth * 0.2, // Container height
                                width: screenWidth * 0.23, // Adjust width
                                child: images[index] != null
                                    ? Image.memory(
                                        images[index]!,
                                        fit: BoxFit.cover,
                                      )
                                    : const Center(
                                        child: Icon(Icons.add_a_photo),
                                      ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),

                  // Image Grid Section

                  const SizedBox(height: 20),
                  Center(
                    child: Wrap(
                      spacing: 16, // Horizontal spacing
                      runSpacing: 16, // Vertical spacing
                      children: [
                        // Text Fields
                        CustomTextFieldWithTitle(
                          title: 'Product Code',
                          hint: 'Enter Product Code',
                          controller: _productCodeController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Vendor Name',
                          hint: 'Enter Vendor Name',
                          controller: _vendorNameController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Brand Name',
                          hint: 'Enter Product Brand Name',
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
                          hint: 'Enter Quantity',
                          controller: _netQuantityController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Energy (kcal)',
                          hint: 'Enter Quantity',
                          controller: _energyController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Protein (g)',
                          hint: 'Enter Quantity',
                          controller: _proteinController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Total Carbohydrates (g)',
                          hint: 'Enter Quantity',
                          controller: _carbohydratesController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Sugars (g)',
                          hint: 'Enter Quantity',
                          controller: _sugarsController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Added Sugars (g)',
                          hint: 'Enter Quantity',
                          controller: _addedSugarsController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Dietary Fiber (g)',
                          hint: 'Enter Quantity',
                          controller: _dietaryFiberController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Total Fat (g)',
                          hint: 'Enter Quantity',
                          controller: _totalFatController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Trans Fat (g)',
                          hint: 'Enter Quantity',
                          controller: _transFatController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Saturated Fat (g)',
                          hint: 'Enter Quantity',
                          controller: _saturatedFatController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Unsaturated Fat (g)',
                          hint: 'Enter Quantity',
                          controller: _unsaturatedFatController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Cholesterol (mg)',
                          hint: 'Enter Quantity',
                          controller: _cholesterolController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Caffein (mg)',
                          hint: 'Enter Quantity',
                          controller: _caffeinController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Sodium (mg)',
                          hint: 'Enter Quantity',
                          controller: _sodiumController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Iron (mg)',
                          hint: 'Enter Quantity',
                          controller: _ironController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Calcium (mg)',
                          hint: 'Enter Quantity',
                          controller: _calciumController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Copper(mg)',
                          hint: 'Enter Quantity',
                          controller: _copperController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Magnesium (mg)',
                          hint: 'Enter Quantity',
                          controller: _magnesiumController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Phosphorus (mg)',
                          hint: 'Enter Quantity',
                          controller: _phosphorusController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Potassium (mg)',
                          hint: 'Enter Quantity',
                          controller: _potassiumController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Zinc (mg)',
                          hint: 'Enter Quantity',
                          controller: _zincController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Manganese (mg)',
                          hint: 'Enter Quantity',
                          controller: _manganeseController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Selenium (mg)',
                          hint: 'Enter Quantity',
                          controller: _seleniumController,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'VitaminB2 (mg)',
                          hint: 'Enter Quantity',
                          controller: _vitaminB2Controller,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'VitaminB6 (mg)',
                          hint: 'Enter Quantity',
                          controller: _vitaminB6Controller,
                          inputType: TextInputType.number,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'VitaminA (mg)',
                          hint: 'Enter Quantity',
                          controller: _vitaminAController,
                          inputType: TextInputType.number,
                        ),

                        CustomTextFieldWithTitle(
                          title: 'What is it?',
                          hint: 'Enter Description',
                          controller: _whatIsItController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'What is it used for?',
                          hint: 'Enter Description',
                          controller: _whatIsItUsedForController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'SOH',
                          hint: 'Enter Value',
                          controller: _sohController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Price',
                          hint: 'Enter the Price',
                          controller: _priceController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Manufacture Address',
                          hint: 'Enter the Address',
                          controller: _manufacturerAddressController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'EAN',
                          hint: 'Enter the EAN',
                          controller: _eanController,
                        ),
                        CustomTextFieldWithTitle(
                          enabled: false,
                          title: 'Imported&Marketed By',
                          hint: 'Enter the value',
                          controller: _importedByController,
                        ),
                        CustomTextFieldWithTitle(
                          enabled: false,
                          title: 'Origin',
                          hint: 'Enter the origin',
                          controller: _originController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Best Before',
                          hint: 'Enter the value',
                          controller: _bestBeforeController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Serving Size',
                          hint: 'Enter value',
                          controller: _servingSizeController,
                        ),

                        // Dropdowns for Boolean Fields
                        CustomDropdownWithTitle(
                          title: 'Is this product organic?',
                          provider: _organicProvider,
                          options: const [
                            'Fully Organic',
                            'Partially Organic',
                            'Non-Organic'
                          ],
                        ),
                        CustomDropdownWithTitle(
                          title: 'Does it contain additives?',
                          provider: _additivesProvider,
                          options: const [
                            'No additives/Preservatives',
                            'Minimal natural Additives/Preservatives',
                            'Artifical Additives/Preservatives'
                          ],
                        ),
                        CustomDropdownWithTitle(
                          title:
                              'Does it contain artificial sweeteners or colors?',
                          provider: _artificialSweetenersProvider,
                          options: const ['None', 'Limited', 'Present'],
                        ),

                        YesNoDropdownWithTitle(
                          title: 'Is the product gluten-free?',
                          label: 'Select Gluten-Free',
                          provider: _glutenFreeProvider,
                        ),
                        YesNoDropdownWithTitle(
                          title: 'Is the product vegan-friendly?',
                          label: 'Select Vegan-Friendly',
                          provider: _veganFriendlyProvider,
                        ),
                        YesNoDropdownWithTitle(
                          title: 'Is the product keto-friendly?',
                          label: 'Select Keto-Friendly',
                          provider: _ketoFriendlyProvider,
                        ),
                        YesNoDropdownWithTitle(
                          title: 'Does it have a low glycemic index?',
                          label: 'Select Low GI',
                          provider: _lowGIProvider,
                        ),
                        YesNoDropdownWithTitle(
                          title:
                              'Is it low in sugar (less than 5g per serving)?',
                          label: 'Select Low Sugar',
                          provider: _lowSugarProvider,
                        ),
                        CustomDropdownWithTitle(
                          title: 'Is the product eco-friendly?',
                          provider: _ecoFriendlyProvider,
                          options: const [
                            'Sustainable/Ethical Sourcing',
                            'Partially Sustainable',
                            'Not Sustainable'
                          ],
                        ),
                        CustomDropdownWithTitle(
                          title: 'Does it use recyclable packaging?',
                          provider: _recyclablePackagingProvider,
                          options: const [
                            'Fully Recyclable',
                            'Partially Recyclable',
                            'Non-Recyclable'
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                          ),
                          child: ArrayInputWithTitle(
                            title: 'FSSAI',
                            hintText: ' Enter FSSAI',
                            provider: fssaiProvider,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                          ),
                          child: ArrayInputWithTitle(
                            title: 'Ingredients',
                            hintText: 'Add an ingredient',
                            provider: ingredientsProvider,
                          ),
                        ),
                      ]
                          .map((field) => SizedBox(
                                width: screenWidth / 3 -
                                    32, // Adjust width for each item
                                child: field,
                              ))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Submit Button
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: 50,
                      width: 100,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: () {
                          if (_validateFields()) {
                            _addProductToFirebase(ref);
                          }
                        },
                        child: const Text(
                          'Upload',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else if (selectedOption == 'Add an excel') ...[
                  const ExcelUploader(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
