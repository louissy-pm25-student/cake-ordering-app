import 'package:flutter/material.dart';

import '../viewmodel/cake_viewmodel.dart';
import '../viewmodel/admin/admin_viewmodel.dart';
import '../ui/cake_widgets.dart';

class CheckoutSchedule extends StatelessWidget {
  final CakeViewModel vm;
  const CheckoutSchedule(this.vm, {super.key});
  @override
  Widget build(BuildContext context) {
    final slots = vm.admin
        .records('slots')
        .where((s) => s.flag('active') && s.text('date') == vm.fulfilmentDate)
        .toList();
    final zones = vm.admin
        .records('zones')
        .where((s) => s.flag('active'))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pickup or delivery',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Choices(const ['pickup', 'delivery'], vm.fulfilment, vm.setFulfilment),
        gap,
        OutlinedButton.icon(
          onPressed: vm.busy
              ? null
              : () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.tryParse(vm.fulfilmentDate) ?? DateTime.now(),
                    firstDate: DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (date != null) vm.setOrderDate(dayKey(date));
                },
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text('Date: ${vm.fulfilmentDate}'),
        ),
        gap,
        if (slots.isNotEmpty)
          DropdownButtonFormField<String>(
            key: ValueKey('slot-${vm.fulfilmentDate}'),
            initialValue: slots.any((s) => s.id == vm.slot) ? vm.slot : null,
            decoration: const InputDecoration(labelText: 'Time slot'),
            items: slots
                .map(
                  (s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(
                      '${s.text('name')} (${s.text('capacity')} order capacity)',
                    ),
                  ),
                )
                .toList(),
            onChanged: (s) => vm.setSlot(s ?? ''),
          ),
        if (vm.fulfilment == 'delivery') ...[
          gap,
          DropdownButtonFormField<String>(
            initialValue: zones.any((s) => s.id == vm.zone) ? vm.zone : null,
            decoration: const InputDecoration(labelText: 'Delivery zone'),
            items: zones
                .map(
                  (s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(
                      '${s.text('name')} · ${money(s.number('fee'))}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (s) => vm.setZone(s ?? ''),
          ),
          if (zones.isEmpty)
            const Text('No delivery zones available. Please choose pickup.'),
        ],
        gap,
        TextFormField(
          initialValue: vm.orderNotes,
          decoration: const InputDecoration(
            labelText: 'Allergies / order instructions',
          ),
          onChanged: (s) => vm.orderNotes = s,
          maxLines: 2,
        ),
        gap,
      ],
    );
  }
}
