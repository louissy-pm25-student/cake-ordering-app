enum VerificationChannel { sms, email }

extension VerificationChannelLabel on VerificationChannel {
  String get label =>
      this == VerificationChannel.sms ? 'Phone message' : 'Email';
  String get value => name;
}

enum VerificationPurpose { registration, passwordReset }

String? normalizeMalaysiaMobile(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('60')) {
    digits = digits.substring(2);
  } else if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  if (!RegExp(r'^1\d{8,9}$').hasMatch(digits)) return null;
  return '+60$digits';
}

class RegistrationDraft {
  final String name, username, email, phone, gender, password;
  const RegistrationDraft({
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.gender,
    required this.password,
  });
}

class VerificationSession {
  final String challengeId, maskedDestination;
  final VerificationChannel channel;
  final VerificationPurpose purpose;
  final String? developmentCode;
  const VerificationSession({
    required this.challengeId,
    required this.maskedDestination,
    required this.channel,
    required this.purpose,
    this.developmentCode,
  });
}
