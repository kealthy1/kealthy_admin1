import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy_admin/view/list_notifier.dart';

class ArrayInputWithTitle extends ConsumerWidget {
  final String title;
  final String hintText;
  final StateNotifierProvider<ListNotifier, List<String>> provider;

  const ArrayInputWithTitle({
    super.key,
    required this.title,
    required this.hintText,
    required this.provider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hintText,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          onFieldSubmitted: (value) {
            if (value.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(provider.notifier).addItem(value);
              });
              controller.clear();
            }
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Added Items:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, child) {
            final items = ref.watch(provider);
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(items.length, (index) {
                return Chip(
                  label: Text(items[index]),
                  deleteIcon: const Icon(Icons.clear),
                  onDeleted: () {
                    ref.read(provider.notifier).removeItem(index);
                  },
                  backgroundColor: Colors.blue[100],
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
