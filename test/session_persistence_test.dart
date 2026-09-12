import 'package:cake_ordering_app/data/local_cake_repository.dart';
import 'package:cake_ordering_app/model/auth_verification.dart';
import 'package:cake_ordering_app/nav/cake_destination.dart';
import 'package:cake_ordering_app/viewmodel/cake_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Malaysian mobile numbers normalize and reject other countries', () {
    expect(normalizeMalaysiaMobile('012-345 6789'), '+60123456789');
    expect(normalizeMalaysiaMobile('+60 11-2345 6789'), '+601123456789');
    expect(normalizeMalaysiaMobile('+65 8123 4567'), isNull);
    expect(normalizeMalaysiaMobile('0323456789'), isNull);
  });

  test('customer and admin sessions restore until explicit logout', () async {
    final prefs = await SharedPreferences.getInstance();
    var vm = CakeViewModel(LocalCakeRepository(prefs));
    await vm.load();
    await vm.authenticate(
      email: 'alice@example.com',
      password: 'Password123',
      name: 'Alice',
    );
    expect(vm.isLoggedIn, true);

    vm = CakeViewModel(LocalCakeRepository(prefs));
    await vm.load();
    expect(vm.isLoggedIn, true);
    expect(vm.email, 'alice@example.com');
    expect(vm.destination, CakeDestination.home);
    await vm.logout();

    vm = CakeViewModel(LocalCakeRepository(prefs));
    await vm.load();
    expect(vm.isLoggedIn, false);
    await vm.authenticate(email: 'admin', password: 'admin123');
    expect(vm.isAdmin, true);

    vm = CakeViewModel(LocalCakeRepository(prefs));
    await vm.load();
    expect(vm.isAdmin, true);
    expect(vm.admin.username, 'admin');
    expect(vm.destination, CakeDestination.admin);
    await vm.exitAdmin();

    vm = CakeViewModel(LocalCakeRepository(prefs));
    await vm.load();
    expect(vm.isAdmin, false);
    expect(vm.destination, CakeDestination.home);
  });
}
