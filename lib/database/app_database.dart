import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../features/common_problems/data/tables/common_problems_table.dart';
import '../features/online_tracking/data/tables/tracking_sync_outbox_table.dart';
import '../features/online_tracking/domain/tracking_sync_operation.dart';
import '../features/online_tracking/infrastructure/public_shop_id_generator.dart';
import '../features/online_tracking/infrastructure/tracking_token_generator.dart';
import '../features/repairs/data/tables/repairs_table.dart';
import '../features/repairs/data/tables/repair_code_sequence_table.dart';
import '../features/settings/data/tables/shop_settings_table.dart';
import 'local_database_path_resolver.dart';

part 'app_database.g.dart';

const appDatabaseFileName = 'nova_repair.sqlite';

@DriftDatabase(
  tables: [
    Repairs,
    RepairCodeSequenceTable,
    ShopSettingsTable,
    CommonProblems,
    TrackingSyncOutboxTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openAppDatabaseConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator migrator) => migrator.createAll(),
      onUpgrade: (Migrator migrator, int from, int to) async {
        if (from < 2) {
          await migrator.createTable(repairs);
        }
        if (from < 3) {
          await migrator.createTable(shopSettingsTable);
        }
        if (from < 4) {
          await migrator.createTable(repairCodeSequenceTable);
        }
        if (from >= 3 && from < 5) {
          await migrator.addColumn(
            shopSettingsTable,
            shopSettingsTable.shopSubtitle,
          );
          await migrator.addColumn(
            shopSettingsTable,
            shopSettingsTable.defaultCustomerTicketPrinterId,
          );
          await migrator.addColumn(
            shopSettingsTable,
            shopSettingsTable.defaultDeviceLabelPrinterId,
          );
        }
        if (from < 6) {
          await migrator.createTable(commonProblems);
        }
        if (from < 7) {
          if (from >= 2) {
            await customStatement(
              'ALTER TABLE repairs ADD COLUMN tracking_token TEXT',
            );
          }
          if (from >= 3) {
            await customStatement(
              'ALTER TABLE shop_settings ADD COLUMN public_shop_id TEXT',
            );
          }
          await migrator.createTable(trackingSyncOutboxTable);
          await customStatement(
            'CREATE UNIQUE INDEX IF NOT EXISTS repairs_tracking_token_unique '
            'ON repairs(tracking_token)',
          );
          await _initializeOnlineTrackingLocalState();
        }
      },
    );
  }

  Future<void> _initializeOnlineTrackingLocalState() async {
    final tokenGenerator = TrackingTokenGenerator();
    final shopIdGenerator = PublicShopIdGenerator(
      tokenGenerator: tokenGenerator,
    );

    final settingsRows = await customSelect(
      'SELECT id, public_shop_id FROM shop_settings WHERE id = 1',
    ).get();
    if (settingsRows.isNotEmpty &&
        settingsRows.single.data['public_shop_id'] == null) {
      await customStatement('UPDATE shop_settings SET public_shop_id = ?', [
        shopIdGenerator.generate(),
      ]);
    }

    final repairRows = await customSelect(
      'SELECT id, tracking_token FROM repairs ORDER BY id ASC',
    ).get();
    final usedTokens = <String>{};
    for (final row in repairRows) {
      final existing = row.data['tracking_token'] as String?;
      if (existing != null && existing.isNotEmpty) {
        usedTokens.add(existing);
        continue;
      }

      final token = _uniqueToken(tokenGenerator, usedTokens);
      await customStatement(
        'UPDATE repairs SET tracking_token = ? WHERE id = ?',
        [token, row.data['id'] as int],
      );
    }

    final now = DateTime.now().toUtc();
    final nowValue = now.millisecondsSinceEpoch;
    for (final row in repairRows) {
      await customStatement(
        '''
        INSERT INTO tracking_sync_outbox (
          repair_id,
          operation,
          attempt_count,
          last_error,
          next_attempt_at,
          created_at,
          updated_at
        )
        VALUES (?, ?, 0, NULL, ?, ?, ?)
        ON CONFLICT(repair_id) DO UPDATE SET
          operation = excluded.operation,
          attempt_count = 0,
          last_error = NULL,
          next_attempt_at = excluded.next_attempt_at,
          updated_at = excluded.updated_at
        ''',
        [
          row.data['id'] as int,
          TrackingSyncOperation.upsertSnapshot.databaseValue,
          nowValue,
          nowValue,
          nowValue,
        ],
      );
    }
  }

  String _uniqueToken(
    TrackingTokenGenerator generator,
    Set<String> usedTokens,
  ) {
    while (true) {
      final token = generator.generate();
      if (usedTokens.add(token)) {
        return token;
      }
    }
  }
}

LazyDatabase openAppDatabaseConnection() {
  return LazyDatabase(() async {
    final file = await resolveAppDatabaseFile();
    await file.parent.create(recursive: true);
    return openNativeDatabaseFile(file);
  });
}

NativeDatabase openNativeDatabaseFile(File file) {
  return NativeDatabase(
    file,
    setup: (database) {
      database.execute('PRAGMA foreign_keys = ON');
    },
  );
}

Future<File> resolveAppDatabaseFile({
  Future<Directory> Function()? appSupportDirectoryProvider,
  LocalDatabasePathResolver? resolver,
  String fileName = appDatabaseFileName,
}) async {
  final effectiveResolver =
      resolver ??
      (appSupportDirectoryProvider == null
          ? LocalDatabasePathResolver(fileName: fileName)
          : LocalDatabasePathResolver(
              documentsDirectoryProvider: appSupportDirectoryProvider,
              legacyAppSupportDirectoryProvider: appSupportDirectoryProvider,
              fileName: fileName,
            ));

  return effectiveResolver.resolveDatabaseFile();
}
