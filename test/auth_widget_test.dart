import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_ordering_app/data/local_cake_repository.dart';
import 'package:cake_ordering_app/viewmodel/cake_viewmodel.dart';
import 'package:cake_ordering_app/ui/cake_app.dart';

Future<void> waitForWork(WidgetTester tester, CakeViewModel vm) async {
  for (var i = 0; i < 200 && vm.busy; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('customer registers, verifies, then logs in with username', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = CakeViewModel(
      LocalCakeRepository(await SharedPreferences.getInstance()),
    );
    await vm.load();
    await tester.pumpWidget(CakeApp(viewModel: vm));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('+60 '), findsOneWidget);
    expect(find.byTooltip('Show confirm password'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Alice Tan',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'alice',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'alice@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Malaysia mobile number'),
      '123456789',
    );
    await tester.tap(find.text('Gender'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'Password123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'different',
    );
    await tester.ensureVisible(find.text('Send verification code'));
    await tester.tap(find.text('Send verification code'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'Password123',
    );
    await tester.tap(find.text('Send verification code'));
    await waitForWork(tester, vm);
    expect(find.text('Enter verification code'), findsOneWidget);

    final code = vm.verificationSession!.developmentCode!;
    await tester.enterText(
      find.widgetWithText(TextFormField, '6-digit code'),
      code,
    );
    await tester.tap(find.text('Verify code'));
    await waitForWork(tester, vm);
    expect(find.textContaining('Account verified.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'alice',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'Password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await waitForWork(tester, vm);
    expect(find.text('Made just for you'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
