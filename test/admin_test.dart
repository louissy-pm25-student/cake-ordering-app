import 'package:flutter_test/flutter_test.dart';
import 'package:cake_ordering_app/viewmodel/admin/admin_viewmodel.dart';
import 'package:cake_ordering_app/model/admin/admin_schema.dart';
import 'package:cake_ordering_app/viewmodel/cake_viewmodel.dart';
import 'package:cake_ordering_app/data/local_cake_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AdminViewModel> setupAdmin({
  Future<bool> Function(Map<String, dynamic>)? persist,
}) async {
  final vm = AdminViewModel(persist ?? (_) async => true);
  vm.load({});
  expect(await vm.login('admin', 'wrong'), false);
  expect(await vm.login('admin', 'admin123'), true);
  expect(
    await vm.save('products', {
      'name': 'Test cake',
      'description': 'A birthday cake',
      'price': 40,
      'available': true,
      'category': 'Birthday',
    }, id: 'cake'),
    true,
  );
  return vm;
}

Map<String, dynamic> manual(AdminViewModel vm, {int quantity = 1}) => {
  'customer': 'Alice',
  'email': 'alice@example.com',
  'address': '123 Sweet Street',
  'product': 'cake',
  'quantity': quantity,
  'date': vm.today,
  'fulfilment': 'pickup',
  'payment': 'cash',
  'paymentStatus': 'pending',
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('removed admin modules are absent from the form registry', () {
    final keys = adminSections.map((section) => section.key);
    for (final removed in [
      'ingredients',
      'recipes',
      'suppliers',
      'slots',
      'settings',
    ]) {
      expect(keys, isNot(contains(removed)));
    }
  });
  test('manual orders can be created, edited and cancelled', () async {
    final vm = await setupAdmin();
    expect(await vm.saveManualOrder(manual(vm)), true);
    final id = vm.records('orders').single.id;
    expect(await vm.saveManualOrder(manual(vm, quantity: 2), id: id), true);
    expect(vm.record('orders', id)!.number('subtotal'), 80);
    expect(await vm.cancelOrder(id, 'Customer changed plans'), true);
    expect(await vm.cancelOrder(id, 'Again'), false);
  });
  test('orders use delivery fees without capacity, time slot, tax or payment reports', () async {
    final vm = await setupAdmin();
    await vm.save('zones', {
      'name': 'Local',
      'fee': 5,
      'active': true,
    }, id: 'zone');
    final order = {...manual(vm), 'fulfilment': 'delivery', 'zone': 'zone'};
    expect(await vm.saveManualOrder(order), true);
    final row = vm.records('orders').single;
    expect(row.number('total'), 45);
    expect(row.number('taxAmount'), 0);
    expect(await vm.saveManualOrder(order), true);
    expect(await vm.updateStatus(row.id, 'delivered'), false);
    expect(await vm.cancelOrder(row.id, 'Refund requested'), true);
    expect(
      vm
          .records('notifications')
          .where((r) => r.text('email') == 'alice@example.com'),
      isNotEmpty,
    );
  });
  test(
    'roles enforce writes and status limits, including direct API calls',
    () async {
      final vm = await setupAdmin();
      await vm.save('staff', {
        'name': 'Baker',
        'username': 'baker',
        'password': 'baker123',
        'role': 'baker',
        'active': true,
      });
      await vm.saveManualOrder(manual(vm));
      final id = vm.records('orders').single.id;
      vm.logout();
      expect(await vm.login('baker', 'baker123'), true);
      expect(vm.canWrite('products'), false);
      expect(await vm.save('products', {'name': 'Illegal'}), false);
      expect(await vm.updateStatus(id, 'baking'), true);
      expect(await vm.updateStatus(id, 'ready'), true);
      expect(await vm.updateStatus(id, 'delivered'), false);
      vm.logout();
      expect(await vm.updateStatus(id, 'delivered'), false);
    },
  );
  test(
    'customer order reaches admin and updates return to customer after reload',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final vm = CakeViewModel(LocalCakeRepository(prefs));
      await vm.load();
      expect(vm.cakes, isEmpty);
      await vm.authenticate(email: 'admin', password: 'admin123');
      expect(vm.isAdmin, true);
      await vm.admin.save('products', {
        'name': 'Berry cake',
        'description': 'Vanilla',
        'price': 29,
        'available': true,
      }, id: 'berry');
      vm.exitAdmin();
      await vm.authenticate(
        email: 'alice@example.com',
        password: 'Password123',
        name: 'Alice',
      );
      vm.addCake(vm.cakes.single);
      vm.setAddress('123 Sweet Street');
      await vm.placeOrder();
      expect(vm.orders.length, 1);
      final id = vm.orders.single.id;
      await vm.logout();
      await vm.authenticate(email: 'admin', password: 'admin123');
      expect(await vm.admin.updateStatus(id, 'baking'), true);
      vm.exitAdmin();
      await vm.authenticate(
        email: 'alice@example.com',
        password: 'Password123',
      );
      expect(vm.admin.record('orders', id)!.text('status'), 'baking');
      expect(
        vm.customerNotifications.any((n) => n.text('name').contains('baking')),
        true,
      );
      final reopened = CakeViewModel(LocalCakeRepository(prefs));
      await reopened.load();
      expect(reopened.admin.record('orders', id)!.text('status'), 'baking');
    },
  );
  test('failed persistence leaves order records unchanged', () async {
    bool fail = false;
    final vm = await setupAdmin(persist: (_) async => !fail);
    fail = true;
    expect(await vm.saveManualOrder(manual(vm)), false);
    expect(vm.records('orders'), isEmpty);
  });
}
