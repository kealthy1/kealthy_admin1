import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kealthy_admin/view/excel_upload.dart';
import 'package:kealthy_admin/view/yesno.dart';
import 'package:kealthy_admin/widgets/array_textfield.dart';
import 'package:kealthy_admin/widgets/custom_dropdown.dart';
import 'package:kealthy_admin/widgets/custom_textfield.dart';
import 'package:lottie/lottie.dart';

class ListNotifier extends StateNotifier<List<String>> {
  ListNotifier() : super([]);

  void addItem(String item) {
    state = [...state, item];
    print("Micronutrient Added: $item");
    print("Current Micronutrients: $state");
  }

  void removeItem(int index) {
    state = [...state]..removeAt(index);
  }
}

// Providers for Ingredients and Micro-nutrients
final ingredientsProvider =
    StateNotifierProvider<ListNotifier, List<String>>((ref) => ListNotifier());

final microNutrientsProvider =
    StateNotifierProvider<ListNotifier, List<String>>((ref) => ListNotifier());

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
  final TextEditingController _whatIsItController = TextEditingController();
  final TextEditingController _whatIsItUsedForController =
      TextEditingController();
      final TextEditingController _kealthyscoreController =
      TextEditingController();
      final TextEditingController _hsnController =
      TextEditingController();
      final TextEditingController _priceController =
      TextEditingController();

// State management for list-based data (ingredients and micronutrients)
  final ingredientsProvider = StateNotifierProvider<ListNotifier, List<String>>(
      (ref) => ListNotifier());
  final microNutrientsProvider =
      StateNotifierProvider<ListNotifier, List<String>>(
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

  // Upload images to Firebase Storage and return their URLs
  // Upload images to Firebase Storage and return their URLs
  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    for (int i = 0; i < _selectedImages.length; i++) {
      if (_selectedImages[i] != null) {
        String fileName =
            'product_image_${DateTime.now().millisecondsSinceEpoch}_$i';
        Reference ref =
            FirebaseStorage.instance.ref().child('product_images/$fileName');
        UploadTask uploadTask = ref.putData(
            _selectedImages[i]!, SettableMetadata(contentType: 'image/jpeg'));
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
        print(downloadUrl);
      }
    }
    return imageUrls;
  }

  Future<void> _addProductToFirebase(WidgetRef ref) async {
    ref.read(loadingProvider.notifier).state = true;

    // Fetch the latest state explicitly
    final micronutrients =
        ref.read(microNutrientsProvider); // Ensure this is fresh
    final ingredients = ref.read(ingredientsProvider);

    print("Micronutrients in productData before saving: $micronutrients");
    print("Ingredients in productData before saving: $ingredients");

    // Validate inputs
    if (micronutrients.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please add at least one micronutrient",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    List<String> imageUrls = await _uploadImages();

    final productData = {
      "Product Code": _productCodeController.text,
      "Vendor Name": _vendorNameController.text,
      "Brand Name": _brandNameController.text,
      "Product Name": _productNameController.text,
      "Category": _categoryController.text,
      "Sub-Category": _subCategoryController.text,
      "Net Quantity": _netQuantityController.text,
      "Ingredients": ingredients, // Read from the updated provider state
      "Energy (kcal)": double.tryParse(_energyController.text) ?? 0.0,
      "Protein (g)": double.tryParse(_proteinController.text) ?? 0.0,
      "Total Carbohydrates (g)":
          double.tryParse(_carbohydratesController.text) ?? 0.0,
      "Sugars (g)": double.tryParse(_sugarsController.text) ?? 0.0,
      "Added Sugars (g)": double.tryParse(_addedSugarsController.text) ?? 0.0,
      "Dietary Fiber (g)": double.tryParse(_dietaryFiberController.text) ?? 0.0,
      "Total Fat (g)": double.tryParse(_totalFatController.text) ?? 0.0,
      "Trans Fat (g)": double.tryParse(_transFatController.text) ?? 0.0,
      "Saturated Fat (g)": double.tryParse(_saturatedFatController.text) ?? 0.0,
      "Unsaturated Fat (g)":
          double.tryParse(_unsaturatedFatController.text) ?? 0.0,
      "Cholesterol (mg)": double.tryParse(_cholesterolController.text) ?? 0.0,
      "Micronutrients": micronutrients, // Read from the updated provider state
      "Organic": ref.read(_organicProvider),
      "Additives/Preservatives": ref.read(_additivesProvider),
      "Artificial Sweeteners/Colors": ref.read(_artificialSweetenersProvider),
      "Gluten-free": ref.read(_glutenFreeProvider),
      "Vegan-Friendly": ref.read(_veganFriendlyProvider),
      "Keto Friendly": ref.read(_ketoFriendlyProvider),
      "Low GI": ref.read(_lowGIProvider),
      "Low Sugar (less than 5g per serving)": ref.read(_lowSugarProvider),
      "Eco-Friendly": ref.read(_ecoFriendlyProvider),
      "Recyclable Packaging": ref.read(_recyclablePackagingProvider),
      "What is it?": _whatIsItController.text,
      "What is it used for?": _whatIsItUsedForController.text,
      "ImageUrls": imageUrls,
      "timestamp": FieldValue.serverTimestamp(),
      "Kealthy Score":double.tryParse(_kealthyscoreController.text) ?? 0.0,
      "HSN":double.tryParse(_hsnController.text) ?? 0.0,
      "Price": double.tryParse(_priceController.text) ?? 0.0,
    };

    print("Final Product Data: $productData");

    // Save to Firestore
    try {
      await FirebaseFirestore.instance.collection('Products').add(productData);
      ref.read(loadingProvider.notifier).state = false;

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
      print("Error saving product: $e");
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
    _whatIsItController.clear();
    _whatIsItUsedForController.clear();
    _kealthyscoreController.clear();
    _hsnController.clear();
    _priceController.clear();

    // Reset lists and images
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    ref.read(microNutrientsProvider.notifier).state = [];
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    ref.read(ingredientsProvider.notifier).state = [];
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

  // Validate string fields are not empty
  if (_productCodeController.text.isEmpty) {
    _showToast("Please enter the Product Code");
    return false;
  }
  if (_vendorNameController.text.isEmpty) {
    _showToast("Please enter the Vendor Name");
    return false;
  }
  if (_brandNameController.text.isEmpty) {
    _showToast("Please enter the Brand Name");
    return false;
  }
  if (_productNameController.text.isEmpty) {
    _showToast("Please enter the Product Name");
    return false;
  }
  if (_categoryController.text.isEmpty) {
    _showToast("Please enter the Category");
    return false;
  }
  if (_subCategoryController.text.isEmpty) {
    _showToast("Please enter the Sub-Category");
    return false;
  }
  if (_netQuantityController.text.isEmpty) {
    _showToast("Please enter the Net Quantity");
    return false;
  }

  // Validate numeric fields are not empty and contain valid numbers
  if (_energyController.text.isEmpty) {
    _showToast("Please enter the Energy value");
    return false;
  } else if (double.tryParse(_energyController.text) == null) {
    _showToast("Please enter a numeric value for the Energy field");
    return false;
  }

  if (_proteinController.text.isEmpty) {
    _showToast("Please enter the Protein value");
    return false;
  } else if (double.tryParse(_proteinController.text) == null) {
    _showToast("Please enter a numeric value for the Protein field");
    return false;
  }

  if (_carbohydratesController.text.isEmpty) {
    _showToast("Please enter the Carbohydrates value");
    return false;
  } else if (double.tryParse(_carbohydratesController.text) == null) {
    _showToast("Please enter a numeric value for the Carbohydrates field");
    return false;
  }

  if (_sugarsController.text.isEmpty) {
    _showToast("Please enter the Sugars value");
    return false;
  } else if (double.tryParse(_sugarsController.text) == null) {
    _showToast("Please enter a numeric value for the Sugars field");
    return false;
  }

  if (_addedSugarsController.text.isEmpty) {
    _showToast("Please enter the Added Sugars value");
    return false;
  } else if (double.tryParse(_addedSugarsController.text) == null) {
    _showToast("Please enter a numeric value for the Added Sugars field");
    return false;
  }

  if (_dietaryFiberController.text.isEmpty) {
    _showToast("Please enter the Dietary Fiber value");
    return false;
  } else if (double.tryParse(_dietaryFiberController.text) == null) {
    _showToast("Please enter a numeric value for the Dietary Fiber field");
    return false;
  }

  if (_totalFatController.text.isEmpty) {
    _showToast("Please enter the Total Fat value");
    return false;
  } else if (double.tryParse(_totalFatController.text) == null) {
    _showToast("Please enter a numeric value for the Total Fat field");
    return false;
  }

  if (_transFatController.text.isEmpty) {
    _showToast("Please enter the Trans Fat value");
    return false;
  } else if (double.tryParse(_transFatController.text) == null) {
    _showToast("Please enter a numeric value for the Trans Fat field");
    return false;
  }

  if (_saturatedFatController.text.isEmpty) {
    _showToast("Please enter the Saturated Fat value");
    return false;
  } else if (double.tryParse(_saturatedFatController.text) == null) {
    _showToast("Please enter a numeric value for the Saturated Fat field");
    return false;
  }

  if (_unsaturatedFatController.text.isEmpty) {
    _showToast("Please enter the Unsaturated Fat value");
    return false;
  } else if (double.tryParse(_unsaturatedFatController.text) == null) {
    _showToast("Please enter a numeric value for the Unsaturated Fat field");
    return false;
  }

  if (_cholesterolController.text.isEmpty) {
    _showToast("Please enter the Cholesterol value");
    return false;
  } else if (double.tryParse(_cholesterolController.text) == null) {
    _showToast("Please enter a numeric value for the Cholesterol field");
    return false;
  }

  // For Kealthy Score, HSN, Price (also numeric fields)
  if (_kealthyscoreController.text.isNotEmpty &&
      double.tryParse(_kealthyscoreController.text) == null) {
    _showToast("Please enter a numeric value for the Kealthy Score field");
    return false;
  }

  if (_hsnController.text.isNotEmpty &&
      double.tryParse(_hsnController.text) == null) {
    _showToast("Please enter a numeric value for the HSN field");
    return false;
  }

  if (_priceController.text.isNotEmpty &&
      double.tryParse(_priceController.text) == null) {
    _showToast("Please enter a numeric value for the Price field");
    return false;
  }

  // Check if micronutrients array is empty
  if (ref.read(microNutrientsProvider).isEmpty) {
    _showToast("Please add at least one Micronutrient");
    return false;
  }

  // Check if ingredients array is empty
  if (ref.read(ingredientsProvider).isEmpty) {
    _showToast("Please add at least one Ingredient");
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
    final isLoading = ref.watch(loadingProvider);

    // Watch the dropdown state
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
                          'Description',
                          'Ingredients'
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
                        CustomTextFieldWithTitle(
                          title: 'Category',
                          hint: 'Enter Product Category',
                          controller: _categoryController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Sub-Category',
                          hint: 'Enter Product Sub-Category',
                          controller: _subCategoryController,
                        ),
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
                          title: 'Kealthy Score',
                          hint: 'Enter Score',
                          controller: _kealthyscoreController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'HSN',
                          hint: 'Enter Value',
                          controller: _hsnController,
                        ),
                        CustomTextFieldWithTitle(
                          title: 'Price',
                          hint: 'Enter the Price',
                          controller: _priceController,
                        ),

                        // Dropdowns for Boolean Fields
                        CustomDropdownWithTitle(
                          title: 'Is this product organic?',
                          provider: _organicProvider, options: const ['Fully Organic', 'Partially Organic', 'Non-Organic'],
                        ),
                        CustomDropdownWithTitle(
                          title: 'Does it contain additives?',
                          provider: _additivesProvider, 
                          options: const ['No additives/Preservatives','Minimal natural Additives/Preservatives','Artifical Additives/Preservatives'],
                        ),
                        CustomDropdownWithTitle(
                          title:
                              'Does it contain artificial sweeteners or colors?',
                          provider: _artificialSweetenersProvider, 
                          options: const ['None','Limited','Present'],
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
                          options: const ['Sustainable/Ethical Sourcing','Partially Sustainable','Not Sustainable'],
                        ),
                        CustomDropdownWithTitle(
                          title: 'Does it use recyclable packaging?',
                          provider: _recyclablePackagingProvider, 
                          options: const ['Fully Recyclable','Partially Recyclable','Non-Recyclable'],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 5),
                          child: ArrayInputWithTitle(
                            title: 'Micronutrients',
                            hintText: 'Calcium, Potassium, Magnesium...',
                            provider: microNutrientsProvider,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 5),
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
                        onPressed: isLoading
                            ? null // Disable the button when loading
                            : () {
                                if (_validateFields()) {
                                  _addProductToFirebase(ref);
                                }
                              },
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Save',
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
