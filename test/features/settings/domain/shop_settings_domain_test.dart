import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/features/settings/domain/entities/shop_settings.dart';

void main() {
  group('ShopSettings', () {
    test('creates valid settings', () {
      final now = DateTime.utc(2026, 1, 1, 9);

      final settings = ShopSettings(
        shopName: 'Nova Tech Repair',
        repairCodePrefix: 'FIX',
        repairCodeNumberWidth: 5,
        createdAt: now,
        updatedAt: now,
      );

      expect(settings.shopName, 'Nova Tech Repair');
      expect(settings.repairCodePrefix, 'FIX');
      expect(settings.repairCodeNumberWidth, 5);
    });

    test('normalizes optional text fields', () {
      final now = DateTime.utc(2026, 1, 1, 9);

      final settings = ShopSettings(
        shopName: ' Nova Tech Repair ',
        shopSubtitle: ' Repair Center ',
        phoneNumber: ' 0555000000 ',
        address: '   ',
        ticketFooter: ' Keep this ticket. ',
        warrantyTerms: '   ',
        defaultCustomerTicketPrinterId: ' printer-ticket-01 ',
        defaultDeviceLabelPrinterId: '   ',
        createdAt: now,
        updatedAt: now,
      );

      expect(settings.shopName, 'Nova Tech Repair');
      expect(settings.shopSubtitle, 'Repair Center');
      expect(settings.phoneNumber, '0555000000');
      expect(settings.address, isNull);
      expect(settings.ticketFooter, 'Keep this ticket.');
      expect(settings.warrantyTerms, isNull);
      expect(settings.defaultCustomerTicketPrinterId, 'printer-ticket-01');
      expect(settings.defaultDeviceLabelPrinterId, isNull);
    });

    test('preserves printer identifier case and content', () {
      final now = DateTime.utc(2026, 1, 1, 9);

      final settings = ShopSettings(
        shopName: 'Nova Tech Repair',
        defaultCustomerTicketPrinterId: r'Windows\Printer A',
        defaultDeviceLabelPrinterId: 'Label_Printer_02',
        createdAt: now,
        updatedAt: now,
      );

      expect(settings.defaultCustomerTicketPrinterId, r'Windows\Printer A');
      expect(settings.defaultDeviceLabelPrinterId, 'Label_Printer_02');
    });

    test('rejects blank shop name', () {
      final now = DateTime.utc(2026, 1, 1, 9);

      expect(
        () => ShopSettings(shopName: '   ', createdAt: now, updatedAt: now),
        throwsArgumentError,
      );
    });

    test('rejects blank repair prefix', () {
      final now = DateTime.utc(2026, 1, 1, 9);

      expect(
        () => ShopSettings(
          shopName: 'Nova Tech Repair',
          repairCodePrefix: '   ',
          createdAt: now,
          updatedAt: now,
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid repair prefix characters', () {
      final now = DateTime.utc(2026, 1, 1, 9);

      expect(
        () => ShopSettings(
          shopName: 'Nova Tech Repair',
          repairCodePrefix: 'RE-P',
          createdAt: now,
          updatedAt: now,
        ),
        throwsArgumentError,
      );
    });

    test('normalizes repair prefix to uppercase', () {
      final now = DateTime.utc(2026, 1, 1, 9);

      final settings = ShopSettings(
        shopName: 'Nova Tech Repair',
        repairCodePrefix: ' fix42 ',
        createdAt: now,
        updatedAt: now,
      );

      expect(settings.repairCodePrefix, 'FIX42');
    });

    test('enforces minimum repair code number width', () {
      final now = DateTime.utc(2026, 1, 1, 9);

      expect(
        () => ShopSettings(
          shopName: 'Nova Tech Repair',
          repairCodeNumberWidth: 2,
          createdAt: now,
          updatedAt: now,
        ),
        throwsArgumentError,
      );
    });

    test('enforces maximum repair code number width', () {
      final now = DateTime.utc(2026, 1, 1, 9);

      expect(
        () => ShopSettings(
          shopName: 'Nova Tech Repair',
          repairCodeNumberWidth: 9,
          createdAt: now,
          updatedAt: now,
        ),
        throwsArgumentError,
      );
    });
  });
}
