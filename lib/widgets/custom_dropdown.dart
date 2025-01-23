import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomDropdownWithTitle extends ConsumerWidget {
  final String title;
  final StateProvider<String> provider;
  final List<String> options;
  final String hint;

  const CustomDropdownWithTitle({
    super.key,
    required this.title,
    required this.provider,
    required this.options,
    this.hint = 'Select an option',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);

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
          const SizedBox(height: 8), // Space between title and dropdown
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButton<String>(dropdownColor: Colors.white,
                value: value.isNotEmpty ? value : null, // Show hint if empty
                isExpanded: true,
                hint: Text(hint,style: const TextStyle(color: Colors.black),), // Default hint
                underline: Container(), // Remove underline
                items: options.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    ref.read(provider.notifier).state = newValue;
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}