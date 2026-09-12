import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Local demo credentials. Production authentication requires a server.
class LocalAccount {
  final String name, username, email, phone, gender, salt, passwordHash;
  const LocalAccount({
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.gender,
    required this.salt,
    required this.passwordHash,
  });
  static final _algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );
  static Future<String> _hash(String password, List<int> salt) async {
    final key = await _algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return base64Encode(await key.extractBytes());
  }

  static Future<LocalAccount> create(
    String name,
    String email,
    String password, {
    String? username,
    String phone = '',
    String gender = '',
  }) async {
    final random = Random.secure();
    final salt = List.generate(16, (_) => random.nextInt(256));
    return LocalAccount(
      name: name,
      username: (username ?? email).trim().toLowerCase(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      gender: gender,
      salt: base64Encode(salt),
      passwordHash: await _hash(password, salt),
    );
  }

  Future<LocalAccount> withPassword(String password) => LocalAccount.create(
    name,
    email,
    password,
    username: username,
    phone: phone,
    gender: gender,
  );

  Future<bool> verify(String password) async {
    final actual = base64Decode(await _hash(password, base64Decode(salt)));
    final expected = base64Decode(passwordHash);
    if (actual.length != expected.length) return false;
    var difference = 0;
    for (var i = 0; i < actual.length; i++) {
      difference |= actual[i] ^ expected[i];
    }
    return difference == 0;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'username': username,
    'email': email,
    'phone': phone,
    'gender': gender,
    'salt': salt,
    'passwordHash': passwordHash,
  };
  factory LocalAccount.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String;
    return LocalAccount(
      name: json['name'] as String,
      username: json['username'] as String? ?? email,
      email: email,
      phone: json['phone'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      salt: json['salt'] as String,
      passwordHash: json['passwordHash'] as String,
    );
  }
}
