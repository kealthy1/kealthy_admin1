import 'package:flutter/material.dart';

class CustomTextFieldWithTitle extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final TextInputType inputType;

  const CustomTextFieldWithTitle({
    super.key,
    required this.title,
    required this.hint,
    required this.controller,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final FocusNode focusNode = FocusNode();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8), // Space between title and text field
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1), // Add border
              borderRadius: BorderRadius.circular(10), // Rounded corners
              color: Colors.white, // Optional: Add a background color
            ),
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              keyboardType: inputType,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none, // Remove default TextField border
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}