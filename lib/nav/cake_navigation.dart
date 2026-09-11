import 'cake_destination.dart';

abstract final class CakeNavigation {
  static bool requiresLogin(CakeDestination page) => [
    CakeDestination.customize,
    CakeDestination.orders,
    CakeDestination.profile,
    CakeDestination.checkout,
  ].contains(page);
  static const bottomDestinations = [
    CakeDestination.home,
    CakeDestination.menu,
    CakeDestination.customize,
    CakeDestination.orders,
    CakeDestination.profile,
  ];
  static CakeDestination? backDestination(CakeDestination current) =>
      switch (current) {
        CakeDestination.home => null,
        CakeDestination.checkout => CakeDestination.menu,
        _ => CakeDestination.home,
      };
  static bool showsCart(CakeDestination page) =>
      page == CakeDestination.home || page == CakeDestination.menu;
}
