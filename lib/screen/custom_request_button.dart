import 'package:flutter/material.dart';

import '../viewmodel/cake_viewmodel.dart';
import '../ui/cake_widgets.dart';
import '../viewmodel/admin/admin_viewmodel.dart';

class CustomRequestButton extends StatelessWidget {
  final CakeViewModel vm;
  const CustomRequestButton(this.vm, {super.key});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    icon: const Icon(Icons.draw_outlined),
    label: const Text('Request a special design / dietary cake'),
    onPressed: () async {
      final design = TextEditingController(),
          dietary = TextEditingController(),
          date = TextEditingController(text: dayKey(DateTime.now()));
      String? error;
      await showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
            title: const Text('Tell us about your cake'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: design,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Design brief',
                    ),
                  ),
                  gap,
                  TextField(
                    controller: dietary,
                    decoration: const InputDecoration(
                      labelText: 'Dietary needs / allergies',
                    ),
                  ),
                  gap,
                  TextField(
                    controller: date,
                    decoration: const InputDecoration(
                      labelText: 'Date (YYYY-MM-DD)',
                    ),
                  ),
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: vm.admin.busy
                    ? null
                    : () async {
                        final ok = await vm.admin.customerRequest(
                          vm.email,
                          vm.profile.name,
                          {
                            'design': design.text,
                            'dietary': dietary.text,
                            'date': date.text,
                          },
                        );
                        if (!context.mounted) return;
                        if (ok) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Request sent to the bakery.'),
                            ),
                          );
                        } else {
                          setLocal(() => error = vm.admin.error);
                        }
                      },
                child: const Text('Send request'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
