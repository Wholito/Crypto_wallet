import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/storage/storage_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initLocalStorage();
  } catch (_) {
    await Hive.deleteBoxFromDisk(HiveBoxes.cache);
    await Hive.deleteBoxFromDisk(HiveBoxes.settings);
    await initLocalStorage();
  }
  runApp(ProviderScope(retry: (_, _) => null, child: const App()));
}
