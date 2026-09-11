import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Local demo credentials. Production authentication requires a server.
class LocalAccount {
  final String name, email, salt, passwordHash;
  const LocalAccount(this.name, this.email, this.salt, this.passwordHash);
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
    String password,
  ) async {
    final random = Random.secure();
    final salt = List.generate(16, (_) => random.nextInt(256));
    return LocalAccount(
      name,
      email,
      base64Encode(salt),
      await _hash(password, salt),
    );
  }

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
    'email': email,
    'salt': salt,
    'passwordHash': passwordHash,
  };
  factory LocalAccount.fromJson(Map<String, dynamic> json) => LocalAccount(
    json['name'] as String,
    json['email'] as String,
    json['salt'] as String,
    json['passwordHash'] as String,
  );
}
