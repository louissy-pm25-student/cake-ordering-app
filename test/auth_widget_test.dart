import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_ordering_app/data/local_cake_repository.dart';
import 'package:cake_ordering_app/viewmodel/cake_viewmodel.dart';
import 'package:cake_ordering_app/ui/cake_app.dart';

void main() {
  testWidgets('guest login and register pages validate forms', (tester) async {
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
    expect(find.text('Welcome\nback, cake lover.'), findsOneWidget);
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Alice',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'alice@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'Password123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'different',
    );
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'Password123',
    );
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));

    for (var i = 0; i < 200 && vm.busy; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    expect(vm.busy, false);
    await tester.pumpAndSettle();
    expect(find.text('Made just for you'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
