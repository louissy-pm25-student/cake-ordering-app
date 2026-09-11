class UserProfile {
  final String name, address, phone;
  const UserProfile({this.name = '', this.address = '', this.phone = ''});
  UserProfile copyWith({String? name, String? address, String? phone}) =>
      UserProfile(
        name: name ?? this.name,
        address: address ?? this.address,
        phone: phone ?? this.phone,
      );
  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'phone': phone,
  };
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
  );
}
