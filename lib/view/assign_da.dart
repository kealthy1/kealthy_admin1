import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Tracks the currently selected delivery user in the dropdown.
final selectedUserProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

/// Notifier to fetch and manage all orders from Realtime Database.
class OrdersNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  OrdersNotifier() : super([]) {
    _listenForOrderChanges();
  }

  StreamSubscription<DatabaseEvent>? _ordersSubscription;
  
  // Create an AudioPlayer instance (from audioplayers)
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Continuously listens for changes under the "orders" node in Realtime DB.
  void _listenForOrderChanges() {
    final databaseReference = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: "https://kealthy-90c55-dd236.firebaseio.com/",
    ).ref("orders");

    _ordersSubscription = databaseReference.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) {
        state = [];
        return;
      }

      // Convert the Realtime DB map into a new list
      final newList = data.entries.map((entry) {
        return {
          'orderId': entry.key,
          ...Map<String, dynamic>.from(entry.value),
        };
      }).toList();

      // Compare new list length with old (state.length)
      final oldCount = state.length; 
      state = newList;

      // If new list length is greater, at least one new order arrived
      if (newList.length > oldCount) {
        _playAlertSound();
      }
    });
  }

  /// Play a short alert sound from assets/sounds/new_order.mp3
  Future<void> _playAlertSound() async {
    try {
     await _audioPlayer.play(
  AssetSource('sounds/AUDIO-2025-02-04-16-41-56.mp3'),
);
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  @override
  void dispose() {
    // Cancel subscription when notifier is disposed
    _ordersSubscription?.cancel();
    super.dispose();
  }

  /// One-time fetch of the orders (triggered by floatingActionButton or on init).
  Future<void> fetchOrders() async {
    final databaseReference = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: "https://kealthy-90c55-dd236.firebaseio.com/",
    ).ref("orders");

    final event = await databaseReference.once();
    final data = event.snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      state = data.entries.map((entry) {
        return {
          'orderId': entry.key,
          ...Map<String, dynamic>.from(entry.value),
        };
      }).toList();
    } else {
      state = [];
    }
  }

  /// Assigns a Delivery Agent to a particular order in Realtime Database.
  Future<void> assignDeliveryAgent(
    String orderId,
    Map<String, dynamic> agent,
  ) async {
    final databaseReference = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: "https://kealthy-90c55-dd236.firebaseio.com/",
    ).ref("orders/$orderId");

    await databaseReference.update({
      'assignedto': agent['ID'],
      'DA': agent['Name'],
      'DAMOBILE': agent['Mobile'],
    });
  }
}

/// Notifier to fetch and manage the list of delivery users from Firestore.
class DeliveryUsersNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  DeliveryUsersNotifier() : super([]);

  Future<void> fetchDeliveryUsers() async {
    final deliveryUsersCollection =
        FirebaseFirestore.instance.collection('DeliveryUsers');

    final snapshot = await deliveryUsersCollection.get();
    state = snapshot.docs.map((doc) {
      return {
        'ID': doc.id,
        ...doc.data(),
      };
    }).toList();
  }
}

// Riverpod providers for Orders and DeliveryUsers
final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<Map<String, dynamic>>>(
        (ref) => OrdersNotifier());

final deliveryUsersProvider =
    StateNotifierProvider<DeliveryUsersNotifier, List<Map<String, dynamic>>>(
        (ref) => DeliveryUsersNotifier());

/// Main widget for assigning delivery agents to orders.
class AssignDa extends ConsumerStatefulWidget {
  const AssignDa({super.key});

  @override
  _AssignDaState createState() => _AssignDaState();
}

class _AssignDaState extends ConsumerState<AssignDa> {
  @override
  void initState() {
    super.initState();
    // Fetch orders and delivery users once the widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).fetchOrders();
      ref.read(deliveryUsersProvider.notifier).fetchDeliveryUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          "Assign DA",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: orders.map((order) {
                  return Container(
                    width: 360,
                    // No fixed height, let the container adapt to content
                    margin: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 5,
                          spreadRadius: 2,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Basic order info + Assign button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Order ID: ${order['orderId']}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "Status: ${order['status'] ?? 'N/A'}",
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: (order['status'] == 'Order Picked')
                                  ? null // Disabled if Order is already picked
                                  : () {
                                      _showAssignDADialog(
                                        context,
                                        ref,
                                        order['orderId'],
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    (order['status'] == 'Order Picked')
                                        ? Colors.grey
                                        : Colors.blue.shade900,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: const Text(
                                "Assign DA",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),

                        // Table layout for better alignment (dynamic height)
                        SingleChildScrollView(
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(2), // Label column
                              1: FlexColumnWidth(3), // Value column
                            },
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.top,
                            children: [
                              _buildTableRow("Name", order['Name']),
                              _buildTableRow("Phone", order['phoneNumber']),
                              _buildTableRow("Distance", order['distance']),
                              _buildTableRow("Delivery Fee",
                                  order['deliveryFee']?.toString()),
                              _buildTableRow("DA", order['DA']),
                              _buildTableRow("DAMobile", order['DAMOBILE']),
                              _buildTableRow("AssignedTo", order['assignedto']),
                              _buildTableRow("Cooking Instructions",
                                  order['cookinginstrcutions']),
                              _buildTableRow("Payment Method",
                                  order['paymentmethod']),
                              _buildTableRow(
                                  "SelectedRoad", order['selectedRoad']),
                              _buildTableRow(
                                  "SelectedType", order['selectedType']),
                              _buildTableRow(
                                  "SelectedSlot", order['selectedSlot']),

                              // Show order items in a single row
                              TableRow(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      "Order Items:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child:
                                        _buildOrderItems(order['orderItems']),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          // Refresh orders and users
          ref.read(ordersProvider.notifier).fetchOrders();
          ref.read(deliveryUsersProvider.notifier).fetchDeliveryUsers();
        },
        child: const Icon(Icons.refresh, color: Colors.blue),
      ),
    );
  }

  /// Creates a single table row with label & value.
  TableRow _buildTableRow(String label, dynamic value) {
    const textStyleLabel = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    const textStyleValue = TextStyle(fontSize: 12);
    final displayValue = value?.toString() ?? "N/A";

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0, right: 4.0),
          child: Text(label, style: textStyleLabel),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(displayValue, style: textStyleValue),
        ),
      ],
    );
  }

  /// Dialog to assign a Delivery Agent to the order
  void _showAssignDADialog(
    BuildContext context,
    WidgetRef ref,
    String orderId,
  ) {
    // Clear any previously selected user
    ref.read(selectedUserProvider.notifier).state = null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (consumerContext, consumerRef, _) {
            final deliveryUsers = consumerRef.watch(deliveryUsersProvider);
            final selectedUser = consumerRef.watch(selectedUserProvider);

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: const Text("Assign Delivery Agent"),
              content: deliveryUsers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 5.0,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.white,
                          ),
                          child: DropdownButton<Map<String, dynamic>>(
                            dropdownColor: Colors.white,
                            isExpanded: true,
                            underline: const SizedBox(),
                            hint: const Text(
                              "Select Delivery Agent",
                              style: TextStyle(color: Colors.black),
                            ),
                            value: selectedUser,
                            items: deliveryUsers.map((user) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: user,
                                child: Text(
                                  "${user['Name']} (${user['ID']})",
                                  style: const TextStyle(color: Colors.black),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              consumerRef
                                  .read(selectedUserProvider.notifier)
                                  .state = value;
                            },
                          ),
                        ),
                      ],
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedUser != null) {
                      // Assign DA in Firebase
                      consumerRef
                          .read(ordersProvider.notifier)
                          .assignDeliveryAgent(orderId, selectedUser)
                          .then((_) async {
                        // Close the 'Assign DA' dialog
                        Navigator.pop(dialogContext);

                        // Refresh orders
                        consumerRef.read(ordersProvider.notifier).fetchOrders();

                        // Show toast
                        Fluttertoast.showToast(
                          msg: "DA Assigned successfully!",
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                        );
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error: $error"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select a delivery agent."),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Assign",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Helper widget to display order items (whether it's a Map or a List)
  /// and show "Total Price" below them.
  Widget _buildOrderItems(dynamic orderItems) {
    double totalPrice = 0.0;

    // Collect widgets in a List so we can
    // add "Total Price" at the end.
    final List<Widget> itemWidgets = [];

    if (orderItems is Map) {
      // Convert map values to a list for iteration
      final itemsList = orderItems.values.toList();
      for (var item in itemsList) {
        if (item is Map) {
          final itemName = item['item_name'] ?? 'Unknown Item';
          final rawQty = item['item_quantity'] ?? 1; // could be int or string
          final rawPrice = item['item_price'] ?? '0';

          // Convert to double
          final qty = double.tryParse(rawQty.toString()) ?? 1;
          final price = double.tryParse(rawPrice.toString()) ?? 0.0;
          totalPrice += (qty * price);

          itemWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text("$itemName x${qty.toStringAsFixed(0)} — ₹ $price"),
            ),
          );
        } else {
          itemWidgets.add(Text("- $item"));
        }
      }
    } else if (orderItems is List) {
      // If it's already a List, iterate
      for (var item in orderItems) {
        if (item is Map) {
          final itemName = item['item_name'] ?? 'Unknown Item';
          final rawQty = item['item_quantity'] ?? 1;
          final rawPrice = item['item_price'] ?? '0';

          final qty = double.tryParse(rawQty.toString()) ?? 1;
          final price = double.tryParse(rawPrice.toString()) ?? 0.0;
          totalPrice += (qty * price);

          itemWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text("$itemName x${qty.toStringAsFixed(0)} — ₹$price"),
            ),
          );
        } else {
          itemWidgets.add(Text("- $item"));
        }
      }
    } else {
      // If it's neither a Map nor a List, just display as text
      return Text("Order Items: $orderItems");
    }

    // After listing items, add the Total Price line
    itemWidgets.add(const SizedBox(height: 6));
    itemWidgets.add(
      Text(
        "Total Price: ₹ $totalPrice",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: itemWidgets,
    );
  }
}