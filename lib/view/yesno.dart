import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class YesNoDropdownWithTitle extends ConsumerWidget {
  final String title;
  final String label;
  final StateProvider<String> provider;

  const YesNoDropdownWithTitle({
    super.key,
    required this.title,
    required this.label,
    required this.provider,
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
                value: value,
                isExpanded: true,
                hint: Text(label), // Set the hint to the label
                underline: Container(), // Remove underline
                items: const [
                  DropdownMenuItem(
                    value: 'Yes',
                    child: Text('Yes'),
                  ),
                  DropdownMenuItem(
                    value: 'No',
                    child: Text('No'),
                  ),
                ],
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