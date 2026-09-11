import '../model/cake.dart';

abstract class CakeRepository {
  static const cakes = [
    Cake(
      'Strawberry Dream',
      29,
      0,
      'Birthday',
      'Vanilla sponge · fresh strawberries',
    ),
    Cake('Chocolate Luxury', 35, 1, 'Birthday', 'Rich cocoa · silky ganache'),
    Cake(
      'Vanilla Elegance',
      32,
      2,
      'Wedding',
      'Vanilla bean · buttercream flowers',
    ),
    Cake(
      'Red Velvet Love',
      38,
      3,
      'Birthday',
      'Red velvet · cream cheese frosting',
    ),
  ];
  Future<Map<String, dynamic>> load();
  Future<void> save(Map<String, dynamic> snapshot);
}
