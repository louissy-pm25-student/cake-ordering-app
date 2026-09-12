import 'package:flutter/material.dart';

import '../model/auth_verification.dart';
import '../ui/cake_style.dart';
import '../ui/cake_widgets.dart';
import '../viewmodel/cake_viewmodel.dart';

class VerificationScreen extends StatefulWidget {
  final CakeViewModel viewModel;
  const VerificationScreen(this.viewModel, {super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final session = vm.verificationSession;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: vm.busy ? null : vm.cancelAuthenticationFlow,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Cancel'),
          ),
        ),
        const Icon(
          Icons.mark_email_read_outlined,
          size: 62,
          color: CakeStyle.caramel,
        ),
        const SizedBox(height: 18),
        PageTitle(
          'Enter verification code',
          session == null
              ? 'Start verification again.'
              : 'We sent a 6-digit code by ${session.channel.label.toLowerCase()} to ${session.maskedDestination}.',
        ),
        TextFormField(
          controller: _code,
          enabled: !vm.busy,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          style: const TextStyle(fontSize: 22, letterSpacing: 8),
          decoration: const InputDecoration(
            labelText: '6-digit code',
            counterText: '',
          ),
        ),
        if (session?.developmentCode != null) ...[
          const SizedBox(height: 12),
          CakePanel(
            color: CakeStyle.blush,
            child: Text(
              'Development code: ${session!.developmentCode}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        if (vm.authError != null) ...[
          gap,
          Text(
            vm.authError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        gap,
        PrimaryButton(
          'Verify code',
          vm.busy ? null : () => vm.verifyAuthenticationCode(_code.text),
        ),
        TextButton(
          onPressed: vm.busy ? null : vm.resendVerification,
          child: const Text('Send a new code'),
        ),
      ],
    );
  }
}
