import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

final selectedUserProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

// StateNotifier for managing orders
class OrdersNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  OrdersNotifier() : super([]) {
    _listenForOrderChanges();
  }

  StreamSubscription<DatabaseEvent>? _ordersSubscription;

  void _listenForOrderChanges() {
    final databaseReference = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: "https://kealthy-90c55-dd236.firebaseio.com/",
    ).ref("orders");

    // Subscribe to changes under "orders"
    _ordersSubscription = databaseReference.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) {
        state = [];
        return;
      }

      // Convert the Realtime DB map into a List<Map<String, dynamic>>
      final newList = data.entries.map((entry) {
        return {
          'orderId': entry.key,
          ...Map<String, dynamic>.from(entry.value),
        };
      }).toList();

      // Update our Riverpod state
      state = newList;
    });
  }

  @override
  void dispose() {
    // Cancel subscription when notifier is disposed
    _ordersSubscription?.cancel();
    super.dispose();
  }

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
    }
  }

  Future<void> assignDeliveryAgent(
      String orderId, Map<String, dynamic> agent) async {
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

// StateNotifier for managing delivery users
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

// Providers
final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<Map<String, dynamic>>>(
        (ref) => OrdersNotifier());

final deliveryUsersProvider =
    StateNotifierProvider<DeliveryUsersNotifier, List<Map<String, dynamic>>>(
        (ref) => DeliveryUsersNotifier());

class AssignDa extends ConsumerStatefulWidget {
  const AssignDa({super.key});

  @override
  _AssignDaState createState() => _AssignDaState();
}

class _AssignDaState extends ConsumerState<AssignDa> {
  @override
  void initState() {
    super.initState();
    // Fetch orders and delivery users when the widget is initialized
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
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
        title: const Text(
          "Assign DA",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: orders.map((order) {
                    return Container(
                      // Fixed width & height per container
                      width: 360,
                      height: 120,
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
                      child: Column(
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
                                // Disable the button if status is "Order Picked"
                                onPressed: (order['status'] == 'Order Picked')
                                    ? null // Disabled
                                    : () {
                                        // Enabled
                                        _showAssignDADialog(
                                            context, ref, order['orderId']);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (order['status'] == 'Order Picked')
                                          ? Colors.grey // or any disabled color
                                          : Colors.blue.shade900,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                child: const Text(
                                  "Assign DA",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          // Additional order info
                          const SizedBox(height: 5),
                          Expanded(
                            // Use Expanded to make remaining info scrollable if needed
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Assigned To: ${order['DA'] ?? 'N/A'} (${order['assignedto'] ?? 'NA'} )",
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "DA Mobile: ${order['DAMOBILE'] ?? 'N/A'}",
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          ref.read(ordersProvider.notifier).fetchOrders();
          ref.read(deliveryUsersProvider.notifier).fetchDeliveryUsers();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _showAssignDADialog(
      BuildContext context, WidgetRef ref, String orderId) {
    // Clear any previously selected user
    ref.read(selectedUserProvider.notifier).state = null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Use Consumer (or you could use ref from above if you prefer)
        return Consumer(
          builder: (context, ref, _) {
            final deliveryUsers = ref.watch(deliveryUsersProvider);
            final selectedUser = ref.watch(selectedUserProvider);

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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            // The currently selected user from the provider
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
                              // Update the provider instead of using setState
                              ref.read(selectedUserProvider.notifier).state =
                                  value;
                            },
                          ),
                        ),
                      ],
                    ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedUser != null) {
                      // Assign DA in Firebase
                      ref
                          .read(ordersProvider.notifier)
                          .assignDeliveryAgent(orderId, selectedUser)
                          .then((_) async {
                        // Close the 'Assign DA' dialog
                        Navigator.pop(dialogContext);

                        // Refresh orders
                        ref.read(ordersProvider.notifier).fetchOrders();

                        // Show success animation in a new dialog
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
}
