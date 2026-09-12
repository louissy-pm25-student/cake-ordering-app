import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/auth_verification.dart';
import '../nav/cake_destination.dart';
import '../ui/cake_widgets.dart';
import '../viewmodel/cake_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  final CakeViewModel viewModel;
  const RegisterScreen(this.viewModel, {super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _gender = '';
  VerificationChannel _channel = VerificationChannel.sms;
  bool _hidden = true;
  bool _confirmHidden = true;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _username,
      _email,
      _phone,
      _password,
      _confirm,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.viewModel.beginRegistration(
      name: _name.text,
      username: _username.text,
      email: _email.text,
      phone: '+60${_phone.text}',
      gender: _gender,
      password: _password.text,
      confirmPassword: _confirm.text,
      channel: _channel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: vm.busy
                ? null
                : () => vm.navigate(CakeDestination.login),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to login'),
          ),
        ),
        const PageTitle(
          'Create your account',
          'Enter accurate contact details so your verification and order updates reach you.',
        ),
        Form(
          key: _form,
          child: Column(
            children: [
              _field(
                _name,
                'Full name',
                Icons.person_outline,
                autofill: const [AutofillHints.name],
              ),
              gap,
              _field(
                _username,
                'Username',
                Icons.alternate_email,
                validator: (value) =>
                    RegExp(r'^[a-zA-Z0-9_.-]{3,30}$')
                        .hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Use 3–30 letters, numbers, dots, underscores or hyphens.',
              ),
              gap,
              _field(
                _email,
                'Email address',
                Icons.mail_outline,
                keyboard: TextInputType.emailAddress,
                autofill: const [AutofillHints.email],
                validator: (value) =>
                    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Enter a valid email address.',
              ),
              gap,
              _field(
                _phone,
                'Malaysia mobile number',
                Icons.phone_outlined,
                keyboard: TextInputType.phone,
                autofill: const [AutofillHints.telephoneNumber],
                prefixText: '+60 ',
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) =>
                    RegExp(r'^1\d{8,9}$').hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Enter the number without 0, for example 123456789.',
              ),
              gap,
              DropdownButtonFormField<String>(
                initialValue: _gender.isEmpty ? null : _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc_outlined),
                ),
                items:
                    const ['Female', 'Male', 'Non-binary', 'Prefer not to say']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: vm.busy
                    ? null
                    : (value) => setState(() => _gender = value ?? ''),
                validator: (value) =>
                    value == null ? 'Select your gender.' : null,
              ),
              gap,
              TextFormField(
                controller: _password,
                obscureText: _hidden,
                enabled: !vm.busy,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => (value ?? '').length < 8
                    ? 'Use at least 8 characters.'
                    : null,
              ),
              gap,
              TextFormField(
                controller: _confirm,
                obscureText: _confirmHidden,
                enabled: !vm.busy,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _confirmHidden
                        ? 'Show confirm password'
                        : 'Hide confirm password',
                    onPressed: () =>
                        setState(() => _confirmHidden = !_confirmHidden),
                    icon: Icon(
                      _confirmHidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) =>
                    value != _password.text ? 'Passwords do not match.' : null,
              ),
              gap,
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Send verification code by',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<VerificationChannel>(
                segments: const [
                  ButtonSegment(
                    value: VerificationChannel.sms,
                    icon: Icon(Icons.sms_outlined),
                    label: Text('Phone'),
                  ),
                  ButtonSegment(
                    value: VerificationChannel.email,
                    icon: Icon(Icons.email_outlined),
                    label: Text('Email'),
                  ),
                ],
                selected: {_channel},
                onSelectionChanged: vm.busy
                    ? null
                    : (value) => setState(() => _channel = value.first),
              ),
              gap,
              if (vm.authError != null) ...[
                Text(
                  vm.authError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                gap,
              ],
              PrimaryButton('Send verification code', vm.busy ? null : _submit),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    List<String>? autofill,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    enabled: !widget.viewModel.busy,
    keyboardType: keyboard,
    autofillHints: autofill,
    autocorrect: false,
    inputFormatters: inputFormatters,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      prefixText: prefixText,
    ),
    validator:
        validator ??
        (value) =>
            (value?.trim().isEmpty ?? true) ? 'This field is required.' : null,
  );
}
