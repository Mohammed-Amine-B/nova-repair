import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/features/online_tracking/application/build_public_repair_tracking_snapshot.dart';
import 'package:nova_repair/features/online_tracking/domain/public_repair_tracking_snapshot.dart';
import 'package:nova_repair/features/online_tracking/domain/public_tracking_contract.dart';
import 'package:nova_repair/features/online_tracking/domain/public_tracking_identity.dart';
import 'package:nova_repair/features/repairs/domain/customer_price_decision.dart';
import 'package:nova_repair/features/repairs/domain/entities/repair.dart';
import 'package:nova_repair/features/repairs/domain/repair_status.dart';
import 'package:nova_repair/features/settings/domain/entities/shop_settings.dart';

void main() {
  const builder = BuildPublicRepairTrackingSnapshot();

  group('PublicRepairTrackingSnapshot', () {
    test('includes only approved public fields', () {
      final snapshot = builder(
        repair: _repair(),
        settings: _settings(shopSubtitle: 'Authorized Service Center'),
        identity: _identity(),
      );

      expect(snapshot.contractVersion, 1);
      expect(snapshot.trackingToken, 'track_A7z9-xTOKEN_2026');
      expect(snapshot.publicShopId, 'shop_public_01');
      expect(snapshot.shopName, 'Nova Repair');
      expect(snapshot.shopSubtitle, 'Authorized Service Center');
      expect(snapshot.repairCode, 'REP-0042');
      expect(snapshot.deviceDisplayName, 'Samsung Galaxy S23');
      expect(snapshot.status, RepairStatus.waitingForCustomerApproval);
      expect(snapshot.customerMessage, 'Waiting for your approval.');
      expect(snapshot.receivedAt, DateTime.utc(2026, 7, 1, 8, 30));
      expect(snapshot.updatedAt, DateTime.utc(2026, 7, 2, 9, 45));
    });

    test('public JSON contract excludes sensitive and internal fields', () {
      final snapshot = builder(
        repair: _repair(
          customerName: 'Amina Private',
          customerPhone: '+213555000111',
          deviceAccessInfo: 'PIN 1234',
          internalNotes: 'Technician-only note',
          reportedProblem: 'Common Problem: screen issue',
          receivedAccessories: 'Charger and bag',
          priceAmount: 6500,
          customerPriceDecision: CustomerPriceDecision.approved,
        ),
        settings: _settings(
          defaultCustomerTicketPrinterId: 'ticket-printer-private',
          defaultDeviceLabelPrinterId: 'label-printer-private',
        ),
        identity: _identity(),
      );

      final encoded = jsonEncode(snapshot.toJson());

      expect(encoded, isNot(contains('Amina Private')));
      expect(encoded, isNot(contains('+213555000111')));
      expect(encoded, isNot(contains('PIN 1234')));
      expect(encoded, isNot(contains('Technician-only note')));
      expect(encoded, isNot(contains('6500')));
      expect(encoded, isNot(contains('approved')));
      expect(encoded, isNot(contains('Charger and bag')));
      expect(encoded, isNot(contains('Common Problem')));
      expect(encoded, isNot(contains('ticket-printer-private')));
      expect(encoded, isNot(contains('label-printer-private')));
      expect(encoded, isNot(contains('"id"')));
      expect(encoded, isNot(contains('"customerName"')));
      expect(encoded, isNot(contains('"customerPhone"')));
      expect(encoded, isNot(contains('"priceAmount"')));
      expect(encoded, isNot(contains('"customerPriceDecision"')));
      expect(encoded, isNot(contains('"internalNotes"')));
      expect(encoded, isNot(contains('"deviceAccessInfo"')));
    });

    test('serializes all statuses to stable explicit wire values', () {
      expect(
        {
          for (final status in RepairStatus.values)
            status: PublicTrackingContract.statusToWireValue(status),
        },
        {
          RepairStatus.received: 'received',
          RepairStatus.diagnosing: 'diagnosing',
          RepairStatus.waitingForCustomerApproval:
              'waiting_for_customer_approval',
          RepairStatus.waitingForPart: 'waiting_for_part',
          RepairStatus.repairing: 'repairing',
          RepairStatus.readyForPickup: 'ready_for_pickup',
          RepairStatus.delivered: 'delivered',
          RepairStatus.cancelled: 'cancelled',
        },
      );

      for (final status in RepairStatus.values) {
        expect(
          PublicTrackingContract.statusFromWireValue(
            PublicTrackingContract.statusToWireValue(status),
          ),
          status,
        );
      }
    });

    test('flexible workflow snapshot reflects only current status', () {
      final identity = _identity();
      final settings = _settings();
      final readySnapshot = builder(
        repair: _repair(status: RepairStatus.readyForPickup),
        settings: settings,
        identity: identity,
      );
      final reworkSnapshot = builder(
        repair: _repair(status: RepairStatus.repairing),
        settings: settings,
        identity: identity,
      );

      expect(readySnapshot.trackingToken, reworkSnapshot.trackingToken);
      expect(readySnapshot.publicShopId, reworkSnapshot.publicShopId);
      expect(readySnapshot.status, RepairStatus.readyForPickup);
      expect(reworkSnapshot.status, RepairStatus.repairing);
      expect(
        reworkSnapshot.toJson()['repair'],
        containsPair('status', 'repairing'),
      );
    });

    test(
      'customer message is null when absent or blank and preserved when set',
      () {
        final absent = builder(
          repair: _repair(customerMessage: null),
          settings: _settings(),
          identity: _identity(),
        );
        final blank = builder(
          repair: _repair(customerMessage: '   '),
          settings: _settings(),
          identity: _identity(),
        );
        final present = builder(
          repair: _repair(customerMessage: '  Device is ready.  '),
          settings: _settings(),
          identity: _identity(),
        );

        expect(absent.customerMessage, isNull);
        expect(blank.customerMessage, isNull);
        expect(present.customerMessage, '  Device is ready.  ');
        expect((absent.toJson()['repair'] as Map)['customerMessage'], isNull);
      },
    );

    test('contract version and JSON round-trip are stable', () {
      final snapshot = builder(
        repair: _repair(),
        settings: _settings(shopSubtitle: 'Service Center'),
        identity: _identity(),
      );

      expect(PublicTrackingContract.currentVersion, 1);
      expect(snapshot.contractVersion, PublicTrackingContract.currentVersion);

      final decoded = jsonDecode(jsonEncode(snapshot.toJson()));
      final roundTripped = PublicRepairTrackingSnapshot.fromJson(
        Map<String, Object?>.from(decoded as Map),
      );

      expect(roundTripped.contractVersion, snapshot.contractVersion);
      expect(roundTripped.trackingToken, snapshot.trackingToken);
      expect(roundTripped.publicShopId, snapshot.publicShopId);
      expect(roundTripped.shopName, snapshot.shopName);
      expect(roundTripped.shopSubtitle, snapshot.shopSubtitle);
      expect(roundTripped.repairCode, snapshot.repairCode);
      expect(roundTripped.deviceDisplayName, snapshot.deviceDisplayName);
      expect(roundTripped.status, snapshot.status);
      expect(roundTripped.customerMessage, snapshot.customerMessage);
      expect(roundTripped.receivedAt, snapshot.receivedAt);
      expect(roundTripped.updatedAt, snapshot.updatedAt);
    });

    test('tracking identity trims values and rejects blanks', () {
      final identity = PublicTrackingIdentity(
        trackingToken: '  token-url-safe  ',
        publicShopId: '  shop-id  ',
      );

      expect(identity.trackingToken, 'token-url-safe');
      expect(identity.publicShopId, 'shop-id');
      expect(
        () =>
            PublicTrackingIdentity(trackingToken: ' ', publicShopId: 'shop-id'),
        throwsArgumentError,
      );
      expect(
        () => PublicTrackingIdentity(trackingToken: 'token', publicShopId: ' '),
        throwsArgumentError,
      );
    });
  });
}

PublicTrackingIdentity _identity() {
  return PublicTrackingIdentity(
    trackingToken: 'track_A7z9-xTOKEN_2026',
    publicShopId: 'shop_public_01',
  );
}

ShopSettings _settings({
  String? shopSubtitle,
  String? defaultCustomerTicketPrinterId,
  String? defaultDeviceLabelPrinterId,
}) {
  final now = DateTime.utc(2026, 7, 1);
  return ShopSettings(
    shopName: 'Nova Repair',
    shopSubtitle: shopSubtitle,
    defaultCustomerTicketPrinterId: defaultCustomerTicketPrinterId,
    defaultDeviceLabelPrinterId: defaultDeviceLabelPrinterId,
    createdAt: now,
    updatedAt: now,
  );
}

Repair _repair({
  int? id = 42,
  String? customerName = 'Amina Private',
  String? customerPhone = '+213555000111',
  String? deviceAccessInfo = 'PIN 1234',
  String? internalNotes = 'Technician-only note',
  String reportedProblem = 'Screen flickers',
  String? receivedAccessories = 'Charger and bag',
  int? priceAmount = 6500,
  CustomerPriceDecision customerPriceDecision = CustomerPriceDecision.pending,
  RepairStatus status = RepairStatus.waitingForCustomerApproval,
  String? customerMessage = 'Waiting for your approval.',
}) {
  return Repair(
    id: id,
    repairCode: 'REP-0042',
    customerName: customerName,
    customerPhone: customerPhone,
    deviceType: 'Phone',
    brand: 'Samsung',
    model: 'Galaxy S23',
    reportedProblem: reportedProblem,
    receivedAccessories: receivedAccessories,
    deviceAccessInfo: deviceAccessInfo,
    status: status,
    priceAmount: priceAmount,
    customerPriceDecision: customerPriceDecision,
    internalNotes: internalNotes,
    customerMessage: customerMessage,
    createdAt: DateTime.utc(2026, 7, 1, 8),
    receivedAt: DateTime.utc(2026, 7, 1, 8, 30),
    updatedAt: DateTime.utc(2026, 7, 2, 9, 45),
  );
}
