import 'package:flutter/material.dart';

import '../viewmodel/cake_viewmodel.dart';
import '../nav/cake_destination.dart';
import '../ui/cake_style.dart';
import '../ui/cake_widgets.dart';

class AuthForm extends StatefulWidget {
  final CakeViewModel vm;
  final bool register;
  const AuthForm(this.vm, {required this.register, super.key});
  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  bool _hidden = true;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    widget.vm.authenticate(
      email: _email.text,
      password: _password.text,
      name: widget.register ? _name.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: vm.busy ? null : vm.cancelLogin,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Continue browsing'),
          ),
        ),
        CakePanel(
          color: CakeStyle.blush,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SWEET STUDIO',
                      style: TextStyle(
                        color: CakeStyle.caramel,
                        letterSpacing: 2,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.register
                          ? 'Join our\nsweet circle.'
                          : 'Welcome\nback, cake lover.',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 100, height: 130, child: CakePhoto(0)),
            ],
          ),
        ),
        gap,
        PageTitle(
          widget.register ? 'Create your account' : 'Log in',
          'Log in to order cakes, customize a creation and see your orders.',
        ),
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              children: [
                if (widget.register) ...[
                  TextFormField(
                    controller: _name,
                    enabled: !vm.busy,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter your name.'
                        : null,
                  ),
                  gap,
                ],
                TextFormField(
                  controller: _email,
                  enabled: !vm.busy,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: widget.register
                        ? 'Email address'
                        : 'Email or admin username',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) =>
                      (!widget.register && (v?.trim().isNotEmpty ?? false))
                      ? null
                      : !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(v?.trim() ?? '')
                      ? 'Enter a valid email address.'
                      : null,
                ),
                gap,
                TextFormField(
                  controller: _password,
                  enabled: !vm.busy,
                  obscureText: _hidden,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: [
                    widget.register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _hidden ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _hidden = !_hidden),
                      icon: Icon(
                        _hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) => (v ?? '').isEmpty
                      ? 'Enter your password.'
                      : widget.register && v!.length < 8
                      ? 'Use at least 8 characters.'
                      : null,
                ),
                gap,
                if (widget.register) ...[
                  TextFormField(
                    controller: _confirm,
                    enabled: !vm.busy,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) =>
                        v != _password.text ? 'Passwords do not match.' : null,
                  ),
                  gap,
                ],
                if (vm.authError != null) ...[
                  Text(
                    vm.authError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  gap,
                ],
                PrimaryButton(
                  vm.busy
                      ? 'Please wait…'
                      : widget.register
                      ? 'Create account'
                      : 'Log in',
                  vm.busy ? null : _submit,
                ),
                gap,
                TextButton(
                  onPressed: vm.busy
                      ? null
                      : () => vm.navigate(
                          widget.register
                              ? CakeDestination.login
                              : CakeDestination.register,
                        ),
                  child: Text(
                    widget.register
                        ? 'Already have an account? Log in'
                        : 'New here? Create an account',
                  ),
                ),
                const Text(
                  'Local demo account · Available only on this device. No online authentication service is connected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CakeStyle.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
