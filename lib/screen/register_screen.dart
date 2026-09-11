import 'package:flutter/material.dart';

import '../viewmodel/cake_viewmodel.dart';
import 'auth_form.dart';

class RegisterScreen extends StatelessWidget {
  final CakeViewModel viewModel;
  const RegisterScreen(this.viewModel, {super.key});
  @override
  Widget build(BuildContext context) => AuthForm(viewModel, register: true);
}
