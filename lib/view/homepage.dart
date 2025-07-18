import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy_admin/view/Add%20product/add_product.dart';
import 'package:kealthy_admin/view/Add%20product/offers.dart';
import 'package:kealthy_admin/view/Add%20product/update_product.dart';
// import 'package:kealthy_admin/view/add_category.dart';
// import 'package:kealthy_admin/view/assign_da.dart';
import 'package:lottie/lottie.dart';

class Homepage extends ConsumerWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth / 4;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.blue.shade900,
          flexibleSpace: Container(
            alignment: Alignment.center,
            child: const Text(
              'Home',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAnimationWithText(
                    context,
                    animationPath:
                        'lib/assets/animations/Animation - 1735538146359.json',
                    width: containerWidth,
                    label: 'Add Products',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddProduct()),
                      );
                    },
                  ),

                  // _buildAnimationWithText(
                  //   context,
                  //   animationPath: 'lib/assets/animations/Animation - 1743750483780.json',
                  //   width: containerWidth,
                  //   label: 'Add Categories',
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => const AssignDa()),
                  //     );
                  //   },
                  // ),
                  _buildAnimationWithText(
                    context,
                    animationPath:
                        'lib/assets/animations/Animation - 1743049786469.json',
                    width: containerWidth,
                    label: 'Edit Products',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const UpdateProduct()),
                      );
                    },
                  ),
                  _buildAnimationWithText(
                    context,
                    animationPath:
                        'lib/assets/animations/Animation - 1750314085880.json',
                    width: containerWidth,
                    label: 'Offers',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const OffersPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
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
