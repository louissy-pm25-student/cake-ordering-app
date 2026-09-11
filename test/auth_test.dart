import 'fixtures.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_ordering_app/data/local_cake_repository.dart';
import 'package:cake_ordering_app/viewmodel/cake_viewmodel.dart';
import 'package:cake_ordering_app/nav/cake_destination.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'guest gates, deferred add, invalid login, isolated accounts and logout',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final vm = CakeViewModel(LocalCakeRepository(prefs));
      await vm.load();
      await seedMenu(vm);
      expect(vm.destination, CakeDestination.home);
      vm.navigate(CakeDestination.menu);
      for (final page in [
        CakeDestination.customize,
        CakeDestination.orders,
        CakeDestination.profile,
        CakeDestination.checkout,
      ]) {
        vm.navigate(page);
        expect(vm.destination, CakeDestination.login);
        vm.cancelLogin();
        expect(vm.destination, CakeDestination.menu);
      }
      vm.addCake(vm.cakes.first);
      expect(vm.cart, isEmpty);
      expect(vm.destination, CakeDestination.login);
      await vm.authenticate(
        email: 'a@example.com',
        password: 'Password123',
        name: 'Alice',
      );
      expect(vm.cartCount, 1);
      expect(vm.destination, CakeDestination.checkout);
      await vm.logout();
      expect(vm.isLoggedIn, false);
      expect(vm.cart, isEmpty);
      vm.navigate(CakeDestination.orders);
      await vm.authenticate(email: 'a@example.com', password: 'wrong');
      expect(vm.isLoggedIn, false);
      expect(vm.authError, isNotNull);
      await vm.authenticate(email: 'A@EXAMPLE.COM', password: 'Password123');
      expect(vm.destination, CakeDestination.orders);
      expect(vm.cartCount, 1);
      await vm.logout();
      await vm.authenticate(
        email: 'b@example.com',
        password: 'Password123',
        name: 'Bob',
      );
      expect(vm.cart, isEmpty);
      expect(vm.orders, isEmpty);
      expect(vm.profile.name, 'Bob');
      await vm.logout();
      await vm.authenticate(
        email: 'a@example.com',
        password: 'Password123',
        name: 'Duplicate',
      );
      expect(vm.isLoggedIn, false);
      expect(vm.authError, contains('already registered'));
      expect(
        prefs.getString('sweet_studio_flutter_v1'),
        isNot(contains('Password123')),
      );
      final reopened = CakeViewModel(LocalCakeRepository(prefs));
      await reopened.load();
      expect(reopened.isLoggedIn, false);
      expect(reopened.cart, isEmpty);
    },
  );
}
