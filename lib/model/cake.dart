class Cake {
  final String name, category, note, id, photoData;
  final double price;
  final int photo;
  final bool available;
  const Cake(
    this.name,
    this.price,
    this.photo,
    this.category,
    this.note, {
    this.id = '',
    this.photoData = '',
    this.available = true,
  });
}
