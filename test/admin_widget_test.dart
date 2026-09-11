import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_ordering_app/data/local_cake_repository.dart';
import 'package:cake_ordering_app/viewmodel/cake_viewmodel.dart';
import 'package:cake_ordering_app/ui/cake_app.dart';

void main() {
  testWidgets(
    'owner logs in, creates a cake with the floating Add button, and customer menu updates',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final vm = CakeViewModel(
        LocalCakeRepository(await SharedPreferences.getInstance()),
      );
      await vm.load();
      await tester.pumpWidget(CakeApp(viewModel: vm));
      await tester.pumpAndSettle();
      expect(find.text('Our menu is being prepared'), findsOneWidget);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email or admin username'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'admin123',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Log in'));
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      final metrics = tester.widget<GridView>(find.byType(GridView).first);
      final delegate =
          metrics.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
      await tester.tap(find.byTooltip('Open admin menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('admin-nav-products')));
      await tester.pumpAndSettle();
      final add = find.byType(FloatingActionButton);
      expect(add, findsOneWidget);
      expect(tester.getBottomLeft(add).dy, lessThan(900));
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cake name'),
        'Celebration Cake',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Fresh vanilla cake',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Base price'),
        '45',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(vm.cakes.single.name, 'Celebration Cake');
      await tester.tap(find.byTooltip('Open admin menu'));
      await tester.pumpAndSettle();
      final profile = find.byKey(const ValueKey('admin-nav-profile'));
      await tester.scrollUntilVisible(
        profile,
        300,
        scrollable: find.descendant(
          of: find.byType(Drawer),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(profile);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextField, 'Username'),
        'studioowner',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Current password'),
        'admin123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'New password'),
        'UpdatedPass123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm new password'),
        'UpdatedPass123',
      );
      final save = find.widgetWithText(FilledButton, 'Save profile');
      await tester.ensureVisible(save);
      await tester.tap(save);
      for (var i = 0; i < 300 && vm.admin.busy; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
      }
      expect(vm.admin.busy, false);
      await tester.pumpAndSettle();
      expect(vm.admin.username, 'studioowner');
      expect(
        find.text(
          'Profile saved. Use your updated credentials next time you log in.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Open admin menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(find.text('Celebration Cake'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
