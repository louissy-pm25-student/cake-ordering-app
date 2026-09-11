import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';

import '../../model/admin/admin_record.dart';
import '../../model/admin/admin_schema.dart';
import '../../viewmodel/admin/admin_viewmodel.dart';
import '../../ui/cake_style.dart';
import '../../ui/cake_widgets.dart';
import 'admin_editor.dart';
import 'admin_profile_screen.dart';

class AdminScreen extends StatefulWidget {
  final AdminViewModel vm;
  final VoidCallback onLogout;
  const AdminScreen(this.vm, {required this.onLogout, super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _section = 'dashboard',
      _search = '',
      _status = 'all',
      _period = 'month';
  String? _date;
  AdminViewModel get vm => widget.vm;
  void _select(String section) {
    setState(() {
      _section = section;
      _search = '';
      _status = 'all';
      _date = null;
    });
  }

  void _message(bool ok) {
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Unable to complete action.')),
      );
    }
  }

  Future<String?> _prompt(
    String title, {
    String initial = '',
    bool numeric = false,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    // Let the dialog finish its reverse animation before disposing its controller.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    return result;
  }

  Future<void> _receipt(AdminRecord order) async {
    final text = vm.receipt(order);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Receipt ${order.id}'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(child: SelectableText(text)),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt copied.')),
                );
              }
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final location = await getSaveLocation(
                  suggestedName: 'receipt-${order.id}.txt',
                );
                if (location != null) {
                  await XFile.fromData(
                    Uint8List.fromList(utf8.encode(text)),
                    mimeType: 'text/plain',
                  ).saveTo(location.path);
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'File saving is unavailable here. Use Copy.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Save .txt'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _schedule(AdminRecord order) async {
    final driver = TextEditingController(text: order.text('driver'));
    final date = TextEditingController(text: order.text('date'));
    final slot = TextEditingController(text: order.text('slot'));
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Schedule & driver'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: date,
                    decoration: const InputDecoration(
                      labelText: 'Date (YYYY-MM-DD)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: vm.record('slots', slot.text) != null
                        ? slot.text
                        : '',
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Time slot'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('None')),
                      ...vm
                          .records('slots')
                          .map(
                            (r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(
                                '${r.text('date')} ${r.text('name')}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                    ],
                    onChanged: (v) => slot.text = v ?? '',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: vm.record('drivers', driver.text) != null
                        ? driver.text
                        : '',
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Driver'),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Unassigned'),
                      ),
                      ...vm
                          .records('drivers')
                          .map(
                            (r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(r.text('name')),
                            ),
                          ),
                    ],
                    onChanged: (v) => driver.text = v ?? '',
                  ),
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: vm.busy
                  ? null
                  : () async {
                      final ok = await vm.assignDelivery(
                        order.id,
                        driver.text,
                        date.text,
                        slot.text,
                      );
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.pop(context);
                      } else {
                        setLocal(() => error = vm.error);
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    driver.dispose();
    date.dispose();
    slot.dispose();
  }

  List<AdminRecord> get _orders => vm
      .records('orders')
      .where(
        (r) =>
            (_status == 'all' || r.text('status') == _status) &&
            (_date == null || r.text('date') == _date) &&
            '${r.id} ${r.text('customer')} ${r.text('email')} ${r.text('phone')} ${r.text('notes')}'
                .toLowerCase()
                .contains(_search.toLowerCase()),
      )
      .toList();
  Widget _orderCard(AdminRecord order) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: CakePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                order.id,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Chip(label: Text(order.text('status'))),
              Chip(label: Text(order.text('paymentStatus'))),
            ],
          ),
          Text('${order.text('customer')} · ${order.text('email')}'),
          Text(
            '${order.text('date')} · ${order.text('fulfilment')} · ${vm.record('slots', order.text('slot'))?.text('name') ?? 'Unscheduled time'}',
            style: const TextStyle(color: CakeStyle.muted),
          ),
          if (order.text('address').isNotEmpty) Text(order.text('address')),
          for (final value in order.values['items'] as List? ?? [])
            Text(
              '${value['quantity']} × ${value['name']} · ${value['details'] ?? ''}',
            ),
          Text(
            '${money(order.number('total'))} · ${order.text('payment')}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (order.text('notes').isNotEmpty)
            Text('Notes: ${order.text('notes')}'),
          if (order.text('cancellation').isNotEmpty)
            Text('Cancelled: ${order.text('cancellation')}'),
          if (order.text('driver').isNotEmpty)
            Text(
              'Driver: ${vm.record('drivers', order.text('driver'))?.text('name') ?? order.text('driver')}',
            ),
          Wrap(
            spacing: 6,
            children: [
              if (vm.canChangeStatus &&
                  !['cancelled', 'delivered'].contains(order.text('status')) &&
                  !(vm.role == 'baker' && order.text('status') == 'ready'))
                TextButton.icon(
                  onPressed: vm.busy
                      ? null
                      : () async {
                          final next = {
                            'pending': 'baking',
                            'baking': 'ready',
                            'ready': 'delivered',
                          }[order.text('status')]!;
                          _message(await vm.updateStatus(order.id, next));
                        },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    'Mark ${{'pending': 'baking', 'baking': 'ready', 'ready': 'delivered'}[order.text('status')]}',
                  ),
                ),
              if (vm.canWrite('orders') &&
                  order.text('status') == 'pending' &&
                  order.text('paymentStatus') == 'pending' &&
                  order.text('source') == 'manual')
                TextButton(
                  onPressed: () =>
                      editAdminRecord(context, vm, 'orders', record: order),
                  child: const Text('Edit'),
                ),
              if (vm.canWrite('orders') &&
                  !['cancelled', 'delivered'].contains(order.text('status')))
                TextButton(
                  onPressed: () => _schedule(order),
                  child: const Text('Schedule / driver'),
                ),
              if (vm.canWrite('orders') &&
                  !['cancelled', 'delivered'].contains(order.text('status')))
                TextButton(
                  onPressed: () async {
                    final reason = await _prompt('Cancellation reason');
                    if (reason != null) {
                      _message(await vm.cancelOrder(order.id, reason));
                    }
                  },
                  child: const Text('Cancel order'),
                ),
              if (vm.canFinance &&
                  order.text('paymentStatus') == 'pending' &&
                  order.text('status') != 'cancelled')
                TextButton(
                  onPressed: () async {
                    final reference = await _prompt(
                      'Payment reference / cash receipt',
                    );
                    if (reference != null) {
                      _message(
                        await vm.paymentAction(order.id, reference: reference),
                      );
                    }
                  },
                  child: const Text('Record payment'),
                ),
              if (vm.canFinance &&
                  [
                    'paid',
                    'refund pending',
                    'partially refunded',
                  ].contains(order.text('paymentStatus')))
                TextButton(
                  onPressed: () async {
                    final amount = await _prompt(
                      'Refund amount',
                      initial:
                          (order.number('total') - order.number('refunded'))
                              .toStringAsFixed(2),
                      numeric: true,
                    );
                    if (amount == null) return;
                    final reference = await _prompt(
                      'Refund transaction reference (record only)',
                    );
                    if (reference != null) {
                      _message(
                        await vm.paymentAction(
                          order.id,
                          refund: true,
                          amount: double.tryParse(amount),
                          reference: reference,
                        ),
                      );
                    }
                  },
                  child: const Text('Record refund'),
                ),
              if (vm.canFinance)
                TextButton(
                  onPressed: () => _receipt(order),
                  child: const Text('Receipt'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
  Widget _filters() => Column(
    children: [
      TextField(
        key: ValueKey('search-$_section'),
        decoration: const InputDecoration(
          hintText: 'Search ID, customer, email…',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) => setState(() => _search = value),
      ),
      gap,
      Wrap(
        spacing: 8,
        children: [
          DropdownButton<String>(
            value: _status,
            items: [
              'all',
              'pending',
              'baking',
              'ready',
              'delivered',
              'cancelled',
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _status = v!),
          ),
          TextButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (date != null) setState(() => _date = dayKey(date));
            },
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(_date ?? 'Filter date'),
          ),
          if (_date != null)
            IconButton(
              onPressed: () => setState(() => _date = null),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      gap,
    ],
  );
  Widget _records() {
    final schema = sectionFor(_section);
    final rows = vm
        .records(_section)
        .where(
          (r) => r.values.entries
              .where((e) => !['credential', 'photoData'].contains(e.key))
              .map((e) => e.value)
              .join(' ')
              .toLowerCase()
              .contains(_search.toLowerCase()),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(schema.subtitle, style: const TextStyle(color: CakeStyle.muted)),
        gap,
        TextField(
          key: ValueKey(_section),
          decoration: const InputDecoration(
            hintText: 'Search records',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (s) => setState(() => _search = s),
        ),
        gap,
        if (rows.isEmpty)
          const EmptyCard(
            'Nothing here yet',
            'Use Add to create the first record.',
          ),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: CakePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_section == 'products' &&
                      row.text('photoData').isNotEmpty)
                    SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: Image.memory(
                        base64Decode(row.text('photoData')),
                        fit: BoxFit.cover,
                      ),
                    ),
                  Text(
                    row.text('name', row.text('customer', row.id)),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SelectableText(
                    'ID: ${row.id}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: CakeStyle.muted,
                    ),
                  ),
                  for (final field in schema.fields.where(
                    (f) =>
                        !['photo', 'password'].contains(f.type) &&
                        f.key != 'name',
                  ))
                    if (row.text(field.key).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${field.label}: ${field.reference == null ? row.text(field.key) : vm.record(field.reference!, row.text(field.key))?.text('name', row.text(field.key)) ?? row.text(field.key)}',
                        ),
                      ),
                  if (_section == 'ingredients' &&
                      row.number('stock') <= row.number('minimum'))
                    const Chip(
                      label: Text('Low stock'),
                      backgroundColor: CakeStyle.blush,
                    ),
                  if (_section == 'slots')
                    Text(
                      'Booked: ${vm.records('orders').where((o) => o.text('slot') == row.id && o.text('status') != 'cancelled').length} / ${row.text('capacity')}',
                    ),
                  if (_section == 'customers')
                    ...vm
                        .records('orders')
                        .where((o) => o.text('email') == row.text('email'))
                        .map(
                          (o) => Text(
                            '${o.id} · ${o.text('status')} · ${money(o.number('total'))}',
                          ),
                        ),
                  if (vm.canWrite(_section))
                    Wrap(
                      children: [
                        TextButton(
                          onPressed: () => editAdminRecord(
                            context,
                            vm,
                            _section,
                            record: row,
                          ),
                          child: const Text('Edit'),
                        ),
                        if (_section != 'settings')
                          TextButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Delete this record?'),
                                  content: Text(row.text('name', row.id)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Keep'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                _message(await vm.delete(_section, row.id));
                              }
                            },
                            child: const Text('Delete'),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _dashboard() {
    final orders = vm.records('orders');
    final now = DateTime.now();
    final since = switch (_period) {
      'day' => DateTime(now.year, now.month, now.day),
      'week' => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1)),
      _ => DateTime(now.year, now.month),
    };
    final inPeriod = orders
        .where(
          (o) =>
              (DateTime.tryParse(o.text('createdAt')) ?? DateTime(1970))
                  .compareTo(since) >=
              0,
        )
        .toList();
    final net = inPeriod
        .where(
          (o) => [
            'paid',
            'refund pending',
            'partially refunded',
            'refunded',
          ].contains(o.text('paymentStatus')),
        )
        .fold<double>(
          0,
          (n, o) => n + o.number('total') - o.number('refunded'),
        );
    final best = <String, int>{};
    final hours = <String, int>{};
    final daily = <String, double>{};
    for (final order in inPeriod.where(
      (o) => o.text('status') != 'cancelled',
    )) {
      for (final item in order.values['items'] as List? ?? []) {
        best.update(
          '${item['name']}',
          (n) => n + (item['quantity'] as num).toInt(),
          ifAbsent: () => (item['quantity'] as num).toInt(),
        );
      }
      final date = DateTime.tryParse(order.text('createdAt'));
      if (date != null) {
        hours.update('${date.hour}:00', (n) => n + 1, ifAbsent: () => 1);
        daily.update(
          dayKey(date),
          (n) => n + order.number('total'),
          ifAbsent: () => order.number('total'),
        );
      }
    }
    final ranked = best.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peak = hours.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle(
          'Your bakery, at a glance',
          'Plan the day. Keep every celebration on track.',
        ),
        Choices(
          const ['day', 'week', 'month'],
          _period,
          (v) => setState(() => _period = v),
        ),
        gap,
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metric('Orders', '${inPeriod.length}'),
            _metric(
              'In production',
              '${orders.where((o) => ['pending', 'baking'].contains(o.text('status'))).length}',
            ),
            _metric('Alerts', '${vm.alerts.length}'),
            if (vm.canFinance) _metric('Net collected', money(net)),
            _metric('Peak hour', peak.isEmpty ? '—' : peak.first.key),
          ],
        ),
        gap,
        if (vm.canFinance)
          const Text(
            'Net collected uses payment records on orders created in the selected period, minus recorded refunds. It is not a cash settlement report.',
            style: TextStyle(color: CakeStyle.muted, fontSize: 12),
          ),
        gap,
        const Text(
          'Best sellers',
          style: TextStyle(fontSize: 20, fontFamily: 'serif'),
        ),
        gap,
        if (ranked.isEmpty)
          const EmptyCard(
            'No sales yet',
            'Best sellers appear when orders are created.',
          ),
        ...ranked
            .take(5)
            .map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.key),
                trailing: Text('${e.value} cakes'),
              ),
            ),
        gap,
        if (vm.canFinance) ...[
          const Text(
            'Daily booked revenue (excludes cancelled orders)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final key in daily.keys.toList()..sort())
            PriceRow(key, money(daily[key]!)),
        ],
        gap,
        const Text(
          'Needs attention',
          style: TextStyle(fontFamily: 'serif', fontSize: 20),
        ),
        ...vm.alerts
            .take(8)
            .map(
              (r) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.notifications_outlined,
                  color: CakeStyle.caramel,
                ),
                title: Text(r.text('name')),
              ),
            ),
      ],
    );
  }

  Widget _metric(String name, String value) => SizedBox(
    width: 155,
    child: CakePanel(
      color: CakeStyle.blush,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          Text(name),
        ],
      ),
    ),
  );
  Widget _calendar() => Column(
    children: [
      CalendarDatePicker(
        initialDate: DateTime.tryParse(_date ?? '') ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        onDateChanged: (d) => setState(() => _date = dayKey(d)),
      ),
      Text(
        '${_date ?? vm.today}: ${vm.records('orders').where((r) => r.text('date') == (_date ?? vm.today) && r.text('status') != 'cancelled').length} / ${vm.settings.text('capacity')} orders',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      gap,
      ...vm
          .records('orders')
          .where((r) => r.text('date') == (_date ?? vm.today))
          .map(_orderCard),
      gap,
      const Text('Production load by date'),
      ...(() {
        final dates =
            vm.records('orders').map((o) => o.text('date')).toSet().toList()
              ..sort();
        return dates.map(
          (date) => ListTile(
            title: Text(date),
            trailing: Text(
              '${vm.records('orders').where((o) => o.text('date') == date && o.text('status') != 'cancelled').length} orders',
            ),
            onTap: () => setState(() => _date = date),
          ),
        );
      })(),
    ],
  );
  Widget _body() => switch (_section) {
    'profile' => AdminProfileScreen(vm),
    'dashboard' => _dashboard(),
    'orders' => Column(
      children: [
        _filters(),
        if (_orders.isEmpty)
          const EmptyCard(
            'No matching orders',
            'Create a manual order or wait for a customer checkout.',
          ),
        ..._orders.map(_orderCard),
      ],
    ),
    'calendar' => _calendar(),
    'finance' => Column(
      children: [
        _dashboard(),
        gap,
        const Text('Payment & refund ledger'),
        ...vm
            .records('payments')
            .map(
              (p) => ListTile(
                title: Text('${p.text('name')} · ${money(p.number('amount'))}'),
                subtitle: Text(
                  '${p.text('order')}\n${p.text('reference')} · ${p.text('date')}',
                ),
              ),
            ),
        gap,
        const Text('Orders awaiting payment or refund'),
        ...vm
            .records('orders')
            .where(
              (o) => [
                'pending',
                'refund pending',
              ].contains(o.text('paymentStatus')),
            )
            .map(_orderCard),
      ],
    ),
    'logs' => Column(
      children: vm
          .records('logs')
          .map(
            (r) => ListTile(
              title: Text(r.text('name')),
              subtitle: Text(
                '${r.text('actor')} · ${r.text('date')}\n${r.text('target')}',
              ),
            ),
          )
          .toList(),
    ),
    'notifications' => Column(
      children: [
        if (vm.alerts.isEmpty)
          const EmptyCard(
            'All caught up',
            'New orders, low stock and due deliveries will appear here.',
          ),
        ...vm.alerts.map(
          (r) => ListTile(
            title: Text(r.text('name')),
            subtitle: Text(r.text('date')),
            trailing: r.id.startsWith('low-') || r.id.startsWith('due-')
                ? null
                : IconButton(
                    tooltip: 'Mark read',
                    onPressed: () => vm.markRead(r.id),
                    icon: const Icon(Icons.done),
                  ),
          ),
        ),
      ],
    ),
    _ => _records(),
  };
  @override
  Widget build(BuildContext context) {
    final sections = {
      'dashboard': 'Dashboard',
      'orders': 'Orders',
      'products': 'Menu',
      for (final s in adminSections.where(
        (s) => !['orders', 'products'].contains(s.key),
      ))
        s.key: s.title,
      'calendar': 'Production calendar',
      'finance': 'Payments & reports',
      'logs': 'Activity log',
      'notifications': 'Notifications',
      'profile': 'Profile',
    };
    final icons = <String, IconData>{
      'dashboard': Icons.dashboard_outlined,
      'orders': Icons.receipt_long_outlined,
      'products': Icons.cake_outlined,
      'calendar': Icons.calendar_month_outlined,
      'finance': Icons.payments_outlined,
      'logs': Icons.history,
      'notifications': Icons.notifications_outlined,
      'profile': Icons.account_circle_outlined,
      'ingredients': Icons.inventory_2_outlined,
      'customers': Icons.people_outline,
      'staff': Icons.badge_outlined,
      'settings': Icons.settings_outlined,
      'drivers': Icons.local_shipping_outlined,
    };
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (p, r) {
          if (!p) _select('dashboard');
        },
        child: Scaffold(
          backgroundColor: CakeStyle.cream,
          drawer: Drawer(
            backgroundColor: CakeStyle.cream,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cake_outlined, size: 36),
                      title: const Text('Sweet Studio'),
                      subtitle: Text('${vm.username} · ${vm.role}'),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        for (final entry in sections.entries.where(
                          (e) => vm.canRead(e.key),
                        ))
                          ListTile(
                            key: ValueKey('admin-nav-${entry.key}'),
                            selected: _section == entry.key,
                            selectedTileColor: CakeStyle.blush,
                            leading: Icon(
                              icons[entry.key] ?? Icons.folder_outlined,
                            ),
                            title: Text(entry.value),
                            onTap: () {
                              Navigator.of(context).pop();
                              _select(entry.key);
                            },
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Log out'),
                    onTap: vm.busy
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            widget.onLogout();
                          },
                  ),
                ],
              ),
            ),
          ),
          appBar: AppBar(
            backgroundColor: CakeStyle.cream,
            leading: Builder(
              builder: (context) => IconButton(
                tooltip: 'Open admin menu',
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Text(sections[_section] ?? 'Admin'),
            actions: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => _select('notifications'),
                icon: Badge(
                  label: Text(vm.alerts.length.toString()),
                  child: const Icon(Icons.notifications_outlined),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    if (vm.busy) const LinearProgressIndicator(),
                    Expanded(
                      child: SingleChildScrollView(
                        key: ValueKey(_section),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                        child: vm.canRead(_section)
                            ? _body()
                            : const Text('Access denied.'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton:
              adminSections.any((s) => s.key == _section) &&
                  vm.canWrite(_section)
              ? FloatingActionButton.extended(
                  onPressed: vm.busy
                      ? null
                      : () => editAdminRecord(
                          context,
                          vm,
                          _section,
                          record: _section == 'settings' ? vm.settings : null,
                        ),
                  icon: const Icon(Icons.add),
                  label: Text(_section == 'settings' ? 'Edit settings' : 'Add'),
                )
              : null,
        ),
      ),
    );
  }
}
