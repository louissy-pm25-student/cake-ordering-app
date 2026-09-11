import 'package:flutter/material.dart';

import '../viewmodel/cake_viewmodel.dart';
import 'auth_form.dart';

class LoginScreen extends StatelessWidget {
  final CakeViewModel viewModel;
  const LoginScreen(this.viewModel, {super.key});
  @override
  Widget build(BuildContext context) => AuthForm(viewModel, register: false);
}
