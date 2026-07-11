import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'database_lifecycle_manager.dart';

final databaseLifecycleManagerProvider = Provider<DatabaseLifecycleManager>((
  ref,
) {
  final manager = DatabaseLifecycleManager.production();
  ref.onDispose(manager.closeCurrentDatabase);
  return manager;
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return ref.watch(databaseLifecycleManagerProvider).database;
});
