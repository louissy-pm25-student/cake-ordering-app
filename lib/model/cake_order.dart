import 'cart_item.dart';

class CakeOrder {
  final String id, address, payment;
  final List<CartItem> items;
  final double total;
  CakeOrder({
    required this.id,
    required List<CartItem> items,
    required this.total,
    required this.address,
    required this.payment,
  }) : items = List.unmodifiable(items);
  Map<String, dynamic> toJson() => {
    'id': id,
    'address': address,
    'payment': payment,
    'total': total,
    'items': items.map((e) => e.toJson()).toList(),
  };
  factory CakeOrder.fromJson(Map<String, dynamic> json) => CakeOrder(
    id: json['id'] as String,
    address: json['address'] as String,
    payment: json['payment'] as String,
    total: (json['total'] as num).toDouble(),
    items: (json['items'] as List)
        .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}
