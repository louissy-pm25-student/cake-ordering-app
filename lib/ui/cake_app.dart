import 'package:flutter/material.dart';

import '../viewmodel/cake_viewmodel.dart';
import '../nav/cake_destination.dart';
import '../nav/cake_navigation.dart';
import '../nav/cake_nav_host.dart';
import 'cake_style.dart';
import '../screen/admin/admin_screen.dart';
import 'cake_widgets.dart';

class CakeApp extends StatelessWidget {
  final CakeViewModel viewModel;
  const CakeApp({required this.viewModel, super.key});
  static const icons = {
    CakeDestination.home: Icons.home_outlined,
    CakeDestination.menu: Icons.receipt_long_outlined,
    CakeDestination.customize: Icons.add,
    CakeDestination.orders: Icons.inventory_2_outlined,
    CakeDestination.profile: Icons.person_outline,
  };
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sweet Studio',
    debugShowCheckedModeBanner: false,
    theme: CakeStyle.theme,
    builder: (context, child) => ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => AppLoadingOverlay(
        isLoading: viewModel.busy || viewModel.admin.busy,
        child: child ?? const SizedBox.shrink(),
      ),
    ),
    home: ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final vm = viewModel;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: vm.isAdmin
              ? AdminScreen(
                  vm.admin,
                  key: const ValueKey('admin-shell'),
                  onLogout: vm.exitAdmin,
                )
              : PopScope(
                  key: const ValueKey('customer-shell'),
                  canPop: vm.destination == CakeDestination.home && !vm.busy,
                  onPopInvokedWithResult: (didPop, result) {
                    if (!didPop) vm.goBack();
                  },
                  child: Scaffold(
                    body: SafeArea(
                      bottom: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            children: [
                              if (vm.error != null)
                                MaterialBanner(
                                  content: Text(vm.error!),
                                  actions: [
                                    TextButton(
                                      onPressed: vm.dismissError,
                                      child: const Text('Dismiss'),
                                    ),
                                  ],
                                ),
                              Expanded(
                                child: Stack(
                                  children: [
                                    CakeNavHost(vm),
                                    if (CakeNavigation.showsCart(
                                          vm.destination,
                                        ) &&
                                        vm.cart.isNotEmpty)
                                      Positioned(
                                        left: 16,
                                        right: 16,
                                        bottom: 12,
                                        child: PrimaryButton(
                                          'View cart · ${vm.cartCount} items    ${money(vm.subtotal)}',
                                          () => vm.navigate(
                                            CakeDestination.checkout,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    bottomNavigationBar:
                        ({
                          CakeDestination.login,
                          CakeDestination.register,
                          CakeDestination.verifyAccount,
                          CakeDestination.forgotPassword,
                          CakeDestination.resetPassword,
                        }.contains(vm.destination))
                        ? null
                        : Container(
                            decoration: const BoxDecoration(
                              color: CakeStyle.paper,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(30),
                              ),
                            ),
                            child: SafeArea(
                              top: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: CakeNavigation.bottomDestinations
                                      .map((page) {
                                        final selected = vm.destination == page;
                                        final custom =
                                            page == CakeDestination.customize;
                                        return Expanded(
                                          child: Semantics(
                                            selected: selected,
                                            button: true,
                                            child: InkWell(
                                              onTap: vm.busy
                                                  ? null
                                                  : () => vm.navigate(page),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: custom ? 46 : 34,
                                                      height: custom ? 46 : 34,
                                                      decoration: custom
                                                          ? const BoxDecoration(
                                                              color: CakeStyle
                                                                  .caramel,
                                                              shape: BoxShape
                                                                  .circle,
                                                            )
                                                          : null,
                                                      child: Icon(
                                                        icons[page],
                                                        color: custom
                                                            ? Colors.white
                                                            : selected
                                                            ? CakeStyle.caramel
                                                            : CakeStyle.muted,
                                                        size: 27,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      page.label,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: selected
                                                            ? CakeStyle.caramel
                                                            : CakeStyle.muted,
                                                        fontWeight: selected
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
        );
      },
    ),
  );
}
