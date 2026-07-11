import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/app/app.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/database/database_provider.dart';
import 'package:nova_repair/features/printing/application/local_printer_service.dart';
import 'package:nova_repair/features/printing/application/print_printer_target.dart';
import 'package:nova_repair/features/printing/application/rendered_print_document.dart';
import 'package:nova_repair/features/printing/domain/entities/local_printer.dart';
import 'package:nova_repair/features/printing/domain/entities/print_result.dart';
import 'package:nova_repair/features/printing/printing_providers.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('shows dashboard by default', (tester) async {
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

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Overview of your repair activity'), findsOneWidget);
    expect(find.text('No repairs yet'), findsOneWidget);
  });

  testWidgets('navigates between app sections', (tester) async {
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

    await tester.tap(find.text('Repairs'));
    await tester.pumpAndSettle();

    expect(find.text('Manage and track all repair jobs'), findsOneWidget);
    expect(find.text('No repairs yet'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(
      find.text('Manage shop information and application preferences'),
      findsOneWidget,
    );
    expect(find.text('Shop Information'), findsOneWidget);
    expect(find.text('Common Problems'), findsOneWidget);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Overview of your repair activity'), findsOneWidget);
    expect(find.text('No repairs yet'), findsOneWidget);
  });
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
