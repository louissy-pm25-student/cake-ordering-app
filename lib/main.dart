import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/local_cake_repository.dart';
import 'viewmodel/cake_viewmodel.dart';
import 'ui/cake_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final viewModel = CakeViewModel(LocalCakeRepository(preferences));
  await viewModel.load();
  runApp(CakeApp(viewModel: viewModel));
}
