import 'package:flutter/material.dart';

import '../screen/main_menu_screen.dart';
import '../screen/login_screen.dart';
import '../screen/register_screen.dart';
import '../screen/customize_screen.dart';
import '../screen/checkout_screen.dart';
import '../screen/orders_screen.dart';
import '../screen/profile_screen.dart';
import '../viewmodel/cake_viewmodel.dart';
import 'cake_destination.dart';

class CakeNavHost extends StatelessWidget {
  final CakeViewModel viewModel;
  const CakeNavHost(this.viewModel, {super.key});
  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: ValueKey(viewModel.destination),
    child: switch (viewModel.destination) {
      CakeDestination.admin => const SizedBox.shrink(),
      CakeDestination.login => LoginScreen(viewModel),
      CakeDestination.register => RegisterScreen(viewModel),
      CakeDestination.home || CakeDestination.menu => MainMenuScreen(viewModel),
      CakeDestination.customize => CustomizeScreen(viewModel),
      CakeDestination.checkout => CheckoutScreen(viewModel),
      CakeDestination.orders => OrdersScreen(viewModel),
      CakeDestination.profile => ProfileScreen(viewModel),
    },
  );
}
