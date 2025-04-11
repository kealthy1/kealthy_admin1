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
    final sheetName = excel.tables.keys.first; // Automatically select first sheet
    final sheet = excel.tables[sheetName];

    if (sheet != null) {
      List<Map<String, dynamic>> productDataList = [];
      List<String> headers = [];

      // Extract headers (first row)
      for (var cell in sheet.rows.first) {
        headers.add(cell?.value?.toString().trim() ?? 'UnknownColumn');
      }

      // Iterate through rows, starting after the header row
      for (int rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
        final row = sheet.rows[rowIndex];

        // Skip empty rows
        if (row.every((cell) => cell?.value == null)) continue;

        Map<String, dynamic> productData = {};

        for (int colIndex = 0; colIndex < headers.length; colIndex++) {
          String columnName = headers[colIndex];
          var cellValue = row[colIndex]?.value?.toString().trim();

          // Convert SOH (Stock on Hand) to a number
          if (columnName.toLowerCase() == "soh") {
            productData[columnName] = double.tryParse(cellValue ?? "0") ?? 0.0;
          }
          // Convert FSSAI, Ingredients, and Scored Based On fields to arrays
          else if (columnName.toLowerCase().contains("fssai") ||
                   columnName.toLowerCase().contains("ingredients") ||
                   columnName.toLowerCase().contains("scored  based on")) {
            productData[columnName] = cellValue != null
                ? cellValue.split(',').map((e) => e.trim()).toList()
                : [];
          } 
          // Convert Image URL field to a List
          else if (columnName.toLowerCase().contains("imageurl") && cellValue != null) {
            productData[columnName] = cellValue.split(',').map((e) => e.trim()).toList();
          }
          // Convert numeric fields properly
          else if (columnName.toLowerCase().contains("price") || columnName.toLowerCase().contains("kealthy score")) {
            productData[columnName] = double.tryParse(cellValue ?? "0") ?? 0.0;
          } 
          // Store dates properly
          else if (columnName.toLowerCase().contains("date") || columnName.toLowerCase().contains("expiry")) {
            productData[columnName] = cellValue; // Further parsing can be applied if needed
          } 
          // Store other values as strings
          else {
            productData[columnName] = cellValue;
          }
        }

        productDataList.add(productData);
      }

      // Upload data to Firestore in a batch
      final batch = FirebaseFirestore.instance.batch();
      final productCollection = FirebaseFirestore.instance.collection('Products');

      for (var product in productDataList) {
        final productCode = product["Product code"];
        if (productCode != null && productCode.isNotEmpty) {
          final docRef = productCollection.doc(productCode); // Use Product Code as doc ID
          batch.set(docRef, product, SetOptions(merge: true)); // Merge to update existing data
        }
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
                        ref.read(selectedExcelFileProvider.notifier).state = null; // Clear selected file
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
