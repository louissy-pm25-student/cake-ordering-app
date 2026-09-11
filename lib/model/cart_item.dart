class CartItem {
  final String id, name, details, productId, variantId, photoData;
  final double price;
  final int photo, quantity;
  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.photo,
    required this.details,
    this.quantity = 1,
    this.productId = '',
    this.variantId = '',
    this.photoData = '',
  });
  CartItem withQuantity(int value) => CartItem(
    id: id,
    name: name,
    price: price,
    photo: photo,
    details: details,
    quantity: value,
    productId: productId,
    variantId: variantId,
    photoData: photoData,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'photo': photo,
    'details': details,
    'quantity': quantity,
    'productId': productId,
    'variantId': variantId,
    'photoData': photoData,
  };
  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: '${json['id'] ?? json['product']}',
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    photo: json['photo'] as int? ?? 0,
    details: json['details'] as String? ?? '',
    quantity: json['quantity'] as int,
    productId: json['productId'] as String? ?? '${json['product'] ?? ''}',
    variantId: json['variantId'] as String? ?? '',
    photoData: json['photoData'] as String? ?? '',
  );
}
