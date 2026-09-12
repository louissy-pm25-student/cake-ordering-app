import 'package:cake_ordering_app/data/local_cake_repository.dart';
import 'package:cake_ordering_app/nav/cake_nav_host.dart';
import 'package:cake_ordering_app/ui/cake_app.dart';
import 'package:cake_ordering_app/ui/cake_widgets.dart';
import 'package:cake_ordering_app/viewmodel/cake_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('loading overlay shows a spinner and blocks interaction', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AppLoadingOverlay(
          isLoading: true,
          child: Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => taps++,
                child: const Text('Action'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading…'), findsNothing);
    expect(find.text('Please wait…'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'Loading',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Action'), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('customer pages use a fade and slide transition', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final vm = CakeViewModel(
      LocalCakeRepository(await SharedPreferences.getInstance()),
    );
    await vm.load();
    await tester.pumpWidget(CakeApp(viewModel: vm));
    await tester.pumpAndSettle();

    final transition = tester
        .widgetList<AnimatedSwitcher>(
          find.descendant(
            of: find.byType(CakeNavHost),
            matching: find.byType(AnimatedSwitcher),
          ),
        )
        .singleWhere(
          (widget) => widget.duration == const Duration(milliseconds: 320),
        );
    expect(transition.duration, const Duration(milliseconds: 320));

    await tester.tap(find.text('Menu'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(FadeTransition), findsWidgets);
    expect(find.byType(SlideTransition), findsWidgets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
