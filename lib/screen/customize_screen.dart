import 'package:flutter/material.dart';

import '../viewmodel/cake_viewmodel.dart';
import '../ui/cake_widgets.dart';
import '../ui/cake_style.dart';
import 'custom_request_button.dart';

class CustomizeScreen extends StatelessWidget {
  final CakeViewModel vm;
  const CustomizeScreen(this.vm, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = vm.custom;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        CustomRequestButton(vm),
        const PageTitle(
          'Made just for you',
          'Create the cake for your kind of celebration.',
        ),
        SizedBox(height: 260, child: CakePhoto(vm.customPhoto)),
        gap,
        const Text('Flavor', style: TextStyle(fontWeight: FontWeight.bold)),
        Choices(
          const ['Vanilla', 'Chocolate', 'Red Velvet'],
          c.flavor,
          (v) => vm.setCustom(c.copyWith(flavor: v)),
        ),
        gap,
        const Text('Size', style: TextStyle(fontWeight: FontWeight.bold)),
        Choices(
          const ['6 inch', '8 inch', '10 inch'],
          c.size,
          (v) => vm.setCustom(c.copyWith(size: v)),
        ),
        gap,
        const Text('Shape', style: TextStyle(fontWeight: FontWeight.bold)),
        Choices(
          const ['Round', 'Square', 'Heart'],
          c.shape,
          (v) => vm.setCustom(c.copyWith(shape: v)),
        ),
        gap,
        const Text(
          'The finishing touch',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Choices(
          const ['Fresh fruit', 'Flowers', 'Chocolate drips'],
          c.decoration,
          (v) => vm.setCustom(c.copyWith(decoration: v)),
        ),
        gap,
        TextFormField(
          initialValue: c.message,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: 'Cake message (optional)',
          ),
          onChanged: (v) => vm.setCustom(c.copyWith(message: v)),
        ),
        const Text(
          'Photo is inspiration; your cake will follow your choices.',
          style: TextStyle(color: CakeStyle.muted, fontSize: 11),
        ),
        gap,
        PrimaryButton(
          'Add to order · ${money(vm.customPrice)}',
          vm.addCustomCake,
        ),
      ],
    );
  }
}
