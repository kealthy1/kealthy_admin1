import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ManualOrderEntryPage extends StatefulWidget {
  const ManualOrderEntryPage({super.key});

  @override
  State<ManualOrderEntryPage> createState() => _ManualOrderEntryPageState();
}

class _ManualOrderEntryPageState extends State<ManualOrderEntryPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController roadController = TextEditingController();
  final TextEditingController deliveryInstructionsController =
      TextEditingController();
  final TextEditingController cookingInstructionsController =
      TextEditingController();
  final TextEditingController slotController = TextEditingController();
  final TextEditingController preferredTimeController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();
  final TextEditingController deliveryFeeController = TextEditingController();

  final TextEditingController distanceController = TextEditingController();
  final TextEditingController fcmTokenController = TextEditingController();
  final TextEditingController selectedDirectionsController =
      TextEditingController();
  final TextEditingController selectedLatitudeController =
      TextEditingController();
  final TextEditingController selectedLongitudeController =
      TextEditingController();
  final TextEditingController orderIdController = TextEditingController();
  final TextEditingController paymentMethodController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  final TextEditingController deviceController = TextEditingController();

  List<Map<String, TextEditingController>> orderItemsControllers = [];

  void addOrderItem() {
    setState(() {
      orderItemsControllers.add({
        'item_name': TextEditingController(),
        'item_price': TextEditingController(),
        'item_quantity': TextEditingController(),
        'item_ean': TextEditingController(),
      });
    });
  }

  void removeOrderItem(int index) {
    setState(() {
      orderItemsControllers.removeAt(index);
    });
  }

  Future<void> submitOrder() async {
    if (_formKey.currentState?.validate() ?? false) {
      final orderId = orderIdController.text.isNotEmpty
          ? orderIdController.text
          : DateTime.now().millisecondsSinceEpoch.toString();
      final orderData = {
        "Name": nameController.text,
        "type": typeController.text,
        "assignedto": "NotAssigned",
        "DA": "Waiting",
        "DAMOBILE": "Waiting",
        "cookinginstrcutions": cookingInstructionsController.text,
        "createdAt": Timestamp.now(),
        "deliveryInstructions": deliveryInstructionsController.text,
        "distance": double.tryParse(distanceController.text) ?? 0.0,
        "landmark": landmarkController.text,
        "orderId": orderId,
        "orderItems": orderItemsControllers.map((item) {
          return {
            "item_name": item['item_name']!.text,
            "item_price": double.tryParse(item['item_price']!.text) ?? 0,
            "item_quantity": int.tryParse(item['item_quantity']!.text) ?? 1,
            "item_ean": item['item_ean']!.text,
          };
        }).toList(),
        "paymentmethod": paymentMethodController.text.isNotEmpty
            ? paymentMethodController.text
            : "COD",
        "fcm_token": fcmTokenController.text,
        "phoneNumber": phoneController.text,
        "selectedDirections": selectedDirectionsController.text,
        "selectedLatitude":
            double.tryParse(selectedLatitudeController.text) ?? 0.0,
        "selectedLongitude":
            double.tryParse(selectedLongitudeController.text) ?? 0.0,
        "selectedRoad": roadController.text,
        "selectedSlot": slotController.text,
        "selectedType": typeController.text,
        "status": statusController.text.isNotEmpty
            ? statusController.text
            : "Order Placed",
        "totalAmountToPay": int.tryParse(totalAmountController.text) ?? 0,
        "deliveryFee": int.tryParse(deliveryFeeController.text) ?? 0,
        "preferredTime": preferredTimeController.text,
        "device":
            deviceController.text.isNotEmpty ? deviceController.text : "iOS",
      };

      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
      );
      await db.ref("orders/$orderId").set(orderData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order saved successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manual Order Entry")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Name",
                    hintText: "Enter customer's name",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: "Phone",
                    hintText: "Enter customer's phone number",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: landmarkController,
                  decoration: InputDecoration(
                    labelText: "Landmark",
                    hintText: "Enter delivery landmark",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: roadController,
                  decoration: InputDecoration(
                    labelText: "Road",
                    hintText: "Enter road name",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: deliveryInstructionsController,
                  decoration: InputDecoration(
                    labelText: "Delivery Instructions",
                    hintText: "Any special delivery instructions",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cookingInstructionsController,
                  decoration: InputDecoration(
                    labelText: "Cooking Instructions",
                    hintText: "Any cooking instructions",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: slotController,
                  decoration: InputDecoration(
                    labelText: "Slot",
                    hintText: "Enter delivery slot",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: preferredTimeController,
                  decoration: InputDecoration(
                    labelText: "Preferred Time",
                    hintText: "Enter preferred delivery time",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: typeController,
                  decoration: InputDecoration(
                    labelText: "Type",
                    hintText: "Enter order type (e.g. Normal)",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: totalAmountController,
                  decoration: InputDecoration(
                    labelText: "Total Amount",
                    hintText: "Enter total amount to pay",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: deliveryFeeController,
                  decoration: InputDecoration(
                    labelText: "Delivery Fee",
                    hintText: "Enter delivery fee",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: distanceController,
                  decoration: InputDecoration(
                    labelText: "Distance",
                    hintText: "Enter distance (km)",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: fcmTokenController,
                  decoration: InputDecoration(
                    labelText: "FCM Token",
                    hintText: "Enter FCM token",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: selectedDirectionsController,
                  decoration: InputDecoration(
                    labelText: "Selected Directions",
                    hintText: "Enter selected direction",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: selectedLatitudeController,
                  decoration: InputDecoration(
                    labelText: "Latitude",
                    hintText: "Enter latitude",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: selectedLongitudeController,
                  decoration: InputDecoration(
                    labelText: "Longitude",
                    hintText: "Enter longitude",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: orderIdController,
                  decoration: InputDecoration(
                    labelText: "Order ID (optional)",
                    hintText: "Enter custom order ID or leave blank",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: paymentMethodController,
                  decoration: InputDecoration(
                    labelText: "Payment Method",
                    hintText: "Enter payment method (e.g. COD, Online)",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: statusController,
                  decoration: InputDecoration(
                    labelText: "Status",
                    hintText: "Enter order status",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: deviceController,
                  decoration: InputDecoration(
                    labelText: "Device",
                    hintText: "Enter device type (iOS/Android)",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Order Items",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...List.generate(orderItemsControllers.length, (index) {
                  final item = orderItemsControllers[index];
                  return Column(
                    children: [
                      TextFormField(
                        controller: item['item_name'],
                        decoration: InputDecoration(
                          labelText: "Item Name",
                          hintText: "Enter item name",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: item['item_price'],
                        decoration: InputDecoration(
                          labelText: "Item Price",
                          hintText: "Enter item price",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: item['item_quantity'],
                        decoration: InputDecoration(
                          labelText: "Item Quantity",
                          hintText: "Enter item quantity",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: item['item_ean'],
                        decoration: InputDecoration(
                          labelText: "Item EAN",
                          hintText: "Enter item EAN",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removeOrderItem(index),
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                }),
                TextButton.icon(
                  onPressed: addOrderItem,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Item"),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: submitOrder,
                    child: const Text("Save Order Details"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
