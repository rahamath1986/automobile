import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/storage/token_store.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the secure session before the API client can issue authorised requests.
  final tokenStore = TokenStore();
  await tokenStore.load();

  runApp(
    ProviderScope(
      overrides: [tokenStoreProvider.overrideWithValue(tokenStore)],
      child: const MotoSaasCustomerApp(),
    ),
  );
}
