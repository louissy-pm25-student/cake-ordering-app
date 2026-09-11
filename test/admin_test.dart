import 'package:flutter_test/flutter_test.dart';
import 'package:cake_ordering_app/viewmodel/admin/admin_viewmodel.dart';
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
  expect(
    await vm.save('ingredients', {
      'name': 'Flour',
      'unit': 'g',
      'stock': 1000,
      'minimum': 100,
      'cost': .01,
    }, id: 'flour'),
    true,
  );
  expect(
    await vm.save('recipes', {
      'product': 'cake',
      'ingredient': 'flour',
      'amount': 200,
    }, id: 'recipe'),
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
  test('manual create/edit/cancel deducts and restores stock once', () async {
    final vm = await setupAdmin();
    expect(await vm.saveManualOrder(manual(vm)), true);
    final id = vm.records('orders').single.id;
    expect(vm.record('ingredients', 'flour')!.number('stock'), 800);
    expect(await vm.saveManualOrder(manual(vm, quantity: 2), id: id), true);
    expect(vm.record('ingredients', 'flour')!.number('stock'), 600);
    expect(await vm.cancelOrder(id, 'Customer changed plans'), true);
    expect(vm.record('ingredients', 'flour')!.number('stock'), 1000);
    expect(await vm.cancelOrder(id, 'Again'), false);
    expect(await vm.saveManualOrder(manual(vm, quantity: 6)), false);
    expect(vm.record('ingredients', 'flour')!.number('stock'), 1000);
  });
  test(
    'capacity, tax, zone fees, status transitions, payments and refunds',
    () async {
      final vm = await setupAdmin();
      await vm.save('settings', {
        'name': 'Test shop',
        'tax': 10,
        'capacity': 2,
      });
      await vm.save('zones', {
        'name': 'Local',
        'fee': 5,
        'active': true,
      }, id: 'zone');
      await vm.save('slots', {
        'name': '10:00–12:00',
        'date': vm.today,
        'capacity': 1,
        'active': true,
      }, id: 'morning');
      final order = {
        ...manual(vm),
        'fulfilment': 'delivery',
        'zone': 'zone',
        'slot': 'morning',
      };
      expect(await vm.saveManualOrder(order), true);
      final row = vm.records('orders').single;
      expect(row.number('total'), 49.5);
      expect(await vm.saveManualOrder(order), false);
      expect(await vm.updateStatus(row.id, 'delivered'), false);
      expect(await vm.paymentAction(row.id, reference: 'CASH-1'), true);
      expect(await vm.paymentAction(row.id, reference: 'duplicate'), false);
      expect(await vm.cancelOrder(row.id, 'Refund requested'), true);
      expect(
        vm.record('orders', row.id)!.text('paymentStatus'),
        'refund pending',
      );
      expect(
        await vm.paymentAction(
          row.id,
          refund: true,
          amount: 50,
          reference: 'bad',
        ),
        false,
      );
      expect(
        await vm.paymentAction(
          row.id,
          refund: true,
          amount: 20,
          reference: 'REF-1',
        ),
        true,
      );
      expect(
        await vm.paymentAction(
          row.id,
          refund: true,
          amount: 29.5,
          reference: 'REF-2',
        ),
        true,
      );
      expect(vm.record('orders', row.id)!.text('paymentStatus'), 'refunded');
      expect(vm.records('payments').length, 3);
      expect(vm.receipt(vm.record('orders', row.id)!), contains('Tax (10.0%)'));
      expect(
        vm
            .records('notifications')
            .where((r) => r.text('email') == 'alice@example.com'),
        isNotEmpty,
      );
    },
  );
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
      expect(vm.canRead('finance'), false);
      expect(vm.canWrite('products'), false);
      expect(await vm.save('products', {'name': 'Illegal'}), false);
      expect(await vm.paymentAction(id, reference: 'BAD'), false);
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
  test('failed persistence leaves records and inventory unchanged', () async {
    bool fail = false;
    final vm = await setupAdmin(persist: (_) async => !fail);
    fail = true;
    expect(await vm.saveManualOrder(manual(vm)), false);
    expect(vm.records('orders'), isEmpty);
    expect(vm.record('ingredients', 'flour')!.number('stock'), 1000);
  });
}
