import 'package:cake_ordering_app/data/local_cake_repository.dart';
import 'package:cake_ordering_app/model/auth_verification.dart';
import 'package:cake_ordering_app/nav/cake_destination.dart';
import 'package:cake_ordering_app/viewmodel/cake_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('verified customer can log in by username and reset password', () async {
    final vm = CakeViewModel(
      LocalCakeRepository(await SharedPreferences.getInstance()),
    );
    await vm.load();

    expect(
      await vm.beginRegistration(
        name: 'Fake Admin',
        username: 'admin',
        email: 'fake@example.com',
        phone: '+60123456789',
        gender: 'Prefer not to say',
        password: 'Password123',
        confirmPassword: 'Password123',
        channel: VerificationChannel.email,
      ),
      false,
    );

    expect(
      await vm.beginRegistration(
        name: 'Alice Tan',
        username: 'alice',
        email: 'alice@example.com',
        phone: '+60123456789',
        gender: 'Female',
        password: 'Password123',
        confirmPassword: 'Password123',
        channel: VerificationChannel.sms,
      ),
      true,
    );
    final registrationCode = vm.verificationSession!.developmentCode!;
    expect(await vm.verifyAuthenticationCode('000000'), false);
    expect(await vm.verifyAuthenticationCode(registrationCode), true);
    expect(vm.destination, CakeDestination.login);

    await vm.authenticate(email: 'alice', password: 'Password123');
    expect(vm.isLoggedIn, true);
    await vm.logout();

    expect(
      await vm.beginPasswordReset(
        username: 'alice',
        channel: VerificationChannel.email,
      ),
      true,
    );
    final resetCode = vm.verificationSession!.developmentCode!;
    expect(await vm.verifyAuthenticationCode(resetCode), true);
    expect(vm.destination, CakeDestination.resetPassword);
    expect(await vm.resetPassword('NewPassword123', 'NewPassword123'), true);
    expect(vm.destination, CakeDestination.login);

    await vm.authenticate(email: 'alice', password: 'Password123');
    expect(vm.isLoggedIn, false);
    await vm.authenticate(email: 'alice', password: 'NewPassword123');
    expect(vm.isLoggedIn, true);
  });
}
