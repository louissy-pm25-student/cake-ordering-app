import 'package:flutter/material.dart';

import '../model/auth_verification.dart';
import '../ui/cake_widgets.dart';
import '../viewmodel/cake_viewmodel.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final CakeViewModel viewModel;
  const ForgotPasswordScreen(this.viewModel, {super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _username = TextEditingController();
  VerificationChannel _channel = VerificationChannel.email;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: vm.busy ? null : vm.cancelAuthenticationFlow,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to login'),
          ),
        ),
        const PageTitle(
          'Forgot password',
          'Choose where you want to receive your verification code.',
        ),
        TextField(
          controller: _username,
          enabled: !vm.busy,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Username or email',
            prefixIcon: Icon(Icons.person_search_outlined),
          ),
        ),
        gap,
        SegmentedButton<VerificationChannel>(
          segments: const [
            ButtonSegment(
              value: VerificationChannel.email,
              icon: Icon(Icons.email_outlined),
              label: Text('Email'),
            ),
            ButtonSegment(
              value: VerificationChannel.sms,
              icon: Icon(Icons.sms_outlined),
              label: Text('Phone'),
            ),
          ],
          selected: {_channel},
          onSelectionChanged: vm.busy
              ? null
              : (value) => setState(() => _channel = value.first),
        ),
        if (vm.authError != null) ...[
          gap,
          Text(
            vm.authError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        gap,
        PrimaryButton(
          'Send verification code',
          vm.busy
              ? null
              : () => vm.beginPasswordReset(
                  username: _username.text,
                  channel: _channel,
                ),
        ),
      ],
    );
  }
}
