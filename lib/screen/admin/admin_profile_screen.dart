import 'package:flutter/material.dart';

import '../../viewmodel/admin/admin_viewmodel.dart';
import '../../ui/cake_widgets.dart';

class AdminProfileScreen extends StatefulWidget {
  final AdminViewModel vm;
  const AdminProfileScreen(this.vm, {super.key});
  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late final TextEditingController _username = TextEditingController(
    text: widget.vm.username,
  );
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _saved = false;

  @override
  void dispose() {
    for (final c in [_username, _current, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _saved = false;
    });
    final ok = await widget.vm.updateProfile(
      newUsername: _username.text,
      currentPassword: _current.text,
      newPassword: _password.text,
      confirmPassword: _confirm.text,
    );
    if (!mounted) return;
    setState(() {
      _error = ok ? null : widget.vm.error;
      _saved = ok;
      if (ok) {
        _username.text = widget.vm.username;
        _current.clear();
        _password.clear();
        _confirm.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) => CakePanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.account_circle_outlined, size: 60),
        const SizedBox(height: 12),
        Text(
          'Signed in as ${widget.vm.username}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text('Role: ${widget.vm.role}', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        TextField(
          controller: _username,
          enabled: !widget.vm.busy,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _current,
          enabled: !widget.vm.busy,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(labelText: 'Current password'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          enabled: !widget.vm.busy,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: 'New password',
            helperText:
                'At least 8 characters. Leave blank to keep your password.',
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirm,
          enabled: !widget.vm.busy,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(labelText: 'Confirm new password'),
          onSubmitted: widget.vm.busy ? null : (_) => _save(),
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_saved)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Profile saved. Use your updated credentials next time you log in.',
            ),
          ),
        FilledButton.icon(
          onPressed: widget.vm.busy ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(widget.vm.busy ? 'Saving…' : 'Save profile'),
        ),
      ],
    ),
  );
}
