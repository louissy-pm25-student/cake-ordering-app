import 'package:flutter/material.dart';

import '../viewmodel/cake_viewmodel.dart';
import '../nav/cake_destination.dart';
import '../ui/cake_style.dart';
import '../ui/cake_widgets.dart';

class OrdersScreen extends StatelessWidget {
  final CakeViewModel vm;
  const OrdersScreen(this.vm, {super.key});
  Future<void> _review(BuildContext context, String id) async {
    final comment = TextEditingController();
    var rating = 5;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Share your feedback'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: rating,
                items: [1, 2, 3, 4, 5]
                    .map(
                      (r) =>
                          DropdownMenuItem(value: r, child: Text('$r stars')),
                    )
                    .toList(),
                onChanged: (r) => setLocal(() => rating = r!),
              ),
              TextField(
                controller: comment,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Your review'),
              ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
            ],
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
                      final ok = await vm.admin.customerReview(
                        vm.email,
                        vm.profile.name,
                        id,
                        rating,
                        comment.text,
                      );
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.pop(context);
                      } else {
                        setLocal(() => error = vm.admin.error);
                      }
                    },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      const PageTitle(
        'Track your happiness',
        'A little closer to your celebration.',
      ),
      if (vm.customerNotifications.any((n) => !n.flag('read'))) ...[
        const Text(
          'Updates for you',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...vm.customerNotifications
            .where((n) => !n.flag('read'))
            .map(
              (n) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(n.text('name')),
                trailing: IconButton(
                  tooltip: 'Mark read',
                  onPressed: () =>
                      vm.admin.markRead(n.id, customerEmail: vm.email),
                  icon: const Icon(Icons.done),
                ),
              ),
            ),
        gap,
      ],
      if (vm.orders.isEmpty) ...[
        const EmptyCard(
          'Good things are on the way',
          'Your orders will appear here after checkout.',
        ),
        gap,
        PrimaryButton(
          'Find your first cake',
          () => vm.navigate(CakeDestination.menu),
        ),
      ],
      for (final order in vm.orders) ...[
        CakePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.id,
                style: const TextStyle(
                  color: CakeStyle.caramel,
                  fontWeight: FontWeight.bold,
                ),
              ),
              gap,
              ...(() {
                final record = vm.admin.record('orders', order.id)!;
                final status = record.text('status');
                final index = [
                  'pending',
                  'baking',
                  'ready',
                  'delivered',
                ].indexOf(status);
                return <Widget>[
                  if (status == 'cancelled')
                    Text('Cancelled: ${record.text('cancellation')}')
                  else
                    ...[
                      'Order confirmed',
                      'Baking in progress',
                      'Ready for pickup / delivery',
                      'Delivered',
                    ].indexed.map(
                      (e) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          e.$1 <= index
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: e.$1 <= index
                              ? CakeStyle.caramel
                              : CakeStyle.muted,
                        ),
                        title: Text(e.$2),
                      ),
                    ),
                  Text('${record.text('date')} · ${record.text('fulfilment')}'),
                  if (record.text('driver').isNotEmpty)
                    Text(
                      'Driver: ${vm.admin.record('drivers', record.text('driver'))?.text('name') ?? ''}',
                    ),
                  if (status == 'delivered')
                    TextButton(
                      onPressed: () => _review(context, order.id),
                      child: const Text('Leave a review'),
                    ),
                ];
              })(),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text('${item.quantity} × ${item.name}'),
                ),
              ),
              Text(order.address),
              PriceRow('Order total', money(order.total)),
            ],
          ),
        ),
        gap,
      ],
      ...vm.admin
          .records('requests')
          .where((r) => r.text('email') == vm.email)
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CakePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Custom request · ${r.text('status')}'),
                    Text(r.text('design')),
                    Text('Quote: ${money(r.number('quote'))}'),
                  ],
                ),
              ),
            ),
          ),
      ...vm.admin
          .records('reviews')
          .where(
            (r) => r.text('email') == vm.email && r.text('reply').isNotEmpty,
          )
          .map(
            (r) => ListTile(
              title: const Text('Bakery reply'),
              subtitle: Text(r.text('reply')),
            ),
          ),
      const Text(
        'Order status is managed locally by the bakery admin. No external courier service is connected.',
        style: TextStyle(color: CakeStyle.muted, fontSize: 12),
      ),
    ],
  );
}
