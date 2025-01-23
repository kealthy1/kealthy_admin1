import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy_admin/view/add_product.dart';
import 'package:kealthy_admin/view/assign_da.dart';
import 'package:lottie/lottie.dart';

class Homepage extends ConsumerWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth =
        screenWidth / 4; // Each container takes 1/4th of screen width

    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            const Size.fromHeight(100), // Set the height of the AppBar
        child: AppBar(
          automaticallyImplyLeading: false, // Optionally hide the leading icon
          backgroundColor: Colors.blue.shade900, // AppBar background color
          flexibleSpace: Container(
            alignment: Alignment
                .center, // Align content to the center (horizontal and vertical)
            child: const Text(
              'ADMIN - KEALTHY',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold, // Optional: Makes the text bold
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAnimationWithText(
                context,
                animationPath:
                    'lib/assets/animations/Animation - 1735538146359.json',
                width: containerWidth,
                label: 'ADD PRODUCTS',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddProduct()),
                  );
                },
              ),
              _buildAnimationWithText(
                context,
                animationPath: 'lib/assets/animations/Delivery Boy.json',
                width: containerWidth,
                label: 'ASSIGN DA',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AssignDa()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationWithText(
    BuildContext context, {
    required String animationPath,
    required double width,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: width, // Set the width for each container
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 5,
                  spreadRadius: 2,
                  offset: const Offset(0, 3), // Shadow position
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Lottie.asset(
                animationPath,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
