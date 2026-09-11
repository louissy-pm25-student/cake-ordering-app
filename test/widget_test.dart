import 'fixtures.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_ordering_app/data/local_cake_repository.dart';
import 'package:cake_ordering_app/viewmodel/cake_viewmodel.dart';
import 'package:cake_ordering_app/model/cake_customization.dart';
import 'package:cake_ordering_app/nav/cake_destination.dart';
import 'package:cake_ordering_app/nav/cake_navigation.dart';
import 'package:cake_ordering_app/ui/cake_app.dart';

Future<CakeViewModel> createModel({bool existing = false}) async {
  final vm = CakeViewModel(
    LocalCakeRepository(await SharedPreferences.getInstance()),
  );
  await vm.load();
  if (!existing) await seedMenu(vm);
  await vm.authenticate(
    email: 'test@example.com',
    password: 'Password123',
    name: existing ? null : 'Test Baker',
  );
  return vm;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'checkout validates, discounts, saves once and survives reload',
    () async {
      final vm = await createModel();
      vm.addCake(vm.cakes.first);
      vm.addCake(vm.cakes.first);
      await vm.placeOrder();
      expect(vm.orders, isEmpty);
      vm.setAddress('123 Sweet Street, Cake City');
      vm.setPromo(' sweet10 ');
      vm.applyPromo();
      expect(vm.total, closeTo(52.2, .001));
      await Future.wait([vm.placeOrder(), vm.placeOrder()]);
      expect(vm.orders.length, 1);
      expect(vm.cart, isEmpty);
      final restored = await createModel(existing: true);
      expect(restored.orders.single.total, closeTo(52.2, .001));
      expect(restored.profile.address, '123 Sweet Street, Cake City');
    },
  );
  test('custom pricing, quantity removal and navigation rules', () async {
    final vm = await createModel();
    vm.setCustom(const CakeCustomization(flavor: 'Chocolate', size: '8 inch'));
    expect(vm.customPrice, 57);
    vm.addCustomCake();
    expect(vm.destination, CakeDestination.checkout);
    vm.goBack();
    expect(vm.destination, CakeDestination.menu);
    vm.changeQuantity(vm.cart.single.id, -1);
    expect(vm.canPlaceOrder, false);
    expect(CakeNavigation.backDestination(CakeDestination.home), isNull);
  });
  testWidgets('menu search, custom checkout and order confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = (await tester.runAsync(createModel))!;
    await tester.pumpWidget(CakeApp(viewModel: vm));
    await tester.pumpAndSettle();
    expect(find.text('SWEET STUDIO'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'nothing');
    await tester.pumpAndSettle();
    expect(find.text('No cakes found'), findsOneWidget);
    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chocolate'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('8 inch'));
    await tester.tap(find.text('8 inch'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Add to order · \$57.00'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Add to order · \$57.00'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full delivery address'),
      '123 Sweet Street, Cake City',
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Place demo order · \$57.00'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Place demo order · \$57.00'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 200 && vm.busy; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    expect(vm.busy, false);
    await tester.pumpAndSettle();
    expect(find.text('Order confirmed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
