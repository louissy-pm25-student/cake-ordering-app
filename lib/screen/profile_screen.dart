import 'package:flutter/material.dart';

import '../viewmodel/cake_viewmodel.dart';
import '../ui/cake_style.dart';
import '../ui/cake_widgets.dart';

class ProfileScreen extends StatelessWidget {
  final CakeViewModel vm;
  const ProfileScreen(this.vm, {super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      const PageTitle(
        'Your sweet corner',
        'A few details for your next celebration',
      ),
      CakePanel(
        color: CakeStyle.blush,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${vm.profile.name.isEmpty ? 'cake lover' : vm.profile.name}!',
              style: const TextStyle(fontFamily: 'serif', fontSize: 23),
            ),
            const Text(
              'There’s always a reason to celebrate.',
              style: TextStyle(color: CakeStyle.muted),
            ),
          ],
        ),
      ),
      gap,
      TextFormField(
        initialValue: vm.profile.name,
        onChanged: vm.setName,
        decoration: const InputDecoration(labelText: 'Your name'),
      ),
      gap,
      TextFormField(
        initialValue: vm.profile.address,
        onChanged: vm.setAddress,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Delivery address'),
      ),
      gap,
      PrimaryButton('Save details', () async {
        final saved = await vm.saveProfile();
        if (context.mounted && saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your details have been saved on this device.'),
            ),
          );
        }
      }),
      gap,
      TextFormField(
        initialValue: vm.profile.phone,
        onChanged: vm.setPhone,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'Phone number'),
      ),
      gap,
      Text(vm.email),
      TextButton.icon(
        onPressed: vm.busy ? null : vm.logout,
        icon: const Icon(Icons.logout),
        label: const Text('Log out'),
      ),
      gap,
      const Text(
        'Sweet Studio · Demo bakery\nOrders and details are stored on this device. No real payment or delivery service is connected.',
        style: TextStyle(color: CakeStyle.muted, height: 1.6),
      ),
    ],
  );
}
