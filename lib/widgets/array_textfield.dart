import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy_admin/view/add_product.dart';

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
            hintText: hintText,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          onFieldSubmitted: (value) {
            if (value.isNotEmpty) {
              ref.read(provider.notifier).addItem(value);
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
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(items.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Chip(
                      label: Text(items[index]),
                      deleteIcon: const Icon(Icons.clear),
                      onDeleted: () {
                        ref.read(provider.notifier).removeItem(index);
                      },
                      backgroundColor: Colors.blue[100],
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }
}