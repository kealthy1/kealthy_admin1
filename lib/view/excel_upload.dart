import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';

final selectedExcelFileProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

final isUploadingProvider = StateProvider<bool>((ref) => false);

class ExcelUploader extends ConsumerWidget {
  const ExcelUploader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedExcelFile = ref.watch(selectedExcelFileProvider);
    final isUploading = ref.watch(isUploadingProvider);

    Future<void> selectExcelFile() async {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx'], // Restrict to Excel files
        );

        if (result != null && result.files.single.bytes != null) {
          ref.read(selectedExcelFileProvider.notifier).state = {
            'fileName': result.files.single.name,
            'fileBytes': Uint8List.fromList(result.files.single.bytes!),
          };
          Fluttertoast.showToast(
            msg:
                "Excel file '${result.files.single.name}' selected successfully!",
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        } else {
          Fluttertoast.showToast(
            msg: "No file selected.",
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } catch (e) {
        print("Error selecting Excel file: $e");
        Fluttertoast.showToast(
          msg: "Error selecting file.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }

    Future<void> uploadExcelFile(BuildContext ctx, Uint8List excelFile) async {
  ref.read(isUploadingProvider.notifier).state = true;
  

  try {
    // Decode the Excel file
    final excel = Excel.decodeBytes(excelFile);

    // Select the correct sheet (update the sheet name if required)
    const sheetName = 'Kealthy Products'; // Replace with your actual sheet name
    final sheet = excel.tables[sheetName];

    if (sheet != null) {
      List<Map<String, dynamic>> productDataList = [];

      // Helper functions for parsing
      String? parseString(dynamic cell) => cell?.value?.toString().trim();
      List<String> parseList(dynamic cell) =>
          (cell?.value?.toString().split(',') ?? [])
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      // Iterate through rows, starting after the header row
      for (int rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
        final row = sheet.rows[rowIndex];

        // Debugging: Print each row's content
        debugPrint('Row $rowIndex: ${row.map((cell) => cell?.value).toList()}');
        debugPrint('Sheet Data: ${sheet.rows.map((row) => row.map((cell) => cell?.value).toList())}');

        // Skip completely empty rows
        if (row.every((cell) => cell?.value == null)) continue;

        // Build product data
        productDataList.add({
          "Product code": parseString(row[0]),
          "Vendor Name": parseString(row[1]),
          "Brand Name": parseString(row[2]),
          "Name": parseString(row[3]),
          "Category": parseString(row[4]),
          "Subcategory": parseString(row[5]),
          "ImageUrl": parseList(row[6]),
          "Qty": parseString(row[7]),
          "Energy (kcal)": parseString(row[8]),
          "Protein (g)": parseString(row[9]),
          "Total Carbohydrates (g)": parseString(row[10]),
          "Sugars (g)": parseString(row[11]),
          "Added Sugars (g)": parseString(row[12]),
          "Dietary Fiber (g)": parseString(row[13]),
          "Total Fat (g)": parseString(row[14]),
          "Trans Fat (g)": parseString(row[15]),
          "Saturated Fat (g)": parseString(row[16]),
          "Unsaturated Fat (g)": parseString(row[17]),
          "Cholesterol (mg)": parseString(row[18]),
          "Micronutrients": parseList(row[19]),
          "Ingredients": parseList(row[20]),
          "Organic": parseString(row[21]),
          "Additives/Preservatives": parseString(row[22]),
          "Artificial Sweeteners?Colors": parseString(row[23]),
          "Gluten-free": parseString(row[24]),
          "Vegan-Friendly": parseString(row[25]),
          "Keto Friendly": parseString(row[26]),
          "Low GI": parseString(row[27]),
          "Low Sugar (less than 5g per serving)": parseString(row[28]),
          "Eco-Friendly": parseString(row[29]),
          "Recyclable Packaging": parseString(row[30]),
          "What is it?": parseString(row[31]),
          "What is it used for?": parseString(row[32]),
          "Kealthy Score":parseString(row[33]),
          "HSN" : parseString(row[34]),
          "Price":parseString(row[35])
        });
      }

      // Upload data to Firestore in a batch
      final batch = FirebaseFirestore.instance.batch();
      for (var product in productDataList) {
        final docRef = FirebaseFirestore.instance.collection('Products').doc();
        batch.set(docRef, product);
      }
      await batch.commit();

      // Success toast
      Fluttertoast.showToast(
        msg: "Excel data uploaded successfully!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Show a success animation dialog
      if (ctx.mounted) {
        showDialog(
          context: ctx,
          builder: (dialogContext) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'lib/assets/animations/Animation - 1731992471934.json', // Update path
                      width: 100,
                      height: 100,
                      repeat: false,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Upload Complete!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        ref.read(selectedExcelFileProvider.notifier).state =
                            null; // Clear selected file
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: "No valid sheet found in the Excel file.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  } catch (e) {
    debugPrint("Error uploading Excel: $e");
    Fluttertoast.showToast(
      msg: "Error uploading Excel. Check the console for details.",
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  } finally {
    ref.read(isUploadingProvider.notifier).state = false;
  }
}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
               onPressed: isUploading
                  ? null // Disable the button if already uploading
                  : selectExcelFile,
              label: const Text(
                "Select Excel File",
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(
                Icons.select_all_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (selectedExcelFile != null) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              "Selected File: ${selectedExcelFile['fileName']}",
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: isUploading
                    ? null // Disable if already uploading
                    : () {
                      
                        final bytes = selectedExcelFile['fileBytes'];
                        if (bytes != null) {
                          uploadExcelFile(context, bytes);
                        } else {
                          Fluttertoast.showToast(
                            msg: "Please select a valid Excel file first.",
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                          );
                        }
                      },
                label: isUploading
                    ? const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text(
                        "Upload Excel Data",
                        style: TextStyle(color: Colors.white),
                      ),
                icon: isUploading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.file_upload, color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
