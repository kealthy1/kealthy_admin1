import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UpdateAllProductsPage extends StatefulWidget {
  const UpdateAllProductsPage({super.key});

  @override
  State<UpdateAllProductsPage> createState() => _UpdateAllProductsPageState();
}

class _UpdateAllProductsPageState extends State<UpdateAllProductsPage> {
  bool isUpdating = false;
  String updateStatus = 'Idle';

  // This method fetches all documents in the "Products" collection and updates
  // the field "Origin" (or "Orgin" if needed) to "India"
  Future<void> updateOriginField() async {
    setState(() {
      isUpdating = true;
      updateStatus = 'Updating...';
    });

    final firestore = FirebaseFirestore.instance;

    try {
      // Get all documents in the Products collection
      final querySnapshot = await firestore.collection('Products').get();

      // Each batch can handle up to 500 operations.
      // If you have more than 500 documents, you need to split into multiple batches.
      // For simplicity, here's a single-batch example.
      final batch = firestore.batch();

      for (var doc in querySnapshot.docs) {
        final docRef = firestore.collection('Products').doc(doc.id);
        batch.update(docRef, {
          'Orgin': 'India', // Use 'Orgin': 'India' if your field is actually spelled that way
        });
      }

      await batch.commit();

      setState(() {
        updateStatus = 'Update complete!';
      });
    } catch (e) {
      setState(() {
        updateStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Products'),
      ),
      body: Center(
        child: isUpdating 
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(updateStatus),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: updateOriginField,
                    child: const Text('Update All Products'),
                  ),
                ],
              ),
      ),
    );
  }
}