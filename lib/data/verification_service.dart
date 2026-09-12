import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../model/auth_verification.dart';

abstract class VerificationService {
  bool get isDevelopment;

  Future<VerificationSession> sendCode({
    required VerificationChannel channel,
    required VerificationPurpose purpose,
    required String destination,
  });

  Future<bool> verifyCode(VerificationSession session, String code);

  factory VerificationService.configured() {
    const endpoint = String.fromEnvironment('VERIFICATION_API_URL');
    return endpoint.isEmpty
        ? DevelopmentVerificationService()
        : HttpVerificationService(endpoint);
  }
}

class DevelopmentVerificationService implements VerificationService {
  final Map<String, String> _codes = {};

  @override
  bool get isDevelopment => true;

  @override
  Future<VerificationSession> sendCode({
    required VerificationChannel channel,
    required VerificationPurpose purpose,
    required String destination,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final id =
        '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(9999)}';
    final code = (100000 + Random.secure().nextInt(900000)).toString();
    _codes[id] = code;
    return VerificationSession(
      challengeId: id,
      maskedDestination: _mask(destination, channel),
      channel: channel,
      purpose: purpose,
      developmentCode: code,
    );
  }

  @override
  Future<bool> verifyCode(VerificationSession session, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final valid = _codes[session.challengeId] == code.trim();
    if (valid) _codes.remove(session.challengeId);
    return valid;
  }
}

class HttpVerificationService implements VerificationService {
  final String endpoint;
  HttpVerificationService(this.endpoint);

  @override
  bool get isDevelopment => false;

  @override
  Future<VerificationSession> sendCode({
    required VerificationChannel channel,
    required VerificationPurpose purpose,
    required String destination,
  }) async {
    final result = await _post('/auth/send-code', {
      'channel': channel.value,
      'purpose': purpose.name,
      'destination': destination,
    });
    return VerificationSession(
      challengeId: '${result['challengeId']}',
      maskedDestination: '${result['maskedDestination']}',
      channel: channel,
      purpose: purpose,
    );
  }

  @override
  Future<bool> verifyCode(VerificationSession session, String code) async {
    final result = await _post('/auth/verify-code', {
      'challengeId': session.challengeId,
      'code': code.trim(),
    });
    return result['verified'] == true;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('$endpoint$path'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close();
      final text = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Verification service rejected the request.');
      }
      return Map<String, dynamic>.from(jsonDecode(text) as Map);
    } finally {
      client.close(force: true);
    }
  }
}

String _mask(String value, VerificationChannel channel) {
  if (channel == VerificationChannel.email) {
    final parts = value.split('@');
    final visible = parts.first.isEmpty ? '' : parts.first[0];
    return '$visible***@${parts.length > 1 ? parts.last : ''}';
  }
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits.length < 4
      ? '***'
      : '*** *** ${digits.substring(digits.length - 4)}';
}
