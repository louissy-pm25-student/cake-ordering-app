class CakeCustomization {
  final String flavor, size, shape, decoration, message;
  const CakeCustomization({
    this.flavor = 'Vanilla',
    this.size = '6 inch',
    this.shape = 'Round',
    this.decoration = 'Fresh fruit',
    this.message = '',
  });
  CakeCustomization copyWith({
    String? flavor,
    String? size,
    String? shape,
    String? decoration,
    String? message,
  }) => CakeCustomization(
    flavor: flavor ?? this.flavor,
    size: size ?? this.size,
    shape: shape ?? this.shape,
    decoration: decoration ?? this.decoration,
    message: message ?? this.message,
  );
}
