import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/app/navigation/app_destination.dart';
import 'package:nova_repair/app/theme/app_theme.dart';
import 'package:nova_repair/app/widgets/bottom_action_bar.dart';
import 'package:nova_repair/app/widgets/buttons/app_buttons.dart';
import 'package:nova_repair/app/widgets/dialogs/confirmation_dialog.dart';
import 'package:nova_repair/app/widgets/empty_value_text.dart';
import 'package:nova_repair/app/widgets/form/app_text_field.dart';
import 'package:nova_repair/app/widgets/form/form_section.dart';
import 'package:nova_repair/app/widgets/nova_sidebar.dart';
import 'package:nova_repair/app/widgets/page_header.dart';
import 'package:nova_repair/app/widgets/section_card.dart';
import 'package:nova_repair/app/widgets/status_badge.dart';
import 'package:nova_repair/app/widgets/table/app_table_shell.dart';
import 'package:nova_repair/features/repairs/domain/repair_status.dart';

void main() {
  Widget themed(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('NovaSidebar shows approved navigation and shop identity', (
    tester,
  ) async {
    AppDestination? selected;

    await tester.pumpWidget(
      themed(
        NovaSidebar(
          selectedDestination: AppDestination.repairs,
          shopName: 'Nova Tech Repair',
          shopSubtitle: 'Repair Center',
          onDestinationSelected: (destination) => selected = destination,
        ),
      ),
    );

    expect(find.text('Nova Repair'), findsOneWidget);
    expect(find.text('Management System'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Repairs'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Nova Tech Repair'), findsOneWidget);
    expect(find.text('Repair Center'), findsOneWidget);
    expect(find.text('Admin User'), findsNothing);
    expect(find.text('Manager'), findsNothing);
    expect(
      find.byKey(const Key('nova-sidebar-item-repairs-selected')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('nova-sidebar-item-settings')));
    await tester.pump();

    expect(selected, AppDestination.settings);
  });

  testWidgets('PageHeader renders title, subtitle, and optional actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      themed(
        const PageHeader(
          title: 'Repairs',
          subtitle: 'Manage repair jobs',
          actions: [PrimaryButton(label: 'New Repair', onPressed: null)],
        ),
      ),
    );

    expect(find.text('Repairs'), findsOneWidget);
    expect(find.text('Manage repair jobs'), findsOneWidget);
    expect(find.text('New Repair'), findsOneWidget);

    await tester.pumpWidget(
      themed(const PageHeader(title: 'Settings', subtitle: 'Configure shop')),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Configure shop'), findsOneWidget);
  });

  testWidgets('StatusBadge maps every repair status to display labels', (
    tester,
  ) async {
    final labels = <RepairStatus, String>{
      RepairStatus.received: 'Received',
      RepairStatus.diagnosing: 'Diagnosing',
      RepairStatus.waitingForCustomerApproval: 'Waiting for Customer Approval',
      RepairStatus.waitingForPart: 'Waiting for Part',
      RepairStatus.repairing: 'Repairing',
      RepairStatus.readyForPickup: 'Ready for Pickup',
      RepairStatus.delivered: 'Delivered',
      RepairStatus.cancelled: 'Cancelled',
    };

    await tester.pumpWidget(
      themed(
        Wrap(
          children: [
            for (final status in RepairStatus.values)
              StatusBadge(status: status),
          ],
        ),
      ),
    );

    for (final entry in labels.entries) {
      expect(find.text(entry.value), findsOneWidget);
      expect(find.text(entry.key.databaseValue), findsNothing);
    }
  });

  testWidgets('EmptyValueText renders the approved empty marker', (
    tester,
  ) async {
    await tester.pumpWidget(themed(const EmptyValueText()));

    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('shared buttons support callbacks and disabled state', (
    tester,
  ) async {
    var primaryCount = 0;
    var secondaryCount = 0;
    var disabledCount = 0;

    await tester.pumpWidget(
      themed(
        Column(
          children: [
            PrimaryButton(
              label: 'Save',
              icon: Icons.save_outlined,
              onPressed: () => primaryCount++,
            ),
            SecondaryButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              onPressed: () => secondaryCount++,
            ),
            PrimaryButton(label: 'Disabled', onPressed: null),
            SecondaryButton(label: 'Disabled Secondary', onPressed: null),
            GhostButton(label: 'Cancel', onPressed: () => disabledCount++),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.tap(find.text('Edit'));
    await tester.tap(find.text('Disabled'));
    await tester.pump();

    expect(primaryCount, 1);
    expect(secondaryCount, 1);
    expect(disabledCount, 0);
  });

  testWidgets('form controls render labels and accept input', (tester) async {
    var changed = '';
    final controller = TextEditingController(text: 'Fixed value');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      themed(
        Column(
          children: [
            AppTextField(
              label: 'Customer Name',
              helperText: 'Optional',
              placeholder: 'Full name',
              onChanged: (value) => changed = value,
            ),
            const AppTextArea(
              label: 'Reported Problem',
              helperText: 'Describe the issue',
              placeholder: 'Problem details',
              minLines: 4,
            ),
            AppTextField(
              label: 'Read Only',
              controller: controller,
              readOnly: true,
            ),
            const FormSection(
              title: 'Customer Information',
              description: 'Basic intake details',
              child: SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Customer Name'), findsOneWidget);
    expect(find.text('Optional'), findsOneWidget);
    expect(find.text('Reported Problem'), findsOneWidget);
    expect(find.text('Describe the issue'), findsOneWidget);
    expect(find.text('Customer Information'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Ahmed');
    expect(changed, 'Ahmed');

    final readOnlyField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Fixed value'),
    );
    expect(readOnlyField.readOnly, isTrue);
  });

  testWidgets('table and section surfaces render provided content', (
    tester,
  ) async {
    await tester.pumpWidget(
      themed(
        const Column(
          children: [
            SectionCard(title: 'Overview', child: Text('Surface content')),
            AppTableShell(
              header: Text('HEADER'),
              child: AppTableRowShell(child: Text('Row content')),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Surface content'), findsOneWidget);
    expect(find.text('HEADER'), findsOneWidget);
    expect(find.text('Row content'), findsOneWidget);
  });

  testWidgets('BottomActionBar renders provided actions', (tester) async {
    await tester.pumpWidget(
      themed(
        const BottomActionBar(
          leftActions: [GhostButton(label: 'Cancel', onPressed: null)],
          actions: [
            SecondaryButton(label: 'Save Repair', onPressed: null),
            PrimaryButton(label: 'Save & Print', onPressed: null),
          ],
        ),
      ),
    );

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save Repair'), findsOneWidget);
    expect(find.text('Save & Print'), findsOneWidget);
  });

  testWidgets('ConfirmationDialog renders message and actions', (tester) async {
    var cancelled = false;
    var confirmed = false;

    await tester.pumpWidget(
      themed(
        ConfirmationDialog(
          title: 'Restore Backup?',
          message: 'Current data will be replaced.',
          icon: Icons.warning_amber_outlined,
          cancelLabel: 'Cancel',
          confirmLabel: 'Restore',
          destructive: true,
          onCancel: () => cancelled = true,
          onConfirm: () => confirmed = true,
        ),
      ),
    );

    expect(find.text('Restore Backup?'), findsOneWidget);
    expect(find.text('Current data will be replaced.'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.tap(find.text('Restore'));
    await tester.pump();

    expect(cancelled, isTrue);
    expect(confirmed, isTrue);
  });
}
