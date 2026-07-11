import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/app/theme/app_theme.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/database/database_provider.dart';
import 'package:nova_repair/features/common_problems/common_problem_providers.dart';
import 'package:nova_repair/features/common_problems/data/datasources/common_problem_local_data_source.dart';
import 'package:nova_repair/features/common_problems/data/repositories/drift_common_problem_repository.dart';
import 'package:nova_repair/features/common_problems/domain/entities/common_problem.dart';
import 'package:nova_repair/features/common_problems/domain/entities/create_common_problem_input.dart';
import 'package:nova_repair/features/common_problems/domain/entities/update_common_problem_input.dart';
import 'package:nova_repair/features/common_problems/domain/repositories/common_problem_repository.dart';
import 'package:nova_repair/features/repairs/presentation/common_problem_picker.dart';

void main() {
  late AppDatabase database;
  late DriftCommonProblemRepository repository;
  late DateTime now;

  setUp(() {
    now = DateTime.utc(2026, 7, 6, 9);
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftCommonProblemRepository(
      database,
      CommonProblemLocalDataSource(database),
      now: () => now,
    );
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('top Common Problems load with backend order and top five only', (
    tester,
  ) async {
    final problems = <CommonProblem>[];
    for (final title in [
      'Sixth',
      'Fifth',
      'Fourth',
      'Third',
      'Second',
      'First',
    ]) {
      problems.add(
        await repository.createCommonProblem(
          CreateCommonProblemInput(title: title),
        ),
      );
    }
    for (var index = 0; index < problems.length; index++) {
      for (var count = 0; count < index; count++) {
        now = now.add(const Duration(minutes: 1));
        await repository.incrementUsage(problems[index].id!);
      }
    }

    await _pumpPicker(tester, database);

    expect(find.text('Common Problems'), findsOneWidget);
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('Third'), findsOneWidget);
    expect(find.text('Fourth'), findsOneWidget);
    expect(find.text('Fifth'), findsOneWidget);
    expect(find.text('Sixth'), findsNothing);
    expect(
      _leftOf(tester, find.text('First')),
      lessThan(_leftOf(tester, find.text('Second'))),
    );
  });

  testWidgets('zero problems are handled without fake examples', (
    tester,
  ) async {
    await _pumpPicker(tester, database);

    expect(
      find.text(
        'Manage Common Problems in Settings to add quick problem templates.',
      ),
      findsOneWidget,
    );
    expect(find.text('Does not charge'), findsNothing);
    expect(find.text('Search Common Problems'), findsOneWidget);
  });

  testWidgets('debounced backend search emits selection and clears results', (
    tester,
  ) async {
    await repository.createCommonProblem(
      CreateCommonProblemInput(title: 'Does not charge'),
    );
    await repository.createCommonProblem(
      CreateCommonProblemInput(title: 'Broken screen'),
    );
    CommonProblem? selected;

    await _pumpPicker(
      tester,
      database,
      onSelected: (problem) => selected = problem,
    );

    await tester.enterText(
      _textFieldIn(const Key('common-problem-picker-search')),
      'CHARGE',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Does not charge'), findsWidgets);
    expect(find.text('Broken screen'), findsOneWidget);
    await tester.tap(
      find.byKey(Key('common-problem-search-result-${selected?.id ?? 1}')),
    );
    await tester.pumpAndSettle();

    expect(selected?.title, 'Does not charge');
    expect(
      _textFieldValue(const Key('common-problem-picker-search'), tester),
      '',
    );
  });

  testWidgets('load failure does not block manual typing nearby', (
    tester,
  ) async {
    final manualController = TextEditingController();
    addTearDown(manualController.dispose);

    await _setDesktopSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commonProblemRepositoryProvider.overrideWithValue(
            const _ThrowingCommonProblemRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Column(
              children: [
                CommonProblemPicker(onProblemSelected: (_) {}),
                TextField(
                  key: const Key('manual-problem-field'),
                  controller: manualController,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Common problems could not be loaded.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('manual-problem-field')),
      'Manual text',
    );
    expect(manualController.text, 'Manual text');
  });
}

Future<void> _pumpPicker(
  WidgetTester tester,
  AppDatabase database, {
  ValueChanged<CommonProblem>? onSelected,
}) async {
  await _setDesktopSurface(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: CommonProblemPicker(onProblemSelected: onSelected ?? (_) {}),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _textFieldIn(Key key) {
  return find.descendant(of: find.byKey(key), matching: find.byType(TextField));
}

String _textFieldValue(Key key, WidgetTester tester) {
  final editable = tester.widget<EditableText>(
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText)),
  );
  return editable.controller.text;
}

double _leftOf(WidgetTester tester, Finder finder) {
  return tester.getTopLeft(finder).dx;
}

Future<void> _setDesktopSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 900);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _ThrowingCommonProblemRepository implements CommonProblemRepository {
  const _ThrowingCommonProblemRepository();

  @override
  Future<CommonProblem> createCommonProblem(CreateCommonProblemInput input) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCommonProblem(int id) {
    throw UnimplementedError();
  }

  @override
  Future<CommonProblem?> getCommonProblemById(int id) {
    throw UnimplementedError();
  }

  @override
  Future<CommonProblem> incrementUsage(int id) {
    throw StateError('boom');
  }

  @override
  Future<List<CommonProblem>> listCommonProblems() {
    throw StateError('boom');
  }

  @override
  Future<List<CommonProblem>> searchCommonProblems(String query) {
    throw StateError('boom');
  }

  @override
  Future<CommonProblem> updateCommonProblemTitle(
    UpdateCommonProblemInput input,
  ) {
    throw UnimplementedError();
  }
}
