import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/app/app.dart';
import 'package:nova_repair/app/theme/app_theme.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/database/database_provider.dart';
import 'package:nova_repair/features/common_problems/common_problems_page.dart';
import 'package:nova_repair/features/common_problems/data/datasources/common_problem_local_data_source.dart';
import 'package:nova_repair/features/common_problems/data/repositories/drift_common_problem_repository.dart';
import 'package:nova_repair/features/common_problems/domain/entities/create_common_problem_input.dart';
import 'package:nova_repair/features/printing/application/local_printer_service.dart';
import 'package:nova_repair/features/printing/application/print_printer_target.dart';
import 'package:nova_repair/features/printing/application/rendered_print_document.dart';
import 'package:nova_repair/features/printing/domain/entities/local_printer.dart';
import 'package:nova_repair/features/printing/domain/entities/print_result.dart';
import 'package:nova_repair/features/printing/printing_providers.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';

void main() {
  late AppDatabase database;
  late DriftCommonProblemRepository commonProblemRepository;
  late DateTime now;

  setUp(() {
    now = DateTime.utc(2026, 7, 6, 9);
    database = AppDatabase(_inMemoryDatabase());
    commonProblemRepository = _commonProblemRepository(database, () => now);
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('empty state renders and Add action opens dialog', (
    tester,
  ) async {
    await _pumpCommonProblemsPage(tester, database);

    expect(find.text('Common Problems'), findsWidgets);
    expect(
      find.text('Manage frequently used repair problem templates'),
      findsOneWidget,
    );
    expect(find.text('No common problems yet'), findsOneWidget);
    expect(
      find.text(
        'Add frequently used repair problems to speed up repair intake.',
      ),
      findsOneWidget,
    );

    await _tapVisible(
      tester,
      find.byKey(const Key('common-problems-empty-add-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Common Problem'), findsWidgets);
    expect(find.text('Problem'), findsOneWidget);
    expect(find.text('Add Problem'), findsOneWidget);
  });

  testWidgets('real persisted common problems render in backend order', (
    tester,
  ) async {
    final low = await commonProblemRepository.createCommonProblem(
      CreateCommonProblemInput(title: 'Low usage'),
    );
    final sameOld = await commonProblemRepository.createCommonProblem(
      CreateCommonProblemInput(title: 'Same old'),
    );
    final sameNew = await commonProblemRepository.createCommonProblem(
      CreateCommonProblemInput(title: 'Same new'),
    );
    now = DateTime.utc(2026, 7, 7, 10);
    await commonProblemRepository.incrementUsage(sameOld.id!);
    now = DateTime.utc(2026, 7, 7, 11);
    await commonProblemRepository.incrementUsage(sameNew.id!);
    now = DateTime.utc(2026, 7, 7, 12);
    await commonProblemRepository.incrementUsage(low.id!);
    await commonProblemRepository.incrementUsage(low.id!);

    await _pumpCommonProblemsPage(tester, database);

    expect(find.text('Problem Templates'), findsOneWidget);
    expect(find.text('Low usage'), findsOneWidget);
    expect(find.text('Used 2 times'), findsOneWidget);
    expect(find.text('Used 1 time'), findsWidgets);
    expect(
      _topOf(tester, find.text('Low usage')),
      lessThan(_topOf(tester, find.text('Same new'))),
    );
    expect(
      _topOf(tester, find.text('Same new')),
      lessThan(_topOf(tester, find.text('Same old'))),
    );
  });

  testWidgets(
    'search uses backend search and blank search returns normal list',
    (tester) async {
      await commonProblemRepository.createCommonProblem(
        CreateCommonProblemInput(title: 'Does not charge'),
      );
      await commonProblemRepository.createCommonProblem(
        CreateCommonProblemInput(title: 'Broken screen'),
      );

      await _pumpCommonProblemsPage(tester, database);

      await tester.enterText(
        _textFieldIn(const Key('common-problems-search-field')),
        'CHARGE',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Does not charge'), findsOneWidget);
      expect(find.text('Broken screen'), findsNothing);

      await tester.enterText(
        _textFieldIn(const Key('common-problems-search-field')),
        'missing',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('No matching problems'), findsOneWidget);
      expect(find.text('Try a different search.'), findsOneWidget);

      await tester.enterText(
        _textFieldIn(const Key('common-problems-search-field')),
        '',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Does not charge'), findsOneWidget);
      expect(find.text('Broken screen'), findsOneWidget);
    },
  );

  testWidgets('add dialog validates, creates, and shows duplicate safely', (
    tester,
  ) async {
    await _pumpCommonProblemsPage(tester, database);

    await _tapVisible(
      tester,
      find.byKey(const Key('common-problems-add-button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('common-problem-dialog-submit')));
    await tester.pump();
    expect(find.text('Problem is required.'), findsOneWidget);

    await tester.enterText(
      _textFieldIn(const Key('common-problem-title-field')),
      '  Does   not charge  ',
    );
    await tester.tap(find.byKey(const Key('common-problem-dialog-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Does not charge'), findsOneWidget);
    expect(find.text('Used 0 times'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const Key('common-problems-add-button')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      _textFieldIn(const Key('common-problem-title-field')),
      'does not charge',
    );
    await tester.tap(find.byKey(const Key('common-problem-dialog-submit')));
    await tester.pumpAndSettle();

    expect(find.text('This problem already exists.'), findsOneWidget);
    expect(find.text('does not charge'), findsOneWidget);
  });

  testWidgets('edit dialog renames while preserving usage count', (
    tester,
  ) async {
    final problem = await commonProblemRepository.createCommonProblem(
      CreateCommonProblemInput(title: 'Broken screen'),
    );
    await commonProblemRepository.incrementUsage(problem.id!);

    await _pumpCommonProblemsPage(tester, database);

    await _tapVisible(
      tester,
      find.byKey(Key('common-problem-edit-${problem.id}')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Common Problem'), findsOneWidget);
    expect(find.text('Broken screen'), findsWidgets);

    await tester.enterText(
      _textFieldIn(const Key('common-problem-title-field')),
      'Cracked screen',
    );
    await tester.tap(find.byKey(const Key('common-problem-dialog-submit')));
    await tester.pumpAndSettle();

    final updated = await commonProblemRepository.getCommonProblemById(
      problem.id!,
    );
    expect(updated?.title, 'Cracked screen');
    expect(updated?.usageCount, 1);
    expect(find.text('Cracked screen'), findsOneWidget);
    expect(find.text('Used 1 time'), findsOneWidget);
  });

  testWidgets('duplicate rename shows safe error', (tester) async {
    final first = await commonProblemRepository.createCommonProblem(
      CreateCommonProblemInput(title: 'Does not charge'),
    );
    final second = await commonProblemRepository.createCommonProblem(
      CreateCommonProblemInput(title: 'Overheating'),
    );

    await _pumpCommonProblemsPage(tester, database);

    await _tapVisible(
      tester,
      find.byKey(Key('common-problem-edit-${second.id}')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      _textFieldIn(const Key('common-problem-title-field')),
      ' does   not charge ',
    );
    await tester.tap(find.byKey(const Key('common-problem-dialog-submit')));
    await tester.pumpAndSettle();

    expect(find.text('This problem already exists.'), findsOneWidget);
    expect(
      await commonProblemRepository.getCommonProblemById(first.id!),
      isNotNull,
    );
    expect(
      (await commonProblemRepository.getCommonProblemById(second.id!))?.title,
      'Overheating',
    );
  });

  testWidgets('delete asks confirmation and does not modify existing repairs', (
    tester,
  ) async {
    final problem = await commonProblemRepository.createCommonProblem(
      CreateCommonProblemInput(title: 'Does not power on'),
    );
    final repairRepository = _repairRepository(database, () => now);
    final repair = await repairRepository.createRepair(
      CreateRepairInput(reportedProblem: problem.title),
    );

    await _pumpCommonProblemsPage(tester, database);

    await _tapVisible(
      tester,
      find.byKey(Key('common-problem-delete-${problem.id}')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete Common Problem?'), findsOneWidget);
    expect(
      find.text('This removes the template from your Common Problems list.'),
      findsOneWidget,
    );
    expect(find.text('Existing repairs will not be changed.'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      await commonProblemRepository.getCommonProblemById(problem.id!),
      isNotNull,
    );

    await _tapVisible(
      tester,
      find.byKey(Key('common-problem-delete-${problem.id}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(
      await commonProblemRepository.getCommonProblemById(problem.id!),
      isNull,
    );
    expect(find.text('Does not power on'), findsNothing);
    final reloadedRepair = await repairRepository.getRepairById(repair.id!);
    expect(reloadedRepair?.reportedProblem, 'Does not power on');
  });

  testWidgets('Settings card opens page and Back returns to Settings', (
    tester,
  ) async {
    await _setDesktopSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          localPrinterServiceProvider.overrideWithValue(
            const _EmptyLocalPrinterService(),
          ),
        ],
        child: const NovaRepairApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.byKey(const Key('settings-common-problems-card')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Manage frequently used repair problem templates'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('nova-sidebar-item-settings-selected')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('common-problems-back-to-settings')));
    await tester.pumpAndSettle();

    expect(
      find.text('Manage shop information and application preferences'),
      findsOneWidget,
    );
    expect(find.text('Shop Information'), findsOneWidget);
  });
}

Future<void> _pumpCommonProblemsPage(
  WidgetTester tester,
  AppDatabase database,
) async {
  await _setDesktopSurface(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: CommonProblemsPage(onBackToSettings: () {})),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _textFieldIn(Key key) {
  return find.descendant(of: find.byKey(key), matching: find.byType(TextField));
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

double _topOf(WidgetTester tester, Finder finder) {
  return tester.getTopLeft(finder).dy;
}

Future<void> _setDesktopSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1200);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

DriftCommonProblemRepository _commonProblemRepository(
  AppDatabase database,
  DateTime Function() now,
) {
  return DriftCommonProblemRepository(
    database,
    CommonProblemLocalDataSource(database),
    now: now,
  );
}

DriftRepairRepository _repairRepository(
  AppDatabase database,
  DateTime Function() now,
) {
  return DriftRepairRepository(
    database,
    RepairLocalDataSource(database),
    RepairCodeSequenceLocalDataSource(database),
    ShopSettingsLocalDataSource(database),
    now: now,
  );
}

NativeDatabase _inMemoryDatabase() {
  return NativeDatabase.memory(
    setup: (database) {
      database.execute('PRAGMA foreign_keys = ON');
    },
  );
}

class _EmptyLocalPrinterService implements LocalPrinterService {
  const _EmptyLocalPrinterService();

  @override
  Future<LocalPrinter?> getDefaultPrinter() async => null;

  @override
  Future<List<LocalPrinter>> listPrinters() async => const [];

  @override
  Future<PrintResult> printDocument({
    required PrintPrinterTarget printerTarget,
    required RenderedPrintDocument document,
    required int copies,
  }) async {
    return PrintResult.failed(
      failureKind: PrintFailureKind.noPrinterAvailable,
      message: 'No printer is available.',
    );
  }
}
