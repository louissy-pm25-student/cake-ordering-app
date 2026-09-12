import 'package:flutter/material.dart';

import '../screen/main_menu_screen.dart';
import '../screen/login_screen.dart';
import '../screen/register_screen.dart';
import '../screen/verification_screen.dart';
import '../screen/forgot_password_screen.dart';
import '../screen/reset_password_screen.dart';
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
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 240),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    layoutBuilder: (current, previous) => Stack(
      alignment: Alignment.topCenter,
      children: [...previous, ?current],
    ),
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.045, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
    ),
    child: KeyedSubtree(
      key: ValueKey(viewModel.destination),
      child: switch (viewModel.destination) {
        CakeDestination.admin => const SizedBox.shrink(),
        CakeDestination.login => LoginScreen(viewModel),
        CakeDestination.register => RegisterScreen(viewModel),
        CakeDestination.verifyAccount => VerificationScreen(viewModel),
        CakeDestination.forgotPassword => ForgotPasswordScreen(viewModel),
        CakeDestination.resetPassword => ResetPasswordScreen(viewModel),
        CakeDestination.home ||
        CakeDestination.menu => MainMenuScreen(viewModel),
        CakeDestination.customize => CustomizeScreen(viewModel),
        CakeDestination.checkout => CheckoutScreen(viewModel),
        CakeDestination.orders => OrdersScreen(viewModel),
        CakeDestination.profile => ProfileScreen(viewModel),
      },
    ),
  );
}
