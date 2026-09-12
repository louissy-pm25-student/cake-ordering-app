import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/cake_repository.dart';
import 'data/local_cake_repository.dart';
import 'data/supabase_cake_repository.dart';
import 'data/supabase_config.dart';
import 'viewmodel/cake_viewmodel.dart';
import 'ui/cake_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final localRepository = LocalCakeRepository(preferences);
  CakeRepository repository = localRepository;
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) {
      await client.auth.signInAnonymously().timeout(const Duration(seconds: 8));
    }
    repository = SupabaseCakeRepository(localRepository, client);
  } catch (_) {
    // The local cache keeps the app usable while Supabase is unavailable.
  }
  final viewModel = CakeViewModel(repository);
  await viewModel.load();
  runApp(CakeApp(viewModel: viewModel));
}
