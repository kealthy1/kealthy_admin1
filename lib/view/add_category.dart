// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image/image.dart' as img;
// import 'package:image_picker/image_picker.dart';
// import 'package:path/path.dart' as path;

// final categoryImageProvider = StateProvider<File?>((ref) => null);
// final subcategoryImageProvider = StateProvider<File?>((ref) => null);
// final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// class CategorySubcategoryPage extends ConsumerWidget {
//   const CategorySubcategoryPage({super.key});

//   // 📦 Compress image before upload
//   Future<Uint8List> _compressImage(File file, {int maxSizeKB = 200}) async {
//     final bytes = await file.readAsBytes();
//     img.Image? image = img.decodeImage(bytes);
//     if (image == null) return bytes;

//     int quality = 90;
//     Uint8List compressed;
//     do {
//       compressed = Uint8List.fromList(img.encodeJpg(image, quality: quality));
//       quality -= 10;
//     } while (compressed.lengthInBytes > maxSizeKB * 1024 && quality > 10);
//     return compressed;
//   }

//   // 📤 Upload to Firebase Storage
//   Future<String> _uploadImage(File imageFile, String folder) async {
//     final compressedBytes = await _compressImage(imageFile);
//     final fileName =
//         'image_${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
//     final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');

//     final uploadTask = ref.putData(
//         compressedBytes, SettableMetadata(contentType: 'image/jpeg'));
//     final snapshot = await uploadTask;
//     return await snapshot.ref.getDownloadURL();
//   }

//   // 📂 Pick image using ImagePicker
//   Future<void> _pickImage(WidgetRef ref, bool isCategory) async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? pickedImage =
//         await picker.pickImage(source: ImageSource.gallery);
//     if (pickedImage != null) {
//       final file = File(pickedImage.path);
//       if (isCategory) {
//         ref.read(categoryImageProvider.notifier).state = file;
//       } else {
//         ref.read(subcategoryImageProvider.notifier).state = file;
//       }
//     }
//   }

//   // ✅ Add Category
//   Future<void> _addCategory(BuildContext context, WidgetRef ref,
//       TextEditingController nameController) async {
//     final image = ref.read(categoryImageProvider);
//     if (nameController.text.isNotEmpty && image != null) {
//       final url = await _uploadImage(image, 'CategoryImages');
//       await FirebaseFirestore.instance.collection('categories').add({
//         'Categories': nameController.text.trim(),
//         'imageurl': url,
//       });
//       ref.invalidate(categoryImageProvider);
//       nameController.clear();
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('Category added')));
//     }
//   }

//   // ✅ Add Subcategory
//   Future<void> _addSubcategory(
//       BuildContext context,
//       WidgetRef ref,
//       TextEditingController nameController,
//       TextEditingController titleController) async {
//     final selectedCategory = ref.read(selectedCategoryProvider);
//     final image = ref.read(subcategoryImageProvider);

//     if (selectedCategory != null &&
//         nameController.text.isNotEmpty &&
//         titleController.text.isNotEmpty &&
//         image != null) {
//       final url = await _uploadImage(image, 'SubCategoryImages');
//       await FirebaseFirestore.instance.collection('SubCategory').add({
//         'Category': selectedCategory,
//         'Subcategory': nameController.text.trim(),
//         'ImageUrl': url,
//         'Title': titleController.text.trim(),
//       });
//       ref.invalidate(subcategoryImageProvider);
//       nameController.clear();
//       titleController.clear();
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('Subcategory added')));
//     }
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final categoryImage = ref.watch(categoryImageProvider);
//     final subcategoryImage = ref.watch(subcategoryImageProvider);
//     final selectedCategory = ref.watch(selectedCategoryProvider);
//     final screenWidth = MediaQuery.of(context).size.width;

//     final categoryNameController = TextEditingController();
//     final subcategoryNameController = TextEditingController();
//     final subcategoryTitleController = TextEditingController();

//     return Scaffold(
//       appBar: AppBar(title: const Text('Add Categories & Subcategories')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView(
//           children: [
//             const Text("Create Category",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             TextField(
//                 controller: categoryNameController,
//                 decoration: const InputDecoration(labelText: 'Category Name')),
//             const SizedBox(height: 10),
//             const Text("Category Image",
//                 style: TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
// // Center(
// //   child: GestureDetector(
// //     onTap: () => _pickImage(ref, true),
// //     child: Container(
// //       height: 180,
// //       width: 180,
// //       decoration: BoxDecoration(
// //         color: Colors.grey[300],
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: Colors.grey),
// //       ),
// //       child: categoryImage != null
// //           ? ClipRRect(
// //               borderRadius: BorderRadius.circular(12),
// //               child: Image.file(
// //                 categoryImage,
// //                 fit: BoxFit.cover,
// //               ),
// //             )
// //           : const Center(child: Icon(Icons.camera_alt, size: 40, color: Colors.black54)),
// //     ),
// //   ),
// // ),

//             Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 8),
//                 GestureDetector(
//                   onTap: () => _pickImage(ref, true),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     height: screenWidth * 0.2, // Container height
//                     width: screenWidth * 0.23, // Adjust width
//                     child: categoryImage != null
//                         ? Image.memory(
//                             categoryImage as Uint8List,
//                             fit: BoxFit.cover,
//                           )
//                         : const Center(
//                             child: Icon(Icons.add_a_photo),
//                           ),
//                   ),
//                 ),
//               ],
//             ),
//             ElevatedButton(
//               onPressed: () =>
//                   _addCategory(context, ref, categoryNameController),
//               child: const Text('Add Category'),
//             ),
//             const Divider(height: 40),
//             const Text("Create Subcategory",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('categories')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) return const CircularProgressIndicator();
//                 final categories = snapshot.data!.docs;
//                 return DropdownButton<String>(
//                   hint: const Text('Select Category'),
//                   value: selectedCategory,
//                   onChanged: (value) =>
//                       ref.read(selectedCategoryProvider.notifier).state = value,
//                   items: categories.map<DropdownMenuItem<String>>((doc) {
//                     final String categoryName = doc['Categories'];
//                     return DropdownMenuItem<String>(
//                       value: categoryName,
//                       child: Text(categoryName),
//                     );
//                   }).toList(),
//                 );
//               },
//             ),
//             Flexible(
//               child: TextField(
//                   controller: subcategoryNameController,
//                   decoration:
//                       const InputDecoration(labelText: 'Subcategory Name')),
//             ),
//             Flexible(
//               child: TextField(
//                   controller: subcategoryTitleController,
//                   decoration: const InputDecoration(labelText: 'Title')),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton.icon(
//               onPressed: () => _pickImage(ref, false),
//               icon: const Icon(Icons.image),
//               label: const Text('Select Subcategory Image'),
//             ),
//             if (subcategoryImage != null)
//               Image.file(subcategoryImage, height: 100),
//             ElevatedButton(
//               onPressed: () => _addSubcategory(context, ref,
//                   subcategoryNameController, subcategoryTitleController),
//               child: const Text('Add Subcategory'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
