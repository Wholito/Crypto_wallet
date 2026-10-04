import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract final class HiveBoxes {
  static const settings = 'settings';
  static const cache = 'cache';
}

Future<void> initLocalStorage() async {
  await Hive.initFlutter();
  await Hive.openBox<String>(HiveBoxes.settings);
  await Hive.openBox<String>(HiveBoxes.cache);
}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device),
  ),
);

final settingsBoxProvider =
    Provider<Box<String>>((ref) => Hive.box<String>(HiveBoxes.settings));

final cacheBoxProvider =
    Provider<Box<String>>((ref) => Hive.box<String>(HiveBoxes.cache));
