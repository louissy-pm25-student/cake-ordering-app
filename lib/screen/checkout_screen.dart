import 'package:flutter/material.dart';

import '../viewmodel/cake_viewmodel.dart';
import '../nav/cake_destination.dart';
import '../ui/cake_style.dart';
import '../ui/cake_widgets.dart';
import 'checkout_schedule.dart';

class CheckoutScreen extends StatelessWidget {
  final CakeViewModel vm;
  const CheckoutScreen(this.vm, {super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      const PageTitle(
        'The sweetest checkout',
        'Just a few details, then you’re all set.',
      ),
      if (vm.cart.isEmpty) ...[
        const EmptyCard(
          'Your cake box is empty',
          'Find something delicious to get started.',
        ),
        gap,
        PrimaryButton('Explore cakes', () => vm.navigate(CakeDestination.menu)),
      ] else ...[
        ...vm.cart.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CakePanel(
              padding: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 86,
                    height: 86,
                    child: CakePhoto(item.photo, photoData: item.photoData),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          item.details,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CakeStyle.muted,
                          ),
                        ),
                        Text(
                          money(item.price * item.quantity),
                          style: const TextStyle(
                            color: CakeStyle.caramel,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Decrease ${item.name} quantity',
                              onPressed: vm.busy
                                  ? null
                                  : () => vm.changeQuantity(item.id, -1),
                              icon: const Icon(Icons.remove),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              tooltip: 'Increase ${item.name} quantity',
                              onPressed: vm.busy
                                  ? null
                                  : () => vm.changeQuantity(item.id, 1),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        CheckoutSchedule(vm),
        const Text(
          'Contact / delivery address',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        gap,
        TextFormField(
          initialValue: vm.profile.address,
          enabled: !vm.busy,
          onChanged: vm.setAddress,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Full delivery address'),
        ),
        gap,
        const Text(
          'Payment method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Choices(
          const ['cash', 'card', 'online transfer'],
          vm.payment,
          vm.setPayment,
        ),
        gap,
        const CakePanel(
          color: CakeStyle.blush,
          child: Text(
            'Demo checkout — no money is charged and no delivery is booked.',
            style: TextStyle(fontSize: 12),
          ),
        ),
        gap,
        TextFormField(
          initialValue: vm.promo,
          onChanged: vm.setPromo,
          decoration: const InputDecoration(
            labelText: 'Promo code · try SWEET10',
          ),
        ),
        TextButton(
          onPressed: vm.applyPromo,
          child: Text(
            vm.promoApplied ? '10% discount applied ✓' : 'Apply promo code',
          ),
        ),
        if (vm.promoError)
          const Text(
            'That code wasn’t found. Try SWEET10.',
            style: TextStyle(color: Colors.red),
          ),
        CakePanel(
          child: Column(
            children: [
              PriceRow('Subtotal', money(vm.subtotal)),
              PriceRow('Delivery', money(vm.deliveryFee)),
              if (vm.promoApplied)
                PriceRow('Sweet discount', '−${money(vm.discount)}'),
              const Divider(),
              PriceRow('Total', money(vm.total)),
            ],
          ),
        ),
        gap,
        if (vm.profile.address.trim().length < 10)
          const Text(
            'Enter a full delivery address (at least 10 characters) to continue.',
            style: TextStyle(color: CakeStyle.muted, fontSize: 12),
          ),
        gap,
        PrimaryButton(
          vm.busy
              ? 'Saving your order…'
              : 'Place demo order · ${money(vm.total)}',
          vm.canPlaceOrder ? vm.placeOrder : null,
        ),
      ],
    ],
  );
}
