import 'package:flutter_test/flutter_test.dart';
import 'package:cake_ordering_app/viewmodel/admin/admin_viewmodel.dart';

void main() {
  test('owner credentials persist and old credentials stop working', () async {
    Map<String, dynamic> stored = {};
    final vm = AdminViewModel((data) async {
      stored = data;
      return true;
    });
    vm.load({});
    expect(await vm.login('admin', 'admin123'), isTrue);
    expect(
      await vm.updateProfile(
        newUsername: 'bakery_owner',
        currentPassword: 'wrong',
        newPassword: 'NewPassword123',
        confirmPassword: 'NewPassword123',
      ),
      isFalse,
    );
    expect(vm.username, 'admin');
    expect(
      await vm.updateProfile(
        newUsername: 'bakery_owner',
        currentPassword: 'admin123',
        newPassword: 'NewPassword123',
        confirmPassword: 'different',
      ),
      isFalse,
    );
    expect(
      await vm.updateProfile(
        newUsername: 'bakery_owner',
        currentPassword: 'admin123',
        newPassword: 'NewPassword123',
        confirmPassword: 'NewPassword123',
      ),
      isTrue,
    );
    expect(vm.username, 'bakery_owner');
    expect(stored.toString(), isNot(contains('NewPassword123')));
    final reopened = AdminViewModel((_) async => true)..load(stored);
    expect(reopened.hasUsername('bakery_owner'), isTrue);
    expect(await reopened.login('admin', 'admin123'), isFalse);
    expect(await reopened.login('bakery_owner', 'admin123'), isFalse);
    expect(await reopened.login('bakery_owner', 'NewPassword123'), isTrue);
    expect(reopened.role, 'owner');
  });

  test(
    'profile rejects collisions and failed persistence keeps old login',
    () async {
      bool fail = false;
      final vm = AdminViewModel((_) async => !fail)..load({});
      await vm.login('admin', 'admin123');
      expect(
        await vm.save('staff', {
          'name': 'Baker',
          'username': 'baker',
          'password': 'Baker1234',
          'role': 'baker',
          'active': true,
        }),
        isTrue,
      );
      expect(
        await vm.updateProfile(
          newUsername: 'baker',
          currentPassword: 'admin123',
          newPassword: '',
          confirmPassword: '',
        ),
        isFalse,
      );
      fail = true;
      expect(
        await vm.updateProfile(
          newUsername: 'newadmin',
          currentPassword: 'admin123',
          newPassword: '',
          confirmPassword: '',
        ),
        isFalse,
      );
      expect(vm.username, 'admin');
      vm.logout();
      expect(await vm.login('admin', 'admin123'), isTrue);
      vm.logout();
      fail = false;
      expect(await vm.login('baker', 'Baker1234'), isTrue);
      expect(vm.canRead('profile'), isTrue);
      expect(
        await vm.updateProfile(
          newUsername: 'admin',
          currentPassword: 'Baker1234',
          newPassword: '',
          confirmPassword: '',
        ),
        isFalse,
      );
      expect(
        await vm.updateProfile(
          newUsername: 'headbaker',
          currentPassword: 'Baker1234',
          newPassword: '',
          confirmPassword: '',
        ),
        isTrue,
      );
      vm.logout();
      expect(await vm.login('baker', 'Baker1234'), isFalse);
      expect(await vm.login('headbaker', 'Baker1234'), isTrue);
      expect(vm.role, 'baker');
      expect(vm.canFinance, isFalse);
    },
  );
}
