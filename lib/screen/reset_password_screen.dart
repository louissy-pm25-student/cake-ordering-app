import 'package:flutter/material.dart';

import '../ui/cake_widgets.dart';
import '../viewmodel/cake_viewmodel.dart';

class ResetPasswordScreen extends StatefulWidget {
  final CakeViewModel viewModel;
  const ResetPasswordScreen(this.viewModel, {super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidden = true;
  bool _confirmHidden = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const PageTitle(
          'Set a new password',
          'Use at least 8 characters, then log in again.',
        ),
        TextField(
          controller: _password,
          enabled: !vm.busy,
          obscureText: _hidden,
          decoration: InputDecoration(
            labelText: 'New password',
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
        ),
        gap,
        TextField(
          controller: _confirm,
          enabled: !vm.busy,
          obscureText: _confirmHidden,
          decoration: InputDecoration(
            labelText: 'Confirm new password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _confirmHidden
                  ? 'Show confirm password'
                  : 'Hide confirm password',
              onPressed: () => setState(() => _confirmHidden = !_confirmHidden),
              icon: Icon(
                _confirmHidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
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
          'Save new password',
          vm.busy
              ? null
              : () => vm.resetPassword(_password.text, _confirm.text),
        ),
      ],
    );
  }
}
