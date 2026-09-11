import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../model/admin/admin_record.dart';
import '../../model/admin/admin_schema.dart';
import '../../model/local_account.dart';

String dayKey(DateTime date) => date.toIso8601String().substring(0, 10);

class AdminViewModel extends ChangeNotifier {
  final Future<bool> Function(Map<String, dynamic>) persist;
  AdminViewModel(this.persist);
  Map<String, dynamic> _data = {};
  String? _username;
  String _role = '';
  bool busy = false;
  String? error;
  bool get signedIn => _username != null;
  String get username => _username ?? '';
  String get role => _role;
  String get today => dayKey(DateTime.now());
  Map<String, dynamic> toJson() =>
      jsonDecode(jsonEncode(_data)) as Map<String, dynamic>;
  List<AdminRecord> _rows(Map<String, dynamic> source, String section) =>
      (source[section] as List? ?? [])
          .map((e) => AdminRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
  List<AdminRecord> records(String section) =>
      List.unmodifiable(_rows(_data, section).where((r) => !r.flag('deleted')));
  AdminRecord? record(String section, String id) {
    for (final row in records(section)) {
      if (row.id == id) return row;
    }
    return null;
  }

  AdminRecord get settings => records('settings').first;
  void load(Map<String, dynamic> data) {
    _data = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    if (_rows(_data, 'settings').isEmpty) {
      _data['settings'] = [
        AdminRecord('store', {
          'name': 'Sweet Studio',
          'tax': 0,
          'capacity': 20,
          'address': '',
          'taxId': '',
        }).toJson(),
      ];
    }
    if (!_data.containsKey('codes')) {
      _data['codes'] = [
        AdminRecord('sweet10', {
          'name': 'SWEET10',
          'percent': 10,
          'minimum': 0,
          'points': 0,
          'active': true,
        }).toJson(),
      ];
    }
  }

  void importCustomers(
    Map<String, dynamic> users,
    List<LocalAccount> accounts,
  ) {
    for (final account in accounts) {
      final user = Map<String, dynamic>.from(
        users[account.email] as Map? ?? {},
      );
      final profile = Map<String, dynamic>.from(user['profile'] as Map? ?? {});
      if (record('customers', account.email) == null) {
        _put(
          _data,
          'customers',
          AdminRecord(account.email, {
            'name': profile['name'] ?? account.name,
            'email': account.email,
            'address': profile['address'] ?? '',
            'points': 0,
          }),
        );
      }
      for (final value in user['orders'] as List? ?? []) {
        final order = Map<String, dynamic>.from(value as Map);
        if (record('orders', '${order['id']}') == null) {
          _put(
            _data,
            'orders',
            AdminRecord('${order['id']}', {
              ...order,
              'customer': account.name,
              'email': account.email,
              'status': 'pending',
              'paymentStatus': 'pending',
              'date': today,
              'createdAt': DateTime.now().toIso8601String(),
              'subtotal': order['total'],
              'taxAmount': 0,
              'fee': 0,
              'discount': 0,
              'allocations': <String, dynamic>{},
              'fulfilment': 'delivery',
            }),
          );
        }
      }
    }
  }

  bool canRead(String section) =>
      signedIn &&
      (section == 'profile' ||
          role == 'owner' ||
          role == 'manager' && section != 'staff' ||
          role == 'baker' &&
              [
                'dashboard',
                'orders',
                'ingredients',
                'recipes',
                'requests',
                'slots',
                'calendar',
                'notifications',
              ].contains(section) ||
          role == 'staff' &&
              [
                'dashboard',
                'orders',
                'products',
                'variants',
                'customers',
                'requests',
                'reviews',
                'calendar',
                'slots',
                'zones',
                'drivers',
                'notifications',
              ].contains(section));
  bool canWrite(String section) =>
      signedIn &&
      (section == 'profile' ||
          role == 'owner' ||
          role == 'manager' && !['staff', 'settings'].contains(section) ||
          role == 'baker' && ['ingredients', 'requests'].contains(section) ||
          role == 'staff' &&
              ['orders', 'customers', 'requests', 'reviews'].contains(section));
  bool get canChangeStatus => signedIn;
  bool get canFinance => signedIn && ['owner', 'manager'].contains(role);
  Future<bool> login(String username, String password) async {
    if (busy) return false;
    busy = true;
    try {
      if (username == ownerUsername) {
        final raw = _data['ownerCredential'];
        final valid = raw == null
            ? password == 'admin123'
            : await LocalAccount.fromJson(Map<String, dynamic>.from(raw as Map))
                  .verify(password);
        if (!valid) return false;
        _username = username;
        _role = 'owner';
        return true;
      }
      for (final person in records('staff')) {
        if (person.text('username') == username && person.flag('active')) {
          final credential = LocalAccount.fromJson(
            Map<String, dynamic>.from(person.values['credential'] as Map),
          );
          if (await credential.verify(password)) {
            _username = username;
            _role = person.text('role');
            return true;
          }
        }
      }
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  String get ownerUsername => _data['ownerUsername'] as String? ?? 'admin';

  Future<bool> updateProfile({
    required String newUsername,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (busy || !signedIn) return _fail('Please sign in first.');
    final name = newUsername.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9_.-]{3,40}$').hasMatch(name)) {
      return _fail(
        'Username must be 3–40 letters, numbers, dots, underscores or hyphens.',
      );
    }
    if (newPassword != confirmPassword) return _fail('Passwords do not match.');
    if (newPassword.isNotEmpty && newPassword.length < 8) {
      return _fail('Use at least 8 characters for the new password.');
    }
    final person = role == 'owner'
        ? null
        : records('staff')
              .where((r) => r.text('username') == username && r.flag('active'))
              .firstOrNull;
    if (role != 'owner' && person == null) {
      return _fail('Account is unavailable.');
    }
    if ((role != 'owner' && name == ownerUsername) ||
        records('staff')
            .any((r) => r.id != person?.id && r.text('username') == name)) {
      return _fail('Username already exists.');
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final raw = role == 'owner'
          ? _data['ownerCredential']
          : person!.values['credential'];
      final valid = raw == null && role == 'owner'
          ? currentPassword == 'admin123'
          : await LocalAccount.fromJson(Map<String, dynamic>.from(raw as Map))
                .verify(currentPassword);
      if (!valid) return _fail('Current password is incorrect.');
      final credential = await LocalAccount.create(
        role == 'owner' ? 'Owner' : person!.text('name'),
        name,
        newPassword.isEmpty ? currentPassword : newPassword,
      );
      final candidate = toJson();
      if (role == 'owner') {
        candidate['ownerUsername'] = name;
        candidate['ownerCredential'] = credential.toJson();
      } else {
        _put(
          candidate,
          'staff',
          person!.patch({'username': name, 'credential': credential.toJson()}),
        );
      }
      _log(candidate, 'Updated own login profile', name);
      if (!await _commit(candidate)) return false;
      _username = name;
      return true;
    } catch (_) {
      return _fail('Profile could not be saved. Please retry.');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  bool hasUsername(String name) =>
      name == ownerUsername ||
      records('staff').any((r) => r.text('username') == name);
  void logout() {
    _username = null;
    _role = '';
    error = null;
    notifyListeners();
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();
  void _put(Map<String, dynamic> data, String section, AdminRecord row) {
    final rows = _rows(data, section);
    final index = rows.indexWhere((r) => r.id == row.id);
    if (index < 0) {
      rows.insert(0, row);
    } else {
      rows[index] = row;
    }
    data[section] = rows.map((r) => r.toJson()).toList();
  }

  void _log(
    Map<String, dynamic> data,
    String action,
    String target, {
    String? actor,
  }) => _put(
    data,
    'logs',
    AdminRecord(_id(), {
      'name': action,
      'target': target,
      'actor': actor ?? username,
      'date': DateTime.now().toIso8601String(),
    }),
  );
  void _notify(
    Map<String, dynamic> data,
    String message, {
    String email = '',
    String order = '',
  }) => _put(
    data,
    'notifications',
    AdminRecord(_id(), {
      'name': message,
      'email': email,
      'order': order,
      'date': DateTime.now().toIso8601String(),
      'read': false,
    }),
  );
  Future<bool> _commit(Map<String, dynamic> candidate) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (!await persist(candidate)) {
        error = 'Changes were not saved. Please retry.';
        return false;
      }
      _data = candidate;
      return true;
    } catch (_) {
      error = 'Changes were not saved. Please retry.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  bool _fail(String message) {
    error = message;
    notifyListeners();
    return false;
  }

  Future<bool> save(
    String section,
    Map<String, dynamic> values, {
    String? id,
  }) async {
    if (busy || !canWrite(section)) {
      return _fail('Your role cannot change this section.');
    }
    if (section == 'orders') return saveManualOrder(values, id: id);
    final schema = sectionFor(section);
    for (final field in schema.fields) {
      final value = '${values[field.key] ?? ''}'.trim();
      if (field.required && value.isEmpty) {
        return _fail('${field.label} is required.');
      }
      if (value.isNotEmpty &&
          ['number', 'integer', 'signed'].contains(field.type)) {
        final number = double.tryParse(value);
        if (number == null ||
            !number.isFinite ||
            field.type != 'signed' && number < 0 ||
            field.type == 'integer' && number != number.roundToDouble()) {
          return _fail('Invalid ${field.label}.');
        }
      }
      if (field.options.isNotEmpty &&
          value.isNotEmpty &&
          !field.options.contains(value)) {
        return _fail('Invalid option for .');
      }
      if (field.reference != null &&
          value.isNotEmpty &&
          record(field.reference!, value) == null) {
        return _fail('Select an existing ${field.label}.');
      }
      if (field.type == 'date' &&
          value.isNotEmpty &&
          DateTime.tryParse(value) == null) {
        return _fail('Use YYYY-MM-DD for ${field.label}.');
      }
    }
    if (['settings', 'codes'].contains(section) &&
        (double.tryParse(
                  '${values[section == 'settings' ? 'tax' : 'percent']}',
                ) ??
                0) >
            100) {
      return _fail('Percentage cannot exceed 100.');
    }
    if (['settings', 'slots'].contains(section) &&
        (int.tryParse('${values['capacity']}') ?? 0) < 1) {
      return _fail('Capacity must be at least one.');
    }
    if (section == 'recipes' &&
        (double.tryParse('${values['amount']}') ?? 0) <= 0) {
      return _fail('Recipe amount must be positive.');
    }
    if (section == 'recipes' &&
        records(section).any(
          (r) =>
              r.id != id &&
              r.text('product') == values['product'] &&
              r.text('ingredient') == values['ingredient'],
        )) {
      return _fail(
        'That ingredient already has a recipe row for this cake. Edit it instead.',
      );
    }
    final clean = Map<String, dynamic>.from(values);
    if (section == 'codes') {
      clean['name'] = '${clean['name']}'.trim().toUpperCase();
      if (records(section)
          .any((r) => r.id != id && r.text('name') == clean['name'])) {
        return _fail('Code already exists.');
      }
    }
    if (section == 'customers') {
      clean['email'] = '${clean['email']}'.trim().toLowerCase();
    }
    if (section == 'staff') {
      final name = '${clean['username']}'.trim().toLowerCase();
      if (name == ownerUsername ||
          records('staff')
              .any((r) => r.id != id && r.text('username') == name)) {
        return _fail('Username already exists.');
      }
      final password = '${clean.remove('password') ?? ''}';
      if (id == null && password.length < 8 ||
          password.isNotEmpty && password.length < 8) {
        return _fail('Use at least 8 characters for the password.');
      }
      if (password.isNotEmpty) {
        busy = true;
        notifyListeners();
        try {
          clean['credential'] = (await LocalAccount.create(
            '${clean['name']}',
            name,
            password,
          )).toJson();
        } finally {
          busy = false;
        }
      } else {
        clean['credential'] = record(section, id!)!.values['credential'];
      }
      clean['username'] = name;
    }
    final candidate = toJson();
    final row = AdminRecord(
      section == 'settings' ? 'store' : id ?? _id(),
      clean,
    );
    _put(candidate, section, row);
    _log(
      candidate,
      id == null ? 'Created $section' : 'Edited $section',
      row.id,
    );
    if (section == 'ingredients' &&
        row.number('stock') <= row.number('minimum')) {
      _notify(candidate, 'Low stock: ${row.text('name')}');
    }
    if (section == 'requests' || section == 'reviews') {
      _notify(
        candidate,
        'Your ${section == 'requests' ? 'custom request' : 'feedback'} was updated.',
        email: row.text('email'),
      );
    }
    return await _commit(candidate);
  }

  Future<bool> delete(String section, String id) async {
    if (busy ||
        !canWrite(section) ||
        ['orders', 'settings'].contains(section)) {
      return _fail('This record cannot be deleted.');
    }
    if (section == 'ingredients' &&
        records(
          'orders',
        ).any((o) => (o.values['allocations'] as Map? ?? {}).containsKey(id))) {
      return _fail(
        'This ingredient is referenced by order history. Keep its stock record.',
      );
    }
    for (final schema in adminSections) {
      for (final field in schema.fields.where((f) => f.reference == section)) {
        if (records(schema.key).any((r) => r.text(field.key) == id)) {
          return _fail('Used in ${schema.title}. Remove that reference first.');
        }
      }
    }
    final candidate = toJson();
    final row = record(section, id);
    if (row == null) return false;
    _put(candidate, section, row.patch({'deleted': true}));
    _log(candidate, 'Deleted $section', id);
    return await _commit(candidate);
  }

  Map<String, double> _allocations(List<Map<String, dynamic>> items) {
    final amounts = <String, double>{};
    for (final item in items) {
      for (final recipe in records(
        'recipes',
      ).where((r) => r.text('product') == item['product'])) {
        amounts.update(
          recipe.text('ingredient'),
          (n) => n + recipe.number('amount') * (item['quantity'] as num),
          ifAbsent: () => recipe.number('amount') * (item['quantity'] as num),
        );
      }
    }
    return amounts;
  }

  void _adjustStock(
    Map<String, dynamic> data,
    Map<String, double> allocations,
    double sign,
  ) {
    for (final entry in allocations.entries) {
      final ingredient = _rows(
        data,
        'ingredients',
      ).firstWhere((r) => r.id == entry.key);
      final next = ingredient.number('stock') + entry.value * sign;
      if (next < -0.000001) {
        throw StateError('Not enough ${ingredient.text('name')} in stock.');
      }
      _put(
        data,
        'ingredients',
        ingredient.patch({'stock': next < 0 ? 0 : next}),
      );
      if (sign < 0 && next <= ingredient.number('minimum')) {
        _notify(data, 'Low stock: ${ingredient.text('name')}');
      }
    }
  }

  double discountFor(String code, double subtotal, String email) {
    for (final discount in records('codes')) {
      if (discount.text('name') == code.trim().toUpperCase() &&
          discount.flag('active') &&
          subtotal >= discount.number('minimum') &&
          (discount.text('expires').isEmpty ||
              discount.text('expires').compareTo(today) >= 0)) {
        final points = records('customers')
            .where((r) => r.text('email') == email)
            .fold<double>(0, (n, r) => n + r.number('points'));
        if (points >= discount.number('points')) {
          return subtotal * discount.number('percent') / 100;
        }
      }
    }
    return 0;
  }

  double feeFor(String fulfilment, String zone) =>
      fulfilment == 'delivery' ? record('zones', zone)?.number('fee') ?? 0 : 0;
  void _validateBooking(
    Map<String, dynamic> data,
    String date,
    String slot,
    String fulfilment,
    String zone, {
    String? exclude,
  }) {
    if (DateTime.tryParse(date) == null ||
        dayKey(DateTime.parse(date)) != date ||
        date.compareTo(today) < 0) {
      throw StateError('Select today or a future fulfilment date.');
    }
    final orders = _rows(data, 'orders').where(
      (r) =>
          r.id != exclude &&
          r.text('status') != 'cancelled' &&
          r.text('date') == date,
    );
    if (orders.length >= settings.number('capacity')) {
      throw StateError('Daily production capacity is full.');
    }
    final openSlots = records('slots')
        .where((r) => r.flag('active') && r.text('date') == date)
        .toList();
    if (openSlots.isNotEmpty && slot.isEmpty) {
      throw StateError('Select a time slot.');
    }
    if (slot.isNotEmpty) {
      final selected = record('slots', slot);
      if (selected == null ||
          !selected.flag('active') ||
          selected.text('date') != date) {
        throw StateError('This time slot is not available on that date.');
      }
      if (orders.where((r) => r.text('slot') == slot).length >=
          selected.number('capacity')) {
        throw StateError('This time slot is full.');
      }
    }
    if (fulfilment == 'delivery' &&
        (record('zones', zone)?.flag('active') != true)) {
      throw StateError('Select an active delivery zone.');
    }
  }

  Future<bool> saveManualOrder(
    Map<String, dynamic> values, {
    String? id,
  }) async {
    if (busy || !canWrite('orders')) {
      return _fail('Your role cannot create or edit orders.');
    }
    if (values['paymentStatus'] == 'paid' && !canFinance) {
      return _fail('Only owner or manager can record a paid order.');
    }
    if (!['pending', 'paid'].contains(values['paymentStatus']) ||
        !['cash', 'card', 'online transfer'].contains(values['payment']) ||
        !['pickup', 'delivery'].contains(values['fulfilment'])) {
      return _fail('Select valid payment and fulfilment options.');
    }
    final old = id == null ? null : record('orders', id);
    if (old != null &&
        (old.text('status') != 'pending' ||
            old.text('paymentStatus') != 'pending')) {
      return _fail(
        'Only unpaid pending orders can be edited. Cancel/refund other orders.',
      );
    }
    if (old != null && old.text('source') != 'manual') {
      return _fail(
        'Customer order items are fixed; edit fulfilment using the order controls.',
      );
    }
    final product = record('products', '${values['product']}');
    final quantity = int.tryParse('${values['quantity']}') ?? 0;
    if (product == null ||
        !product.flag('available') ||
        quantity < 1 ||
        '${values['customer'] ?? ''}'.trim().isEmpty) {
      return _fail(
        'Choose an available cake, a positive quantity and a customer.',
      );
    }
    final variantId = '${values['variant'] ?? ''}';
    final variant = record('variants', variantId);
    if (variantId.isNotEmpty &&
        (variant == null || variant.text('product') != product.id)) {
      return _fail('Variant must belong to the selected cake.');
    }
    final price =
        product.number('price') + (variant?.number('adjustment') ?? 0);
    if (price < 0) return _fail('Variant price cannot be negative.');
    final item = {
      'product': product.id,
      'name': product.text('name'),
      'quantity': quantity,
      'price': price,
      'details': variant?.text('name') ?? '',
      'photo': 0,
      'photoData': product.text('photoData'),
    };
    return _createOrder(
      {
        ...values,
        'source': 'manual',
        'items': [item],
      },
      id: id,
      old: old,
    );
  }

  Future<bool> _createOrder(
    Map<String, dynamic> values, {
    String? id,
    AdminRecord? old,
    String? customerActor,
  }) async {
    final candidate = toJson();
    try {
      final date = '${values['date']}';
      final slot = '${values['slot'] ?? ''}';
      final fulfilment = '${values['fulfilment'] ?? 'pickup'}';
      final zone = '${values['zone'] ?? ''}';
      _validateBooking(candidate, date, slot, fulfilment, zone, exclude: id);
      if (fulfilment == 'delivery' &&
          '${values['address'] ?? ''}'.trim().length < 10) {
        throw StateError('Enter a full delivery address.');
      }
      final driver = '${values['driver'] ?? ''}';
      if (driver.isNotEmpty &&
          record('drivers', driver)?.flag('active') != true) {
        throw StateError('Select an available driver.');
      }
      final items = (values['items'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (old != null) {
        _adjustStock(
          candidate,
          Map<String, dynamic>.from(old.values['allocations'] as Map? ?? {})
              .map((k, v) => MapEntry(k, (v as num).toDouble())),
          1,
        );
      }
      final allocations = _allocations(items);
      _adjustStock(candidate, allocations, -1);
      final subtotal = items.fold<double>(
        0,
        (n, i) => n + (i['price'] as num) * (i['quantity'] as num),
      );
      final discount = discountFor(
        '${values['code'] ?? ''}',
        subtotal,
        '${values['email'] ?? ''}',
      );
      final fee = feeFor(fulfilment, zone);
      final tax = (subtotal - discount + fee) * settings.number('tax') / 100;
      final total = double.parse(
        (subtotal - discount + fee + tax).toStringAsFixed(2),
      );
      final order = AdminRecord(id ?? 'SS-${_id()}', {
        ...values,
        'status': 'pending',
        'createdAt': old?.text('createdAt') ?? DateTime.now().toIso8601String(),
        'date': date,
        'slot': slot,
        'fulfilment': fulfilment,
        'zone': zone,
        'subtotal': subtotal,
        'discount': discount,
        'fee': fee,
        'taxRate': settings.number('tax'),
        'taxAmount': tax,
        'total': total,
        'refunded': 0,
        'paymentStatus': values['paymentStatus'] ?? 'pending',
        'allocations': allocations,
      });
      _put(candidate, 'orders', order);
      if (order.text('paymentStatus') == 'paid') {
        _put(
          candidate,
          'payments',
          AdminRecord(_id(), {
            'name': 'Payment',
            'order': order.id,
            'amount': total,
            'reference': 'Manual receipt ${order.id}',
            'method': order.text('payment'),
            'actor': username,
            'date': DateTime.now().toIso8601String(),
          }),
        );
      }
      _log(
        candidate,
        old == null ? 'Created order' : 'Edited order',
        order.id,
        actor: customerActor,
      );
      _notify(candidate, 'New order ${order.id}');
      _notify(
        candidate,
        'Order ${order.id} is pending.',
        email: order.text('email'),
        order: order.id,
      );
      final customerEmail = order.text('email').trim().toLowerCase();
      if (customerEmail.isNotEmpty) {
        final existing = records('customers')
            .where((c) => c.text('email') == customerEmail)
            .firstOrNull;
        _put(
          candidate,
          'customers',
          AdminRecord(existing?.id ?? customerEmail, {
            ...?existing?.values,
            'name': order.text('customer'),
            'email': customerEmail,
            'phone': order.text('phone'),
            'address': order.text('address'),
            'points': existing?.number('points') ?? 0,
          }),
        );
      }
      return await _commit(candidate);
    } on StateError catch (e) {
      return _fail(e.message);
    }
  }

  /// Called by the authenticated customer checkout, not by the admin editor.
  Future<bool> customerOrder(Map<String, dynamic> values) async {
    if (busy || '${values['email'] ?? ''}'.isEmpty) return false;
    final items = (values['items'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    for (final item in items) {
      if ('${item['product']}'.startsWith('custom-')) continue;
      final product = record('products', '${item['product']}');
      if (product == null || !product.flag('available')) {
        return _fail('${item['name']} is no longer available.');
      }
      final quantity = item['quantity'];
      if (quantity is! num ||
          quantity <= 0 ||
          quantity != quantity.roundToDouble()) {
        return _fail('Invalid quantity.');
      }
      final variantId = '${item['variantId'] ?? ''}';
      final variant = record('variants', variantId);
      if (variantId.isNotEmpty &&
          (variant == null || variant.text('product') != product.id)) {
        return _fail(
          'A cake option changed. Remove the cake and add it again.',
        );
      }
      final price =
          product.number('price') + (variant?.number('adjustment') ?? 0);
      final cartPrice = item['price'];
      if (price < 0 || cartPrice is! num || (cartPrice - price).abs() > .001) {
        return _fail('A cake price changed. Remove the cake and add it again.');
      }
    }
    return _createOrder({
      ...values,
      'items': items,
      'source': 'online',
      'paymentStatus': 'pending',
    }, customerActor: '${values['email']}');
  }

  Future<bool> updateStatus(String id, String status) async {
    if (busy || !canChangeStatus) return _fail('Please sign in as staff.');
    final order = record('orders', id);
    if (order == null) return false;
    final current = order.text('status');
    final next = {'pending': 'baking', 'baking': 'ready', 'ready': 'delivered'};
    if (next[current] != status) {
      return _fail('Status must follow pending → baking → ready → delivered.');
    }
    if (role == 'baker' && status == 'delivered') {
      return _fail('Only front-of-house staff can mark delivered.');
    }
    final candidate = toJson();
    _put(candidate, 'orders', order.patch({'status': status}));
    if (status == 'delivered') {
      final customer = records('customers')
          .where((c) => c.text('email') == order.text('email'))
          .firstOrNull;
      if (customer != null) {
        _put(
          candidate,
          'customers',
          customer.patch({
            'points': customer.number('points') + order.number('total').floor(),
          }),
        );
      }
    }
    _log(candidate, 'Status → $status', id);
    _notify(
      candidate,
      'Order $id is $status.',
      email: order.text('email'),
      order: id,
    );
    return await _commit(candidate);
  }

  Future<bool> cancelOrder(String id, String reason) async {
    if (busy || !canWrite('orders') || reason.trim().isEmpty) {
      return _fail('Enter a cancellation reason.');
    }
    final order = record('orders', id);
    if (order == null ||
        ['cancelled', 'delivered'].contains(order.text('status'))) {
      return _fail('This order cannot be cancelled.');
    }
    final candidate = toJson();
    if (order.text('status') == 'pending') {
      _adjustStock(
        candidate,
        Map<String, dynamic>.from(order.values['allocations'] as Map? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        1,
      );
    }
    _put(
      candidate,
      'orders',
      order.patch({
        'status': 'cancelled',
        'cancellation': reason,
        'paymentStatus': order.text('paymentStatus') == 'paid'
            ? 'refund pending'
            : order.text('paymentStatus'),
      }),
    );
    _log(candidate, 'Cancelled: $reason', id);
    _notify(
      candidate,
      'Order $id was cancelled: $reason',
      email: order.text('email'),
      order: id,
    );
    return await _commit(candidate);
  }

  Future<bool> paymentAction(
    String id, {
    bool refund = false,
    String reference = '',
    double? amount,
  }) async {
    if (busy || !canFinance) {
      return _fail('Only owner or manager can record payments/refunds.');
    }
    final order = record('orders', id);
    if (order == null) return false;
    if (reference.trim().isEmpty) {
      return _fail('Enter a payment/refund reference.');
    }
    if (!refund &&
        (order.text('paymentStatus') != 'pending' ||
            order.text('status') == 'cancelled')) {
      return _fail('Payment already recorded or order cancelled.');
    }
    if (refund &&
        (![
              'paid',
              'refund pending',
              'partially refunded',
            ].contains(order.text('paymentStatus')) ||
            amount == null ||
            amount <= 0 ||
            amount > order.number('total') - order.number('refunded'))) {
      return _fail(
        'Refund must be positive and no more than the remaining paid amount.',
      );
    }
    final candidate = toJson();
    final refunded = order.number('refunded') + (refund ? amount! : 0);
    _put(
      candidate,
      'orders',
      order.patch({
        'paymentStatus': refund
            ? refunded >= order.number('total')
                  ? 'refunded'
                  : 'partially refunded'
            : 'paid',
        'refunded': refunded,
      }),
    );
    _put(
      candidate,
      'payments',
      AdminRecord(_id(), {
        'name': refund ? 'Refund' : 'Payment',
        'order': id,
        'amount': refund ? amount : order.number('total'),
        'reference': reference,
        'method': order.text('payment'),
        'actor': username,
        'date': DateTime.now().toIso8601String(),
      }),
    );
    _log(candidate, refund ? 'Recorded refund' : 'Recorded payment', id);
    _notify(
      candidate,
      refund ? 'Refund recorded for $id.' : 'Payment recorded for $id.',
      email: order.text('email'),
      order: id,
    );
    return await _commit(candidate);
  }

  Future<bool> assignDelivery(
    String id,
    String driver,
    String date,
    String slot,
  ) async {
    if (busy || !canWrite('orders')) {
      return _fail('Your role cannot schedule orders.');
    }
    final order = record('orders', id);
    if (order == null ||
        ['cancelled', 'delivered'].contains(order.text('status'))) {
      return _fail('This order is closed.');
    }
    if (driver.isNotEmpty &&
        record('drivers', driver)?.flag('active') != true) {
      return _fail('Driver is not available.');
    }
    try {
      _validateBooking(
        _data,
        date,
        slot,
        order.text('fulfilment'),
        order.text('zone'),
        exclude: id,
      );
    } on StateError catch (e) {
      return _fail(e.message);
    }
    final candidate = toJson();
    _put(
      candidate,
      'orders',
      order.patch({'driver': driver, 'date': date, 'slot': slot}),
    );
    _log(candidate, 'Updated schedule / driver', id);
    _notify(
      candidate,
      'Delivery/pickup schedule updated for $id: $date.',
      email: order.text('email'),
      order: id,
    );
    return await _commit(candidate);
  }

  List<AdminRecord> get alerts => [
    ...records('notifications')
        .where((r) => r.text('email').isEmpty && !r.flag('read')),
    ...records('ingredients')
        .where((r) => r.number('stock') <= r.number('minimum'))
        .map(
          (r) => AdminRecord('low-${r.id}', {
            'name':
                'Low stock: ${r.text('name')} (${r.text('stock')} ${r.text('unit')})',
          }),
        ),
    ...records('orders')
        .where(
          (r) =>
              r
                      .text('date')
                      .compareTo(
                        dayKey(DateTime.now().add(const Duration(days: 1))),
                      ) <=
                  0 &&
              !['cancelled', 'delivered'].contains(r.text('status')),
        )
        .map(
          (r) => AdminRecord('due-${r.id}', {
            'name': 'Due ${r.text('date')}: ${r.id} · ${r.text('customer')}',
          }),
        ),
  ];
  Future<void> markRead(String id, {String? customerEmail}) async {
    if (busy) return;
    final note = record('notifications', id);
    if (note == null) return;
    if (customerEmail == null && !signedIn ||
        customerEmail != null && note.text('email') != customerEmail) {
      return;
    }
    final candidate = toJson();
    _put(candidate, 'notifications', note.patch({'read': true}));
    await _commit(candidate);
  }

  Future<bool> customerRequest(
    String email,
    String name,
    Map<String, dynamic> values,
  ) async {
    if (busy ||
        email.isEmpty ||
        '${values['design'] ?? ''}'.trim().isEmpty ||
        DateTime.tryParse('${values['date']}') == null) {
      return _fail('Enter a design brief and valid date.');
    }
    final candidate = toJson();
    final id = _id();
    _put(
      candidate,
      'requests',
      AdminRecord(id, {
        ...values,
        'customer': name,
        'email': email,
        'status': 'pending',
        'quote': 0,
      }),
    );
    _notify(candidate, 'New custom cake request from $name');
    _log(candidate, 'Submitted custom request', id, actor: email);
    return await _commit(candidate);
  }

  Future<bool> customerReview(
    String email,
    String name,
    String orderId,
    int rating,
    String comment,
  ) async {
    final order = record('orders', orderId);
    if (busy ||
        order?.text('email') != email ||
        order?.text('status') != 'delivered' ||
        rating < 1 ||
        rating > 5 ||
        comment.trim().isEmpty) {
      return _fail('Feedback requires a delivered order, rating and comment.');
    }
    if (records('reviews')
        .any((r) => r.text('order') == orderId && r.text('email') == email)) {
      return _fail('You already reviewed this order.');
    }
    final candidate = toJson();
    _put(
      candidate,
      'reviews',
      AdminRecord(_id(), {
        'email': email,
        'customer': name,
        'order': orderId,
        'rating': rating,
        'comment': comment,
      }),
    );
    _notify(candidate, 'New review from $name');
    return await _commit(candidate);
  }

  Future<bool> syncCustomer(
    String email,
    String name,
    String address,
    String phone,
  ) async {
    if (busy || email.isEmpty) return false;
    final existing = records('customers')
        .where((r) => r.text('email') == email)
        .firstOrNull;
    final candidate = toJson();
    _put(
      candidate,
      'customers',
      AdminRecord(existing?.id ?? email, {
        ...?existing?.values,
        'email': email,
        'name': name,
        'address': address,
        'phone': phone,
        'points': existing?.number('points') ?? 0,
      }),
    );
    return await _commit(candidate);
  }

  String receipt(AdminRecord order) {
    final items = (order.values['items'] as List? ?? []).map(
      (e) => Map<String, dynamic>.from(e as Map),
    );
    return '${settings.text('name')}\n${settings.text('address')}\nTax ID: ${settings.text('taxId')}\n\nINVOICE / RECEIPT ${order.id}\nCreated: ${order.text('createdAt')}\nCustomer: ${order.text('customer')}\n${order.text('email')}\n${order.text('address')}\n\n${items.map((i) => '${i['quantity']} × ${i['name']} @ \$${(i['price'] as num).toStringAsFixed(2)}').join('\n')}\n\nSubtotal: \$${order.number('subtotal').toStringAsFixed(2)}\nDiscount: \$${order.number('discount').toStringAsFixed(2)}\nDelivery: \$${order.number('fee').toStringAsFixed(2)}\nTax (${order.text('taxRate')}%): \$${order.number('taxAmount').toStringAsFixed(2)}\nTotal: \$${order.number('total').toStringAsFixed(2)}\nPayment: ${order.text('payment')} / ${order.text('paymentStatus')}\nRefunded: \$${order.number('refunded').toStringAsFixed(2)}\n\nLocal record. No payment is processed by this app.';
  }
}
