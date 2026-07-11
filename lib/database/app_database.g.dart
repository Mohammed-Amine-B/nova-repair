// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RepairsTable extends Repairs with TableInfo<$RepairsTable, RepairRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RepairsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _repairCodeMeta = const VerificationMeta(
    'repairCode',
  );
  @override
  late final GeneratedColumn<String> repairCode = GeneratedColumn<String>(
    'repair_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerPhoneMeta = const VerificationMeta(
    'customerPhone',
  );
  @override
  late final GeneratedColumn<String> customerPhone = GeneratedColumn<String>(
    'customer_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceTypeMeta = const VerificationMeta(
    'deviceType',
  );
  @override
  late final GeneratedColumn<String> deviceType = GeneratedColumn<String>(
    'device_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reportedProblemMeta = const VerificationMeta(
    'reportedProblem',
  );
  @override
  late final GeneratedColumn<String> reportedProblem = GeneratedColumn<String>(
    'reported_problem',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAccessoriesMeta =
      const VerificationMeta('receivedAccessories');
  @override
  late final GeneratedColumn<String> receivedAccessories =
      GeneratedColumn<String>(
        'received_accessories',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deviceAccessInfoMeta = const VerificationMeta(
    'deviceAccessInfo',
  );
  @override
  late final GeneratedColumn<String> deviceAccessInfo = GeneratedColumn<String>(
    'device_access_info',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceAmountMeta = const VerificationMeta(
    'priceAmount',
  );
  @override
  late final GeneratedColumn<int> priceAmount = GeneratedColumn<int>(
    'price_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NULL CHECK(price_amount >= 0)',
  );
  static const VerificationMeta _customerPriceDecisionMeta =
      const VerificationMeta('customerPriceDecision');
  @override
  late final GeneratedColumn<String> customerPriceDecision =
      GeneratedColumn<String>(
        'customer_price_decision',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('not_requested'),
      );
  static const VerificationMeta _internalNotesMeta = const VerificationMeta(
    'internalNotes',
  );
  @override
  late final GeneratedColumn<String> internalNotes = GeneratedColumn<String>(
    'internal_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerMessageMeta = const VerificationMeta(
    'customerMessage',
  );
  @override
  late final GeneratedColumn<String> customerMessage = GeneratedColumn<String>(
    'customer_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentRepairIdMeta = const VerificationMeta(
    'parentRepairId',
  );
  @override
  late final GeneratedColumn<int> parentRepairId = GeneratedColumn<int>(
    'parent_repair_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NULL REFERENCES repairs(id) ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _trackingTokenMeta = const VerificationMeta(
    'trackingToken',
  );
  @override
  late final GeneratedColumn<String> trackingToken = GeneratedColumn<String>(
    'tracking_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readyAtMeta = const VerificationMeta(
    'readyAt',
  );
  @override
  late final GeneratedColumn<DateTime> readyAt = GeneratedColumn<DateTime>(
    'ready_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deliveredAtMeta = const VerificationMeta(
    'deliveredAt',
  );
  @override
  late final GeneratedColumn<DateTime> deliveredAt = GeneratedColumn<DateTime>(
    'delivered_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    repairCode,
    customerName,
    customerPhone,
    deviceType,
    brand,
    model,
    reportedProblem,
    receivedAccessories,
    deviceAccessInfo,
    status,
    priceAmount,
    customerPriceDecision,
    internalNotes,
    customerMessage,
    parentRepairId,
    trackingToken,
    createdAt,
    updatedAt,
    receivedAt,
    readyAt,
    deliveredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'repairs';
  @override
  VerificationContext validateIntegrity(
    Insertable<RepairRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('repair_code')) {
      context.handle(
        _repairCodeMeta,
        repairCode.isAcceptableOrUnknown(data['repair_code']!, _repairCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_repairCodeMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('customer_phone')) {
      context.handle(
        _customerPhoneMeta,
        customerPhone.isAcceptableOrUnknown(
          data['customer_phone']!,
          _customerPhoneMeta,
        ),
      );
    }
    if (data.containsKey('device_type')) {
      context.handle(
        _deviceTypeMeta,
        deviceType.isAcceptableOrUnknown(data['device_type']!, _deviceTypeMeta),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('reported_problem')) {
      context.handle(
        _reportedProblemMeta,
        reportedProblem.isAcceptableOrUnknown(
          data['reported_problem']!,
          _reportedProblemMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reportedProblemMeta);
    }
    if (data.containsKey('received_accessories')) {
      context.handle(
        _receivedAccessoriesMeta,
        receivedAccessories.isAcceptableOrUnknown(
          data['received_accessories']!,
          _receivedAccessoriesMeta,
        ),
      );
    }
    if (data.containsKey('device_access_info')) {
      context.handle(
        _deviceAccessInfoMeta,
        deviceAccessInfo.isAcceptableOrUnknown(
          data['device_access_info']!,
          _deviceAccessInfoMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('price_amount')) {
      context.handle(
        _priceAmountMeta,
        priceAmount.isAcceptableOrUnknown(
          data['price_amount']!,
          _priceAmountMeta,
        ),
      );
    }
    if (data.containsKey('customer_price_decision')) {
      context.handle(
        _customerPriceDecisionMeta,
        customerPriceDecision.isAcceptableOrUnknown(
          data['customer_price_decision']!,
          _customerPriceDecisionMeta,
        ),
      );
    }
    if (data.containsKey('internal_notes')) {
      context.handle(
        _internalNotesMeta,
        internalNotes.isAcceptableOrUnknown(
          data['internal_notes']!,
          _internalNotesMeta,
        ),
      );
    }
    if (data.containsKey('customer_message')) {
      context.handle(
        _customerMessageMeta,
        customerMessage.isAcceptableOrUnknown(
          data['customer_message']!,
          _customerMessageMeta,
        ),
      );
    }
    if (data.containsKey('parent_repair_id')) {
      context.handle(
        _parentRepairIdMeta,
        parentRepairId.isAcceptableOrUnknown(
          data['parent_repair_id']!,
          _parentRepairIdMeta,
        ),
      );
    }
    if (data.containsKey('tracking_token')) {
      context.handle(
        _trackingTokenMeta,
        trackingToken.isAcceptableOrUnknown(
          data['tracking_token']!,
          _trackingTokenMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('ready_at')) {
      context.handle(
        _readyAtMeta,
        readyAt.isAcceptableOrUnknown(data['ready_at']!, _readyAtMeta),
      );
    }
    if (data.containsKey('delivered_at')) {
      context.handle(
        _deliveredAtMeta,
        deliveredAt.isAcceptableOrUnknown(
          data['delivered_at']!,
          _deliveredAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RepairRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RepairRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      repairCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repair_code'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      ),
      customerPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_phone'],
      ),
      deviceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_type'],
      ),
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      reportedProblem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reported_problem'],
      )!,
      receivedAccessories: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}received_accessories'],
      ),
      deviceAccessInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_access_info'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      priceAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_amount'],
      ),
      customerPriceDecision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_price_decision'],
      )!,
      internalNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}internal_notes'],
      ),
      customerMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_message'],
      ),
      parentRepairId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_repair_id'],
      ),
      trackingToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tracking_token'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      readyAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ready_at'],
      ),
      deliveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}delivered_at'],
      ),
    );
  }

  @override
  $RepairsTable createAlias(String alias) {
    return $RepairsTable(attachedDatabase, alias);
  }
}

class RepairRow extends DataClass implements Insertable<RepairRow> {
  final int id;
  final String repairCode;
  final String? customerName;
  final String? customerPhone;
  final String? deviceType;
  final String? brand;
  final String? model;
  final String reportedProblem;
  final String? receivedAccessories;
  final String? deviceAccessInfo;
  final String status;
  final int? priceAmount;
  final String customerPriceDecision;
  final String? internalNotes;
  final String? customerMessage;
  final int? parentRepairId;
  final String? trackingToken;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime receivedAt;
  final DateTime? readyAt;
  final DateTime? deliveredAt;
  const RepairRow({
    required this.id,
    required this.repairCode,
    this.customerName,
    this.customerPhone,
    this.deviceType,
    this.brand,
    this.model,
    required this.reportedProblem,
    this.receivedAccessories,
    this.deviceAccessInfo,
    required this.status,
    this.priceAmount,
    required this.customerPriceDecision,
    this.internalNotes,
    this.customerMessage,
    this.parentRepairId,
    this.trackingToken,
    required this.createdAt,
    required this.updatedAt,
    required this.receivedAt,
    this.readyAt,
    this.deliveredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['repair_code'] = Variable<String>(repairCode);
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || customerPhone != null) {
      map['customer_phone'] = Variable<String>(customerPhone);
    }
    if (!nullToAbsent || deviceType != null) {
      map['device_type'] = Variable<String>(deviceType);
    }
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    map['reported_problem'] = Variable<String>(reportedProblem);
    if (!nullToAbsent || receivedAccessories != null) {
      map['received_accessories'] = Variable<String>(receivedAccessories);
    }
    if (!nullToAbsent || deviceAccessInfo != null) {
      map['device_access_info'] = Variable<String>(deviceAccessInfo);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || priceAmount != null) {
      map['price_amount'] = Variable<int>(priceAmount);
    }
    map['customer_price_decision'] = Variable<String>(customerPriceDecision);
    if (!nullToAbsent || internalNotes != null) {
      map['internal_notes'] = Variable<String>(internalNotes);
    }
    if (!nullToAbsent || customerMessage != null) {
      map['customer_message'] = Variable<String>(customerMessage);
    }
    if (!nullToAbsent || parentRepairId != null) {
      map['parent_repair_id'] = Variable<int>(parentRepairId);
    }
    if (!nullToAbsent || trackingToken != null) {
      map['tracking_token'] = Variable<String>(trackingToken);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['received_at'] = Variable<DateTime>(receivedAt);
    if (!nullToAbsent || readyAt != null) {
      map['ready_at'] = Variable<DateTime>(readyAt);
    }
    if (!nullToAbsent || deliveredAt != null) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt);
    }
    return map;
  }

  RepairsCompanion toCompanion(bool nullToAbsent) {
    return RepairsCompanion(
      id: Value(id),
      repairCode: Value(repairCode),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      customerPhone: customerPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(customerPhone),
      deviceType: deviceType == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceType),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      reportedProblem: Value(reportedProblem),
      receivedAccessories: receivedAccessories == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedAccessories),
      deviceAccessInfo: deviceAccessInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceAccessInfo),
      status: Value(status),
      priceAmount: priceAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(priceAmount),
      customerPriceDecision: Value(customerPriceDecision),
      internalNotes: internalNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(internalNotes),
      customerMessage: customerMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(customerMessage),
      parentRepairId: parentRepairId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentRepairId),
      trackingToken: trackingToken == null && nullToAbsent
          ? const Value.absent()
          : Value(trackingToken),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      receivedAt: Value(receivedAt),
      readyAt: readyAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readyAt),
      deliveredAt: deliveredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveredAt),
    );
  }

  factory RepairRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RepairRow(
      id: serializer.fromJson<int>(json['id']),
      repairCode: serializer.fromJson<String>(json['repairCode']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      customerPhone: serializer.fromJson<String?>(json['customerPhone']),
      deviceType: serializer.fromJson<String?>(json['deviceType']),
      brand: serializer.fromJson<String?>(json['brand']),
      model: serializer.fromJson<String?>(json['model']),
      reportedProblem: serializer.fromJson<String>(json['reportedProblem']),
      receivedAccessories: serializer.fromJson<String?>(
        json['receivedAccessories'],
      ),
      deviceAccessInfo: serializer.fromJson<String?>(json['deviceAccessInfo']),
      status: serializer.fromJson<String>(json['status']),
      priceAmount: serializer.fromJson<int?>(json['priceAmount']),
      customerPriceDecision: serializer.fromJson<String>(
        json['customerPriceDecision'],
      ),
      internalNotes: serializer.fromJson<String?>(json['internalNotes']),
      customerMessage: serializer.fromJson<String?>(json['customerMessage']),
      parentRepairId: serializer.fromJson<int?>(json['parentRepairId']),
      trackingToken: serializer.fromJson<String?>(json['trackingToken']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      readyAt: serializer.fromJson<DateTime?>(json['readyAt']),
      deliveredAt: serializer.fromJson<DateTime?>(json['deliveredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'repairCode': serializer.toJson<String>(repairCode),
      'customerName': serializer.toJson<String?>(customerName),
      'customerPhone': serializer.toJson<String?>(customerPhone),
      'deviceType': serializer.toJson<String?>(deviceType),
      'brand': serializer.toJson<String?>(brand),
      'model': serializer.toJson<String?>(model),
      'reportedProblem': serializer.toJson<String>(reportedProblem),
      'receivedAccessories': serializer.toJson<String?>(receivedAccessories),
      'deviceAccessInfo': serializer.toJson<String?>(deviceAccessInfo),
      'status': serializer.toJson<String>(status),
      'priceAmount': serializer.toJson<int?>(priceAmount),
      'customerPriceDecision': serializer.toJson<String>(customerPriceDecision),
      'internalNotes': serializer.toJson<String?>(internalNotes),
      'customerMessage': serializer.toJson<String?>(customerMessage),
      'parentRepairId': serializer.toJson<int?>(parentRepairId),
      'trackingToken': serializer.toJson<String?>(trackingToken),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'readyAt': serializer.toJson<DateTime?>(readyAt),
      'deliveredAt': serializer.toJson<DateTime?>(deliveredAt),
    };
  }

  RepairRow copyWith({
    int? id,
    String? repairCode,
    Value<String?> customerName = const Value.absent(),
    Value<String?> customerPhone = const Value.absent(),
    Value<String?> deviceType = const Value.absent(),
    Value<String?> brand = const Value.absent(),
    Value<String?> model = const Value.absent(),
    String? reportedProblem,
    Value<String?> receivedAccessories = const Value.absent(),
    Value<String?> deviceAccessInfo = const Value.absent(),
    String? status,
    Value<int?> priceAmount = const Value.absent(),
    String? customerPriceDecision,
    Value<String?> internalNotes = const Value.absent(),
    Value<String?> customerMessage = const Value.absent(),
    Value<int?> parentRepairId = const Value.absent(),
    Value<String?> trackingToken = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? receivedAt,
    Value<DateTime?> readyAt = const Value.absent(),
    Value<DateTime?> deliveredAt = const Value.absent(),
  }) => RepairRow(
    id: id ?? this.id,
    repairCode: repairCode ?? this.repairCode,
    customerName: customerName.present ? customerName.value : this.customerName,
    customerPhone: customerPhone.present
        ? customerPhone.value
        : this.customerPhone,
    deviceType: deviceType.present ? deviceType.value : this.deviceType,
    brand: brand.present ? brand.value : this.brand,
    model: model.present ? model.value : this.model,
    reportedProblem: reportedProblem ?? this.reportedProblem,
    receivedAccessories: receivedAccessories.present
        ? receivedAccessories.value
        : this.receivedAccessories,
    deviceAccessInfo: deviceAccessInfo.present
        ? deviceAccessInfo.value
        : this.deviceAccessInfo,
    status: status ?? this.status,
    priceAmount: priceAmount.present ? priceAmount.value : this.priceAmount,
    customerPriceDecision: customerPriceDecision ?? this.customerPriceDecision,
    internalNotes: internalNotes.present
        ? internalNotes.value
        : this.internalNotes,
    customerMessage: customerMessage.present
        ? customerMessage.value
        : this.customerMessage,
    parentRepairId: parentRepairId.present
        ? parentRepairId.value
        : this.parentRepairId,
    trackingToken: trackingToken.present
        ? trackingToken.value
        : this.trackingToken,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    receivedAt: receivedAt ?? this.receivedAt,
    readyAt: readyAt.present ? readyAt.value : this.readyAt,
    deliveredAt: deliveredAt.present ? deliveredAt.value : this.deliveredAt,
  );
  RepairRow copyWithCompanion(RepairsCompanion data) {
    return RepairRow(
      id: data.id.present ? data.id.value : this.id,
      repairCode: data.repairCode.present
          ? data.repairCode.value
          : this.repairCode,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerPhone: data.customerPhone.present
          ? data.customerPhone.value
          : this.customerPhone,
      deviceType: data.deviceType.present
          ? data.deviceType.value
          : this.deviceType,
      brand: data.brand.present ? data.brand.value : this.brand,
      model: data.model.present ? data.model.value : this.model,
      reportedProblem: data.reportedProblem.present
          ? data.reportedProblem.value
          : this.reportedProblem,
      receivedAccessories: data.receivedAccessories.present
          ? data.receivedAccessories.value
          : this.receivedAccessories,
      deviceAccessInfo: data.deviceAccessInfo.present
          ? data.deviceAccessInfo.value
          : this.deviceAccessInfo,
      status: data.status.present ? data.status.value : this.status,
      priceAmount: data.priceAmount.present
          ? data.priceAmount.value
          : this.priceAmount,
      customerPriceDecision: data.customerPriceDecision.present
          ? data.customerPriceDecision.value
          : this.customerPriceDecision,
      internalNotes: data.internalNotes.present
          ? data.internalNotes.value
          : this.internalNotes,
      customerMessage: data.customerMessage.present
          ? data.customerMessage.value
          : this.customerMessage,
      parentRepairId: data.parentRepairId.present
          ? data.parentRepairId.value
          : this.parentRepairId,
      trackingToken: data.trackingToken.present
          ? data.trackingToken.value
          : this.trackingToken,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      readyAt: data.readyAt.present ? data.readyAt.value : this.readyAt,
      deliveredAt: data.deliveredAt.present
          ? data.deliveredAt.value
          : this.deliveredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RepairRow(')
          ..write('id: $id, ')
          ..write('repairCode: $repairCode, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('deviceType: $deviceType, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('reportedProblem: $reportedProblem, ')
          ..write('receivedAccessories: $receivedAccessories, ')
          ..write('deviceAccessInfo: $deviceAccessInfo, ')
          ..write('status: $status, ')
          ..write('priceAmount: $priceAmount, ')
          ..write('customerPriceDecision: $customerPriceDecision, ')
          ..write('internalNotes: $internalNotes, ')
          ..write('customerMessage: $customerMessage, ')
          ..write('parentRepairId: $parentRepairId, ')
          ..write('trackingToken: $trackingToken, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('readyAt: $readyAt, ')
          ..write('deliveredAt: $deliveredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    repairCode,
    customerName,
    customerPhone,
    deviceType,
    brand,
    model,
    reportedProblem,
    receivedAccessories,
    deviceAccessInfo,
    status,
    priceAmount,
    customerPriceDecision,
    internalNotes,
    customerMessage,
    parentRepairId,
    trackingToken,
    createdAt,
    updatedAt,
    receivedAt,
    readyAt,
    deliveredAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RepairRow &&
          other.id == this.id &&
          other.repairCode == this.repairCode &&
          other.customerName == this.customerName &&
          other.customerPhone == this.customerPhone &&
          other.deviceType == this.deviceType &&
          other.brand == this.brand &&
          other.model == this.model &&
          other.reportedProblem == this.reportedProblem &&
          other.receivedAccessories == this.receivedAccessories &&
          other.deviceAccessInfo == this.deviceAccessInfo &&
          other.status == this.status &&
          other.priceAmount == this.priceAmount &&
          other.customerPriceDecision == this.customerPriceDecision &&
          other.internalNotes == this.internalNotes &&
          other.customerMessage == this.customerMessage &&
          other.parentRepairId == this.parentRepairId &&
          other.trackingToken == this.trackingToken &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.receivedAt == this.receivedAt &&
          other.readyAt == this.readyAt &&
          other.deliveredAt == this.deliveredAt);
}

class RepairsCompanion extends UpdateCompanion<RepairRow> {
  final Value<int> id;
  final Value<String> repairCode;
  final Value<String?> customerName;
  final Value<String?> customerPhone;
  final Value<String?> deviceType;
  final Value<String?> brand;
  final Value<String?> model;
  final Value<String> reportedProblem;
  final Value<String?> receivedAccessories;
  final Value<String?> deviceAccessInfo;
  final Value<String> status;
  final Value<int?> priceAmount;
  final Value<String> customerPriceDecision;
  final Value<String?> internalNotes;
  final Value<String?> customerMessage;
  final Value<int?> parentRepairId;
  final Value<String?> trackingToken;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime> receivedAt;
  final Value<DateTime?> readyAt;
  final Value<DateTime?> deliveredAt;
  const RepairsCompanion({
    this.id = const Value.absent(),
    this.repairCode = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.deviceType = const Value.absent(),
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.reportedProblem = const Value.absent(),
    this.receivedAccessories = const Value.absent(),
    this.deviceAccessInfo = const Value.absent(),
    this.status = const Value.absent(),
    this.priceAmount = const Value.absent(),
    this.customerPriceDecision = const Value.absent(),
    this.internalNotes = const Value.absent(),
    this.customerMessage = const Value.absent(),
    this.parentRepairId = const Value.absent(),
    this.trackingToken = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.readyAt = const Value.absent(),
    this.deliveredAt = const Value.absent(),
  });
  RepairsCompanion.insert({
    this.id = const Value.absent(),
    required String repairCode,
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.deviceType = const Value.absent(),
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    required String reportedProblem,
    this.receivedAccessories = const Value.absent(),
    this.deviceAccessInfo = const Value.absent(),
    required String status,
    this.priceAmount = const Value.absent(),
    this.customerPriceDecision = const Value.absent(),
    this.internalNotes = const Value.absent(),
    this.customerMessage = const Value.absent(),
    this.parentRepairId = const Value.absent(),
    this.trackingToken = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime receivedAt,
    this.readyAt = const Value.absent(),
    this.deliveredAt = const Value.absent(),
  }) : repairCode = Value(repairCode),
       reportedProblem = Value(reportedProblem),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       receivedAt = Value(receivedAt);
  static Insertable<RepairRow> custom({
    Expression<int>? id,
    Expression<String>? repairCode,
    Expression<String>? customerName,
    Expression<String>? customerPhone,
    Expression<String>? deviceType,
    Expression<String>? brand,
    Expression<String>? model,
    Expression<String>? reportedProblem,
    Expression<String>? receivedAccessories,
    Expression<String>? deviceAccessInfo,
    Expression<String>? status,
    Expression<int>? priceAmount,
    Expression<String>? customerPriceDecision,
    Expression<String>? internalNotes,
    Expression<String>? customerMessage,
    Expression<int>? parentRepairId,
    Expression<String>? trackingToken,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? receivedAt,
    Expression<DateTime>? readyAt,
    Expression<DateTime>? deliveredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (repairCode != null) 'repair_code': repairCode,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (deviceType != null) 'device_type': deviceType,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (reportedProblem != null) 'reported_problem': reportedProblem,
      if (receivedAccessories != null)
        'received_accessories': receivedAccessories,
      if (deviceAccessInfo != null) 'device_access_info': deviceAccessInfo,
      if (status != null) 'status': status,
      if (priceAmount != null) 'price_amount': priceAmount,
      if (customerPriceDecision != null)
        'customer_price_decision': customerPriceDecision,
      if (internalNotes != null) 'internal_notes': internalNotes,
      if (customerMessage != null) 'customer_message': customerMessage,
      if (parentRepairId != null) 'parent_repair_id': parentRepairId,
      if (trackingToken != null) 'tracking_token': trackingToken,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (receivedAt != null) 'received_at': receivedAt,
      if (readyAt != null) 'ready_at': readyAt,
      if (deliveredAt != null) 'delivered_at': deliveredAt,
    });
  }

  RepairsCompanion copyWith({
    Value<int>? id,
    Value<String>? repairCode,
    Value<String?>? customerName,
    Value<String?>? customerPhone,
    Value<String?>? deviceType,
    Value<String?>? brand,
    Value<String?>? model,
    Value<String>? reportedProblem,
    Value<String?>? receivedAccessories,
    Value<String?>? deviceAccessInfo,
    Value<String>? status,
    Value<int?>? priceAmount,
    Value<String>? customerPriceDecision,
    Value<String?>? internalNotes,
    Value<String?>? customerMessage,
    Value<int?>? parentRepairId,
    Value<String?>? trackingToken,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime>? receivedAt,
    Value<DateTime?>? readyAt,
    Value<DateTime?>? deliveredAt,
  }) {
    return RepairsCompanion(
      id: id ?? this.id,
      repairCode: repairCode ?? this.repairCode,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deviceType: deviceType ?? this.deviceType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      reportedProblem: reportedProblem ?? this.reportedProblem,
      receivedAccessories: receivedAccessories ?? this.receivedAccessories,
      deviceAccessInfo: deviceAccessInfo ?? this.deviceAccessInfo,
      status: status ?? this.status,
      priceAmount: priceAmount ?? this.priceAmount,
      customerPriceDecision:
          customerPriceDecision ?? this.customerPriceDecision,
      internalNotes: internalNotes ?? this.internalNotes,
      customerMessage: customerMessage ?? this.customerMessage,
      parentRepairId: parentRepairId ?? this.parentRepairId,
      trackingToken: trackingToken ?? this.trackingToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      readyAt: readyAt ?? this.readyAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (repairCode.present) {
      map['repair_code'] = Variable<String>(repairCode.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerPhone.present) {
      map['customer_phone'] = Variable<String>(customerPhone.value);
    }
    if (deviceType.present) {
      map['device_type'] = Variable<String>(deviceType.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (reportedProblem.present) {
      map['reported_problem'] = Variable<String>(reportedProblem.value);
    }
    if (receivedAccessories.present) {
      map['received_accessories'] = Variable<String>(receivedAccessories.value);
    }
    if (deviceAccessInfo.present) {
      map['device_access_info'] = Variable<String>(deviceAccessInfo.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priceAmount.present) {
      map['price_amount'] = Variable<int>(priceAmount.value);
    }
    if (customerPriceDecision.present) {
      map['customer_price_decision'] = Variable<String>(
        customerPriceDecision.value,
      );
    }
    if (internalNotes.present) {
      map['internal_notes'] = Variable<String>(internalNotes.value);
    }
    if (customerMessage.present) {
      map['customer_message'] = Variable<String>(customerMessage.value);
    }
    if (parentRepairId.present) {
      map['parent_repair_id'] = Variable<int>(parentRepairId.value);
    }
    if (trackingToken.present) {
      map['tracking_token'] = Variable<String>(trackingToken.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (readyAt.present) {
      map['ready_at'] = Variable<DateTime>(readyAt.value);
    }
    if (deliveredAt.present) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RepairsCompanion(')
          ..write('id: $id, ')
          ..write('repairCode: $repairCode, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('deviceType: $deviceType, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('reportedProblem: $reportedProblem, ')
          ..write('receivedAccessories: $receivedAccessories, ')
          ..write('deviceAccessInfo: $deviceAccessInfo, ')
          ..write('status: $status, ')
          ..write('priceAmount: $priceAmount, ')
          ..write('customerPriceDecision: $customerPriceDecision, ')
          ..write('internalNotes: $internalNotes, ')
          ..write('customerMessage: $customerMessage, ')
          ..write('parentRepairId: $parentRepairId, ')
          ..write('trackingToken: $trackingToken, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('readyAt: $readyAt, ')
          ..write('deliveredAt: $deliveredAt')
          ..write(')'))
        .toString();
  }
}

class $RepairCodeSequenceTableTable extends RepairCodeSequenceTable
    with TableInfo<$RepairCodeSequenceTableTable, RepairCodeSequenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RepairCodeSequenceTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _lastUsedSequenceMeta = const VerificationMeta(
    'lastUsedSequence',
  );
  @override
  late final GeneratedColumn<int> lastUsedSequence = GeneratedColumn<int>(
    'last_used_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK(last_used_sequence >= 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [id, lastUsedSequence];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'repair_code_sequence';
  @override
  VerificationContext validateIntegrity(
    Insertable<RepairCodeSequenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('last_used_sequence')) {
      context.handle(
        _lastUsedSequenceMeta,
        lastUsedSequence.isAcceptableOrUnknown(
          data['last_used_sequence']!,
          _lastUsedSequenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedSequenceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RepairCodeSequenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RepairCodeSequenceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lastUsedSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_used_sequence'],
      )!,
    );
  }

  @override
  $RepairCodeSequenceTableTable createAlias(String alias) {
    return $RepairCodeSequenceTableTable(attachedDatabase, alias);
  }
}

class RepairCodeSequenceRow extends DataClass
    implements Insertable<RepairCodeSequenceRow> {
  final int id;
  final int lastUsedSequence;
  const RepairCodeSequenceRow({
    required this.id,
    required this.lastUsedSequence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['last_used_sequence'] = Variable<int>(lastUsedSequence);
    return map;
  }

  RepairCodeSequenceTableCompanion toCompanion(bool nullToAbsent) {
    return RepairCodeSequenceTableCompanion(
      id: Value(id),
      lastUsedSequence: Value(lastUsedSequence),
    );
  }

  factory RepairCodeSequenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RepairCodeSequenceRow(
      id: serializer.fromJson<int>(json['id']),
      lastUsedSequence: serializer.fromJson<int>(json['lastUsedSequence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lastUsedSequence': serializer.toJson<int>(lastUsedSequence),
    };
  }

  RepairCodeSequenceRow copyWith({int? id, int? lastUsedSequence}) =>
      RepairCodeSequenceRow(
        id: id ?? this.id,
        lastUsedSequence: lastUsedSequence ?? this.lastUsedSequence,
      );
  RepairCodeSequenceRow copyWithCompanion(
    RepairCodeSequenceTableCompanion data,
  ) {
    return RepairCodeSequenceRow(
      id: data.id.present ? data.id.value : this.id,
      lastUsedSequence: data.lastUsedSequence.present
          ? data.lastUsedSequence.value
          : this.lastUsedSequence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RepairCodeSequenceRow(')
          ..write('id: $id, ')
          ..write('lastUsedSequence: $lastUsedSequence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lastUsedSequence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RepairCodeSequenceRow &&
          other.id == this.id &&
          other.lastUsedSequence == this.lastUsedSequence);
}

class RepairCodeSequenceTableCompanion
    extends UpdateCompanion<RepairCodeSequenceRow> {
  final Value<int> id;
  final Value<int> lastUsedSequence;
  const RepairCodeSequenceTableCompanion({
    this.id = const Value.absent(),
    this.lastUsedSequence = const Value.absent(),
  });
  RepairCodeSequenceTableCompanion.insert({
    this.id = const Value.absent(),
    required int lastUsedSequence,
  }) : lastUsedSequence = Value(lastUsedSequence);
  static Insertable<RepairCodeSequenceRow> custom({
    Expression<int>? id,
    Expression<int>? lastUsedSequence,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastUsedSequence != null) 'last_used_sequence': lastUsedSequence,
    });
  }

  RepairCodeSequenceTableCompanion copyWith({
    Value<int>? id,
    Value<int>? lastUsedSequence,
  }) {
    return RepairCodeSequenceTableCompanion(
      id: id ?? this.id,
      lastUsedSequence: lastUsedSequence ?? this.lastUsedSequence,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lastUsedSequence.present) {
      map['last_used_sequence'] = Variable<int>(lastUsedSequence.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RepairCodeSequenceTableCompanion(')
          ..write('id: $id, ')
          ..write('lastUsedSequence: $lastUsedSequence')
          ..write(')'))
        .toString();
  }
}

class $ShopSettingsTableTable extends ShopSettingsTable
    with TableInfo<$ShopSettingsTableTable, ShopSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShopSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _shopNameMeta = const VerificationMeta(
    'shopName',
  );
  @override
  late final GeneratedColumn<String> shopName = GeneratedColumn<String>(
    'shop_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK(length(trim(shop_name)) > 0)',
  );
  static const VerificationMeta _shopSubtitleMeta = const VerificationMeta(
    'shopSubtitle',
  );
  @override
  late final GeneratedColumn<String> shopSubtitle = GeneratedColumn<String>(
    'shop_subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoPathMeta = const VerificationMeta(
    'logoPath',
  );
  @override
  late final GeneratedColumn<String> logoPath = GeneratedColumn<String>(
    'logo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repairCodePrefixMeta = const VerificationMeta(
    'repairCodePrefix',
  );
  @override
  late final GeneratedColumn<String> repairCodePrefix = GeneratedColumn<String>(
    'repair_code_prefix',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK(length(repair_code_prefix) BETWEEN 2 AND 10)',
  );
  static const VerificationMeta _repairCodeNumberWidthMeta =
      const VerificationMeta('repairCodeNumberWidth');
  @override
  late final GeneratedColumn<int> repairCodeNumberWidth = GeneratedColumn<int>(
    'repair_code_number_width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK(repair_code_number_width BETWEEN 3 AND 8)',
  );
  static const VerificationMeta _ticketFooterMeta = const VerificationMeta(
    'ticketFooter',
  );
  @override
  late final GeneratedColumn<String> ticketFooter = GeneratedColumn<String>(
    'ticket_footer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warrantyTermsMeta = const VerificationMeta(
    'warrantyTerms',
  );
  @override
  late final GeneratedColumn<String> warrantyTerms = GeneratedColumn<String>(
    'warranty_terms',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultCustomerTicketPrinterIdMeta =
      const VerificationMeta('defaultCustomerTicketPrinterId');
  @override
  late final GeneratedColumn<String> defaultCustomerTicketPrinterId =
      GeneratedColumn<String>(
        'default_customer_ticket_printer_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _defaultDeviceLabelPrinterIdMeta =
      const VerificationMeta('defaultDeviceLabelPrinterId');
  @override
  late final GeneratedColumn<String> defaultDeviceLabelPrinterId =
      GeneratedColumn<String>(
        'default_device_label_printer_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _publicShopIdMeta = const VerificationMeta(
    'publicShopId',
  );
  @override
  late final GeneratedColumn<String> publicShopId = GeneratedColumn<String>(
    'public_shop_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopName,
    shopSubtitle,
    phoneNumber,
    address,
    logoPath,
    repairCodePrefix,
    repairCodeNumberWidth,
    ticketFooter,
    warrantyTerms,
    defaultCustomerTicketPrinterId,
    defaultDeviceLabelPrinterId,
    publicShopId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shop_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShopSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shop_name')) {
      context.handle(
        _shopNameMeta,
        shopName.isAcceptableOrUnknown(data['shop_name']!, _shopNameMeta),
      );
    } else if (isInserting) {
      context.missing(_shopNameMeta);
    }
    if (data.containsKey('shop_subtitle')) {
      context.handle(
        _shopSubtitleMeta,
        shopSubtitle.isAcceptableOrUnknown(
          data['shop_subtitle']!,
          _shopSubtitleMeta,
        ),
      );
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('logo_path')) {
      context.handle(
        _logoPathMeta,
        logoPath.isAcceptableOrUnknown(data['logo_path']!, _logoPathMeta),
      );
    }
    if (data.containsKey('repair_code_prefix')) {
      context.handle(
        _repairCodePrefixMeta,
        repairCodePrefix.isAcceptableOrUnknown(
          data['repair_code_prefix']!,
          _repairCodePrefixMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_repairCodePrefixMeta);
    }
    if (data.containsKey('repair_code_number_width')) {
      context.handle(
        _repairCodeNumberWidthMeta,
        repairCodeNumberWidth.isAcceptableOrUnknown(
          data['repair_code_number_width']!,
          _repairCodeNumberWidthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_repairCodeNumberWidthMeta);
    }
    if (data.containsKey('ticket_footer')) {
      context.handle(
        _ticketFooterMeta,
        ticketFooter.isAcceptableOrUnknown(
          data['ticket_footer']!,
          _ticketFooterMeta,
        ),
      );
    }
    if (data.containsKey('warranty_terms')) {
      context.handle(
        _warrantyTermsMeta,
        warrantyTerms.isAcceptableOrUnknown(
          data['warranty_terms']!,
          _warrantyTermsMeta,
        ),
      );
    }
    if (data.containsKey('default_customer_ticket_printer_id')) {
      context.handle(
        _defaultCustomerTicketPrinterIdMeta,
        defaultCustomerTicketPrinterId.isAcceptableOrUnknown(
          data['default_customer_ticket_printer_id']!,
          _defaultCustomerTicketPrinterIdMeta,
        ),
      );
    }
    if (data.containsKey('default_device_label_printer_id')) {
      context.handle(
        _defaultDeviceLabelPrinterIdMeta,
        defaultDeviceLabelPrinterId.isAcceptableOrUnknown(
          data['default_device_label_printer_id']!,
          _defaultDeviceLabelPrinterIdMeta,
        ),
      );
    }
    if (data.containsKey('public_shop_id')) {
      context.handle(
        _publicShopIdMeta,
        publicShopId.isAcceptableOrUnknown(
          data['public_shop_id']!,
          _publicShopIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShopSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShopSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      shopName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_name'],
      )!,
      shopSubtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_subtitle'],
      ),
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      logoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_path'],
      ),
      repairCodePrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repair_code_prefix'],
      )!,
      repairCodeNumberWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repair_code_number_width'],
      )!,
      ticketFooter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ticket_footer'],
      ),
      warrantyTerms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warranty_terms'],
      ),
      defaultCustomerTicketPrinterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_customer_ticket_printer_id'],
      ),
      defaultDeviceLabelPrinterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_device_label_printer_id'],
      ),
      publicShopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_shop_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ShopSettingsTableTable createAlias(String alias) {
    return $ShopSettingsTableTable(attachedDatabase, alias);
  }
}

class ShopSettingsRow extends DataClass implements Insertable<ShopSettingsRow> {
  final int id;
  final String shopName;
  final String? shopSubtitle;
  final String? phoneNumber;
  final String? address;
  final String? logoPath;
  final String repairCodePrefix;
  final int repairCodeNumberWidth;
  final String? ticketFooter;
  final String? warrantyTerms;
  final String? defaultCustomerTicketPrinterId;
  final String? defaultDeviceLabelPrinterId;
  final String? publicShopId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ShopSettingsRow({
    required this.id,
    required this.shopName,
    this.shopSubtitle,
    this.phoneNumber,
    this.address,
    this.logoPath,
    required this.repairCodePrefix,
    required this.repairCodeNumberWidth,
    this.ticketFooter,
    this.warrantyTerms,
    this.defaultCustomerTicketPrinterId,
    this.defaultDeviceLabelPrinterId,
    this.publicShopId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['shop_name'] = Variable<String>(shopName);
    if (!nullToAbsent || shopSubtitle != null) {
      map['shop_subtitle'] = Variable<String>(shopSubtitle);
    }
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || logoPath != null) {
      map['logo_path'] = Variable<String>(logoPath);
    }
    map['repair_code_prefix'] = Variable<String>(repairCodePrefix);
    map['repair_code_number_width'] = Variable<int>(repairCodeNumberWidth);
    if (!nullToAbsent || ticketFooter != null) {
      map['ticket_footer'] = Variable<String>(ticketFooter);
    }
    if (!nullToAbsent || warrantyTerms != null) {
      map['warranty_terms'] = Variable<String>(warrantyTerms);
    }
    if (!nullToAbsent || defaultCustomerTicketPrinterId != null) {
      map['default_customer_ticket_printer_id'] = Variable<String>(
        defaultCustomerTicketPrinterId,
      );
    }
    if (!nullToAbsent || defaultDeviceLabelPrinterId != null) {
      map['default_device_label_printer_id'] = Variable<String>(
        defaultDeviceLabelPrinterId,
      );
    }
    if (!nullToAbsent || publicShopId != null) {
      map['public_shop_id'] = Variable<String>(publicShopId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ShopSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return ShopSettingsTableCompanion(
      id: Value(id),
      shopName: Value(shopName),
      shopSubtitle: shopSubtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(shopSubtitle),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      logoPath: logoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(logoPath),
      repairCodePrefix: Value(repairCodePrefix),
      repairCodeNumberWidth: Value(repairCodeNumberWidth),
      ticketFooter: ticketFooter == null && nullToAbsent
          ? const Value.absent()
          : Value(ticketFooter),
      warrantyTerms: warrantyTerms == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyTerms),
      defaultCustomerTicketPrinterId:
          defaultCustomerTicketPrinterId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultCustomerTicketPrinterId),
      defaultDeviceLabelPrinterId:
          defaultDeviceLabelPrinterId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultDeviceLabelPrinterId),
      publicShopId: publicShopId == null && nullToAbsent
          ? const Value.absent()
          : Value(publicShopId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ShopSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShopSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      shopName: serializer.fromJson<String>(json['shopName']),
      shopSubtitle: serializer.fromJson<String?>(json['shopSubtitle']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      address: serializer.fromJson<String?>(json['address']),
      logoPath: serializer.fromJson<String?>(json['logoPath']),
      repairCodePrefix: serializer.fromJson<String>(json['repairCodePrefix']),
      repairCodeNumberWidth: serializer.fromJson<int>(
        json['repairCodeNumberWidth'],
      ),
      ticketFooter: serializer.fromJson<String?>(json['ticketFooter']),
      warrantyTerms: serializer.fromJson<String?>(json['warrantyTerms']),
      defaultCustomerTicketPrinterId: serializer.fromJson<String?>(
        json['defaultCustomerTicketPrinterId'],
      ),
      defaultDeviceLabelPrinterId: serializer.fromJson<String?>(
        json['defaultDeviceLabelPrinterId'],
      ),
      publicShopId: serializer.fromJson<String?>(json['publicShopId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shopName': serializer.toJson<String>(shopName),
      'shopSubtitle': serializer.toJson<String?>(shopSubtitle),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'address': serializer.toJson<String?>(address),
      'logoPath': serializer.toJson<String?>(logoPath),
      'repairCodePrefix': serializer.toJson<String>(repairCodePrefix),
      'repairCodeNumberWidth': serializer.toJson<int>(repairCodeNumberWidth),
      'ticketFooter': serializer.toJson<String?>(ticketFooter),
      'warrantyTerms': serializer.toJson<String?>(warrantyTerms),
      'defaultCustomerTicketPrinterId': serializer.toJson<String?>(
        defaultCustomerTicketPrinterId,
      ),
      'defaultDeviceLabelPrinterId': serializer.toJson<String?>(
        defaultDeviceLabelPrinterId,
      ),
      'publicShopId': serializer.toJson<String?>(publicShopId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ShopSettingsRow copyWith({
    int? id,
    String? shopName,
    Value<String?> shopSubtitle = const Value.absent(),
    Value<String?> phoneNumber = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<String?> logoPath = const Value.absent(),
    String? repairCodePrefix,
    int? repairCodeNumberWidth,
    Value<String?> ticketFooter = const Value.absent(),
    Value<String?> warrantyTerms = const Value.absent(),
    Value<String?> defaultCustomerTicketPrinterId = const Value.absent(),
    Value<String?> defaultDeviceLabelPrinterId = const Value.absent(),
    Value<String?> publicShopId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ShopSettingsRow(
    id: id ?? this.id,
    shopName: shopName ?? this.shopName,
    shopSubtitle: shopSubtitle.present ? shopSubtitle.value : this.shopSubtitle,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    address: address.present ? address.value : this.address,
    logoPath: logoPath.present ? logoPath.value : this.logoPath,
    repairCodePrefix: repairCodePrefix ?? this.repairCodePrefix,
    repairCodeNumberWidth: repairCodeNumberWidth ?? this.repairCodeNumberWidth,
    ticketFooter: ticketFooter.present ? ticketFooter.value : this.ticketFooter,
    warrantyTerms: warrantyTerms.present
        ? warrantyTerms.value
        : this.warrantyTerms,
    defaultCustomerTicketPrinterId: defaultCustomerTicketPrinterId.present
        ? defaultCustomerTicketPrinterId.value
        : this.defaultCustomerTicketPrinterId,
    defaultDeviceLabelPrinterId: defaultDeviceLabelPrinterId.present
        ? defaultDeviceLabelPrinterId.value
        : this.defaultDeviceLabelPrinterId,
    publicShopId: publicShopId.present ? publicShopId.value : this.publicShopId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ShopSettingsRow copyWithCompanion(ShopSettingsTableCompanion data) {
    return ShopSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      shopName: data.shopName.present ? data.shopName.value : this.shopName,
      shopSubtitle: data.shopSubtitle.present
          ? data.shopSubtitle.value
          : this.shopSubtitle,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      address: data.address.present ? data.address.value : this.address,
      logoPath: data.logoPath.present ? data.logoPath.value : this.logoPath,
      repairCodePrefix: data.repairCodePrefix.present
          ? data.repairCodePrefix.value
          : this.repairCodePrefix,
      repairCodeNumberWidth: data.repairCodeNumberWidth.present
          ? data.repairCodeNumberWidth.value
          : this.repairCodeNumberWidth,
      ticketFooter: data.ticketFooter.present
          ? data.ticketFooter.value
          : this.ticketFooter,
      warrantyTerms: data.warrantyTerms.present
          ? data.warrantyTerms.value
          : this.warrantyTerms,
      defaultCustomerTicketPrinterId:
          data.defaultCustomerTicketPrinterId.present
          ? data.defaultCustomerTicketPrinterId.value
          : this.defaultCustomerTicketPrinterId,
      defaultDeviceLabelPrinterId: data.defaultDeviceLabelPrinterId.present
          ? data.defaultDeviceLabelPrinterId.value
          : this.defaultDeviceLabelPrinterId,
      publicShopId: data.publicShopId.present
          ? data.publicShopId.value
          : this.publicShopId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShopSettingsRow(')
          ..write('id: $id, ')
          ..write('shopName: $shopName, ')
          ..write('shopSubtitle: $shopSubtitle, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('address: $address, ')
          ..write('logoPath: $logoPath, ')
          ..write('repairCodePrefix: $repairCodePrefix, ')
          ..write('repairCodeNumberWidth: $repairCodeNumberWidth, ')
          ..write('ticketFooter: $ticketFooter, ')
          ..write('warrantyTerms: $warrantyTerms, ')
          ..write(
            'defaultCustomerTicketPrinterId: $defaultCustomerTicketPrinterId, ',
          )
          ..write('defaultDeviceLabelPrinterId: $defaultDeviceLabelPrinterId, ')
          ..write('publicShopId: $publicShopId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shopName,
    shopSubtitle,
    phoneNumber,
    address,
    logoPath,
    repairCodePrefix,
    repairCodeNumberWidth,
    ticketFooter,
    warrantyTerms,
    defaultCustomerTicketPrinterId,
    defaultDeviceLabelPrinterId,
    publicShopId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShopSettingsRow &&
          other.id == this.id &&
          other.shopName == this.shopName &&
          other.shopSubtitle == this.shopSubtitle &&
          other.phoneNumber == this.phoneNumber &&
          other.address == this.address &&
          other.logoPath == this.logoPath &&
          other.repairCodePrefix == this.repairCodePrefix &&
          other.repairCodeNumberWidth == this.repairCodeNumberWidth &&
          other.ticketFooter == this.ticketFooter &&
          other.warrantyTerms == this.warrantyTerms &&
          other.defaultCustomerTicketPrinterId ==
              this.defaultCustomerTicketPrinterId &&
          other.defaultDeviceLabelPrinterId ==
              this.defaultDeviceLabelPrinterId &&
          other.publicShopId == this.publicShopId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ShopSettingsTableCompanion extends UpdateCompanion<ShopSettingsRow> {
  final Value<int> id;
  final Value<String> shopName;
  final Value<String?> shopSubtitle;
  final Value<String?> phoneNumber;
  final Value<String?> address;
  final Value<String?> logoPath;
  final Value<String> repairCodePrefix;
  final Value<int> repairCodeNumberWidth;
  final Value<String?> ticketFooter;
  final Value<String?> warrantyTerms;
  final Value<String?> defaultCustomerTicketPrinterId;
  final Value<String?> defaultDeviceLabelPrinterId;
  final Value<String?> publicShopId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ShopSettingsTableCompanion({
    this.id = const Value.absent(),
    this.shopName = const Value.absent(),
    this.shopSubtitle = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.address = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.repairCodePrefix = const Value.absent(),
    this.repairCodeNumberWidth = const Value.absent(),
    this.ticketFooter = const Value.absent(),
    this.warrantyTerms = const Value.absent(),
    this.defaultCustomerTicketPrinterId = const Value.absent(),
    this.defaultDeviceLabelPrinterId = const Value.absent(),
    this.publicShopId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ShopSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required String shopName,
    this.shopSubtitle = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.address = const Value.absent(),
    this.logoPath = const Value.absent(),
    required String repairCodePrefix,
    required int repairCodeNumberWidth,
    this.ticketFooter = const Value.absent(),
    this.warrantyTerms = const Value.absent(),
    this.defaultCustomerTicketPrinterId = const Value.absent(),
    this.defaultDeviceLabelPrinterId = const Value.absent(),
    this.publicShopId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : shopName = Value(shopName),
       repairCodePrefix = Value(repairCodePrefix),
       repairCodeNumberWidth = Value(repairCodeNumberWidth),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ShopSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? shopName,
    Expression<String>? shopSubtitle,
    Expression<String>? phoneNumber,
    Expression<String>? address,
    Expression<String>? logoPath,
    Expression<String>? repairCodePrefix,
    Expression<int>? repairCodeNumberWidth,
    Expression<String>? ticketFooter,
    Expression<String>? warrantyTerms,
    Expression<String>? defaultCustomerTicketPrinterId,
    Expression<String>? defaultDeviceLabelPrinterId,
    Expression<String>? publicShopId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopName != null) 'shop_name': shopName,
      if (shopSubtitle != null) 'shop_subtitle': shopSubtitle,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (address != null) 'address': address,
      if (logoPath != null) 'logo_path': logoPath,
      if (repairCodePrefix != null) 'repair_code_prefix': repairCodePrefix,
      if (repairCodeNumberWidth != null)
        'repair_code_number_width': repairCodeNumberWidth,
      if (ticketFooter != null) 'ticket_footer': ticketFooter,
      if (warrantyTerms != null) 'warranty_terms': warrantyTerms,
      if (defaultCustomerTicketPrinterId != null)
        'default_customer_ticket_printer_id': defaultCustomerTicketPrinterId,
      if (defaultDeviceLabelPrinterId != null)
        'default_device_label_printer_id': defaultDeviceLabelPrinterId,
      if (publicShopId != null) 'public_shop_id': publicShopId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ShopSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? shopName,
    Value<String?>? shopSubtitle,
    Value<String?>? phoneNumber,
    Value<String?>? address,
    Value<String?>? logoPath,
    Value<String>? repairCodePrefix,
    Value<int>? repairCodeNumberWidth,
    Value<String?>? ticketFooter,
    Value<String?>? warrantyTerms,
    Value<String?>? defaultCustomerTicketPrinterId,
    Value<String?>? defaultDeviceLabelPrinterId,
    Value<String?>? publicShopId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ShopSettingsTableCompanion(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      shopSubtitle: shopSubtitle ?? this.shopSubtitle,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      logoPath: logoPath ?? this.logoPath,
      repairCodePrefix: repairCodePrefix ?? this.repairCodePrefix,
      repairCodeNumberWidth:
          repairCodeNumberWidth ?? this.repairCodeNumberWidth,
      ticketFooter: ticketFooter ?? this.ticketFooter,
      warrantyTerms: warrantyTerms ?? this.warrantyTerms,
      defaultCustomerTicketPrinterId:
          defaultCustomerTicketPrinterId ?? this.defaultCustomerTicketPrinterId,
      defaultDeviceLabelPrinterId:
          defaultDeviceLabelPrinterId ?? this.defaultDeviceLabelPrinterId,
      publicShopId: publicShopId ?? this.publicShopId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shopName.present) {
      map['shop_name'] = Variable<String>(shopName.value);
    }
    if (shopSubtitle.present) {
      map['shop_subtitle'] = Variable<String>(shopSubtitle.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (logoPath.present) {
      map['logo_path'] = Variable<String>(logoPath.value);
    }
    if (repairCodePrefix.present) {
      map['repair_code_prefix'] = Variable<String>(repairCodePrefix.value);
    }
    if (repairCodeNumberWidth.present) {
      map['repair_code_number_width'] = Variable<int>(
        repairCodeNumberWidth.value,
      );
    }
    if (ticketFooter.present) {
      map['ticket_footer'] = Variable<String>(ticketFooter.value);
    }
    if (warrantyTerms.present) {
      map['warranty_terms'] = Variable<String>(warrantyTerms.value);
    }
    if (defaultCustomerTicketPrinterId.present) {
      map['default_customer_ticket_printer_id'] = Variable<String>(
        defaultCustomerTicketPrinterId.value,
      );
    }
    if (defaultDeviceLabelPrinterId.present) {
      map['default_device_label_printer_id'] = Variable<String>(
        defaultDeviceLabelPrinterId.value,
      );
    }
    if (publicShopId.present) {
      map['public_shop_id'] = Variable<String>(publicShopId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShopSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('shopName: $shopName, ')
          ..write('shopSubtitle: $shopSubtitle, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('address: $address, ')
          ..write('logoPath: $logoPath, ')
          ..write('repairCodePrefix: $repairCodePrefix, ')
          ..write('repairCodeNumberWidth: $repairCodeNumberWidth, ')
          ..write('ticketFooter: $ticketFooter, ')
          ..write('warrantyTerms: $warrantyTerms, ')
          ..write(
            'defaultCustomerTicketPrinterId: $defaultCustomerTicketPrinterId, ',
          )
          ..write('defaultDeviceLabelPrinterId: $defaultDeviceLabelPrinterId, ')
          ..write('publicShopId: $publicShopId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CommonProblemsTable extends CommonProblems
    with TableInfo<$CommonProblemsTable, CommonProblemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommonProblemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK(length(trim(title)) > 0)',
  );
  static const VerificationMeta _normalizedTitleMeta = const VerificationMeta(
    'normalizedTitle',
  );
  @override
  late final GeneratedColumn<String> normalizedTitle = GeneratedColumn<String>(
    'normalized_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL UNIQUE CHECK(length(trim(normalized_title)) > 0)',
  );
  static const VerificationMeta _usageCountMeta = const VerificationMeta(
    'usageCount',
  );
  @override
  late final GeneratedColumn<int> usageCount = GeneratedColumn<int>(
    'usage_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK(usage_count >= 0)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    normalizedTitle,
    usageCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'common_problems';
  @override
  VerificationContext validateIntegrity(
    Insertable<CommonProblemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('normalized_title')) {
      context.handle(
        _normalizedTitleMeta,
        normalizedTitle.isAcceptableOrUnknown(
          data['normalized_title']!,
          _normalizedTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedTitleMeta);
    }
    if (data.containsKey('usage_count')) {
      context.handle(
        _usageCountMeta,
        usageCount.isAcceptableOrUnknown(data['usage_count']!, _usageCountMeta),
      );
    } else if (isInserting) {
      context.missing(_usageCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CommonProblemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommonProblemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      normalizedTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_title'],
      )!,
      usageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}usage_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CommonProblemsTable createAlias(String alias) {
    return $CommonProblemsTable(attachedDatabase, alias);
  }
}

class CommonProblemRow extends DataClass
    implements Insertable<CommonProblemRow> {
  final int id;
  final String title;
  final String normalizedTitle;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CommonProblemRow({
    required this.id,
    required this.title,
    required this.normalizedTitle,
    required this.usageCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['normalized_title'] = Variable<String>(normalizedTitle);
    map['usage_count'] = Variable<int>(usageCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CommonProblemsCompanion toCompanion(bool nullToAbsent) {
    return CommonProblemsCompanion(
      id: Value(id),
      title: Value(title),
      normalizedTitle: Value(normalizedTitle),
      usageCount: Value(usageCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CommonProblemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommonProblemRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      normalizedTitle: serializer.fromJson<String>(json['normalizedTitle']),
      usageCount: serializer.fromJson<int>(json['usageCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'normalizedTitle': serializer.toJson<String>(normalizedTitle),
      'usageCount': serializer.toJson<int>(usageCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CommonProblemRow copyWith({
    int? id,
    String? title,
    String? normalizedTitle,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CommonProblemRow(
    id: id ?? this.id,
    title: title ?? this.title,
    normalizedTitle: normalizedTitle ?? this.normalizedTitle,
    usageCount: usageCount ?? this.usageCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CommonProblemRow copyWithCompanion(CommonProblemsCompanion data) {
    return CommonProblemRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      normalizedTitle: data.normalizedTitle.present
          ? data.normalizedTitle.value
          : this.normalizedTitle,
      usageCount: data.usageCount.present
          ? data.usageCount.value
          : this.usageCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommonProblemRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('normalizedTitle: $normalizedTitle, ')
          ..write('usageCount: $usageCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, normalizedTitle, usageCount, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommonProblemRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.normalizedTitle == this.normalizedTitle &&
          other.usageCount == this.usageCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CommonProblemsCompanion extends UpdateCompanion<CommonProblemRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> normalizedTitle;
  final Value<int> usageCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CommonProblemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.normalizedTitle = const Value.absent(),
    this.usageCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CommonProblemsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String normalizedTitle,
    required int usageCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : title = Value(title),
       normalizedTitle = Value(normalizedTitle),
       usageCount = Value(usageCount),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CommonProblemRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? normalizedTitle,
    Expression<int>? usageCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (normalizedTitle != null) 'normalized_title': normalizedTitle,
      if (usageCount != null) 'usage_count': usageCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CommonProblemsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? normalizedTitle,
    Value<int>? usageCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CommonProblemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      normalizedTitle: normalizedTitle ?? this.normalizedTitle,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (normalizedTitle.present) {
      map['normalized_title'] = Variable<String>(normalizedTitle.value);
    }
    if (usageCount.present) {
      map['usage_count'] = Variable<int>(usageCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommonProblemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('normalizedTitle: $normalizedTitle, ')
          ..write('usageCount: $usageCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TrackingSyncOutboxTableTable extends TrackingSyncOutboxTable
    with TableInfo<$TrackingSyncOutboxTableTable, TrackingSyncOutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackingSyncOutboxTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _repairIdMeta = const VerificationMeta(
    'repairId',
  );
  @override
  late final GeneratedColumn<int> repairId = GeneratedColumn<int>(
    'repair_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES repairs (id)',
    ),
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK(operation IN (\'upsert_snapshot\'))',
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK(attempt_count >= 0)',
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    repairId,
    operation,
    attemptCount,
    lastError,
    nextAttemptAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracking_sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackingSyncOutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('repair_id')) {
      context.handle(
        _repairIdMeta,
        repairId.isAcceptableOrUnknown(data['repair_id']!, _repairIdMeta),
      );
    } else if (isInserting) {
      context.missing(_repairIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attemptCountMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackingSyncOutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackingSyncOutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      repairId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repair_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TrackingSyncOutboxTableTable createAlias(String alias) {
    return $TrackingSyncOutboxTableTable(attachedDatabase, alias);
  }
}

class TrackingSyncOutboxRow extends DataClass
    implements Insertable<TrackingSyncOutboxRow> {
  final int id;
  final int repairId;
  final String operation;
  final int attemptCount;
  final String? lastError;
  final DateTime nextAttemptAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TrackingSyncOutboxRow({
    required this.id,
    required this.repairId,
    required this.operation,
    required this.attemptCount,
    this.lastError,
    required this.nextAttemptAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['repair_id'] = Variable<int>(repairId);
    map['operation'] = Variable<String>(operation);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TrackingSyncOutboxTableCompanion toCompanion(bool nullToAbsent) {
    return TrackingSyncOutboxTableCompanion(
      id: Value(id),
      repairId: Value(repairId),
      operation: Value(operation),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      nextAttemptAt: Value(nextAttemptAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TrackingSyncOutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackingSyncOutboxRow(
      id: serializer.fromJson<int>(json['id']),
      repairId: serializer.fromJson<int>(json['repairId']),
      operation: serializer.fromJson<String>(json['operation']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'repairId': serializer.toJson<int>(repairId),
      'operation': serializer.toJson<String>(operation),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TrackingSyncOutboxRow copyWith({
    int? id,
    int? repairId,
    String? operation,
    int? attemptCount,
    Value<String?> lastError = const Value.absent(),
    DateTime? nextAttemptAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TrackingSyncOutboxRow(
    id: id ?? this.id,
    repairId: repairId ?? this.repairId,
    operation: operation ?? this.operation,
    attemptCount: attemptCount ?? this.attemptCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TrackingSyncOutboxRow copyWithCompanion(
    TrackingSyncOutboxTableCompanion data,
  ) {
    return TrackingSyncOutboxRow(
      id: data.id.present ? data.id.value : this.id,
      repairId: data.repairId.present ? data.repairId.value : this.repairId,
      operation: data.operation.present ? data.operation.value : this.operation,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackingSyncOutboxRow(')
          ..write('id: $id, ')
          ..write('repairId: $repairId, ')
          ..write('operation: $operation, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    repairId,
    operation,
    attemptCount,
    lastError,
    nextAttemptAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackingSyncOutboxRow &&
          other.id == this.id &&
          other.repairId == this.repairId &&
          other.operation == this.operation &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TrackingSyncOutboxTableCompanion
    extends UpdateCompanion<TrackingSyncOutboxRow> {
  final Value<int> id;
  final Value<int> repairId;
  final Value<String> operation;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  final Value<DateTime> nextAttemptAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TrackingSyncOutboxTableCompanion({
    this.id = const Value.absent(),
    this.repairId = const Value.absent(),
    this.operation = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TrackingSyncOutboxTableCompanion.insert({
    this.id = const Value.absent(),
    required int repairId,
    required String operation,
    required int attemptCount,
    this.lastError = const Value.absent(),
    required DateTime nextAttemptAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : repairId = Value(repairId),
       operation = Value(operation),
       attemptCount = Value(attemptCount),
       nextAttemptAt = Value(nextAttemptAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TrackingSyncOutboxRow> custom({
    Expression<int>? id,
    Expression<int>? repairId,
    Expression<String>? operation,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (repairId != null) 'repair_id': repairId,
      if (operation != null) 'operation': operation,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TrackingSyncOutboxTableCompanion copyWith({
    Value<int>? id,
    Value<int>? repairId,
    Value<String>? operation,
    Value<int>? attemptCount,
    Value<String?>? lastError,
    Value<DateTime>? nextAttemptAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return TrackingSyncOutboxTableCompanion(
      id: id ?? this.id,
      repairId: repairId ?? this.repairId,
      operation: operation ?? this.operation,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (repairId.present) {
      map['repair_id'] = Variable<int>(repairId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackingSyncOutboxTableCompanion(')
          ..write('id: $id, ')
          ..write('repairId: $repairId, ')
          ..write('operation: $operation, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RepairsTable repairs = $RepairsTable(this);
  late final $RepairCodeSequenceTableTable repairCodeSequenceTable =
      $RepairCodeSequenceTableTable(this);
  late final $ShopSettingsTableTable shopSettingsTable =
      $ShopSettingsTableTable(this);
  late final $CommonProblemsTable commonProblems = $CommonProblemsTable(this);
  late final $TrackingSyncOutboxTableTable trackingSyncOutboxTable =
      $TrackingSyncOutboxTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    repairs,
    repairCodeSequenceTable,
    shopSettingsTable,
    commonProblems,
    trackingSyncOutboxTable,
  ];
}

typedef $$RepairsTableCreateCompanionBuilder =
    RepairsCompanion Function({
      Value<int> id,
      required String repairCode,
      Value<String?> customerName,
      Value<String?> customerPhone,
      Value<String?> deviceType,
      Value<String?> brand,
      Value<String?> model,
      required String reportedProblem,
      Value<String?> receivedAccessories,
      Value<String?> deviceAccessInfo,
      required String status,
      Value<int?> priceAmount,
      Value<String> customerPriceDecision,
      Value<String?> internalNotes,
      Value<String?> customerMessage,
      Value<int?> parentRepairId,
      Value<String?> trackingToken,
      required DateTime createdAt,
      required DateTime updatedAt,
      required DateTime receivedAt,
      Value<DateTime?> readyAt,
      Value<DateTime?> deliveredAt,
    });
typedef $$RepairsTableUpdateCompanionBuilder =
    RepairsCompanion Function({
      Value<int> id,
      Value<String> repairCode,
      Value<String?> customerName,
      Value<String?> customerPhone,
      Value<String?> deviceType,
      Value<String?> brand,
      Value<String?> model,
      Value<String> reportedProblem,
      Value<String?> receivedAccessories,
      Value<String?> deviceAccessInfo,
      Value<String> status,
      Value<int?> priceAmount,
      Value<String> customerPriceDecision,
      Value<String?> internalNotes,
      Value<String?> customerMessage,
      Value<int?> parentRepairId,
      Value<String?> trackingToken,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime> receivedAt,
      Value<DateTime?> readyAt,
      Value<DateTime?> deliveredAt,
    });

final class $$RepairsTableReferences
    extends BaseReferences<_$AppDatabase, $RepairsTable, RepairRow> {
  $$RepairsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $TrackingSyncOutboxTableTable,
    List<TrackingSyncOutboxRow>
  >
  _trackingSyncOutboxTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.trackingSyncOutboxTable,
        aliasName: 'repairs__id__tracking_sync_outbox__repair_id',
      );

  $$TrackingSyncOutboxTableTableProcessedTableManager
  get trackingSyncOutboxTableRefs {
    final manager = $$TrackingSyncOutboxTableTableTableManager(
      $_db,
      $_db.trackingSyncOutboxTable,
    ).filter((f) => f.repairId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _trackingSyncOutboxTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RepairsTableFilterComposer
    extends Composer<_$AppDatabase, $RepairsTable> {
  $$RepairsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repairCode => $composableBuilder(
    column: $table.repairCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceType => $composableBuilder(
    column: $table.deviceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportedProblem => $composableBuilder(
    column: $table.reportedProblem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receivedAccessories => $composableBuilder(
    column: $table.receivedAccessories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceAccessInfo => $composableBuilder(
    column: $table.deviceAccessInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceAmount => $composableBuilder(
    column: $table.priceAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerPriceDecision => $composableBuilder(
    column: $table.customerPriceDecision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get internalNotes => $composableBuilder(
    column: $table.internalNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerMessage => $composableBuilder(
    column: $table.customerMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parentRepairId => $composableBuilder(
    column: $table.parentRepairId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackingToken => $composableBuilder(
    column: $table.trackingToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get readyAt => $composableBuilder(
    column: $table.readyAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> trackingSyncOutboxTableRefs(
    Expression<bool> Function($$TrackingSyncOutboxTableTableFilterComposer f) f,
  ) {
    final $$TrackingSyncOutboxTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.trackingSyncOutboxTable,
          getReferencedColumn: (t) => t.repairId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TrackingSyncOutboxTableTableFilterComposer(
                $db: $db,
                $table: $db.trackingSyncOutboxTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RepairsTableOrderingComposer
    extends Composer<_$AppDatabase, $RepairsTable> {
  $$RepairsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repairCode => $composableBuilder(
    column: $table.repairCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceType => $composableBuilder(
    column: $table.deviceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportedProblem => $composableBuilder(
    column: $table.reportedProblem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receivedAccessories => $composableBuilder(
    column: $table.receivedAccessories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceAccessInfo => $composableBuilder(
    column: $table.deviceAccessInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceAmount => $composableBuilder(
    column: $table.priceAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerPriceDecision => $composableBuilder(
    column: $table.customerPriceDecision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get internalNotes => $composableBuilder(
    column: $table.internalNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerMessage => $composableBuilder(
    column: $table.customerMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parentRepairId => $composableBuilder(
    column: $table.parentRepairId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackingToken => $composableBuilder(
    column: $table.trackingToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get readyAt => $composableBuilder(
    column: $table.readyAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RepairsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RepairsTable> {
  $$RepairsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get repairCode => $composableBuilder(
    column: $table.repairCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceType => $composableBuilder(
    column: $table.deviceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get reportedProblem => $composableBuilder(
    column: $table.reportedProblem,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receivedAccessories => $composableBuilder(
    column: $table.receivedAccessories,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceAccessInfo => $composableBuilder(
    column: $table.deviceAccessInfo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get priceAmount => $composableBuilder(
    column: $table.priceAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerPriceDecision => $composableBuilder(
    column: $table.customerPriceDecision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get internalNotes => $composableBuilder(
    column: $table.internalNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerMessage => $composableBuilder(
    column: $table.customerMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get parentRepairId => $composableBuilder(
    column: $table.parentRepairId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackingToken => $composableBuilder(
    column: $table.trackingToken,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get readyAt =>
      $composableBuilder(column: $table.readyAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => column,
  );

  Expression<T> trackingSyncOutboxTableRefs<T extends Object>(
    Expression<T> Function($$TrackingSyncOutboxTableTableAnnotationComposer a)
    f,
  ) {
    final $$TrackingSyncOutboxTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.trackingSyncOutboxTable,
          getReferencedColumn: (t) => t.repairId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TrackingSyncOutboxTableTableAnnotationComposer(
                $db: $db,
                $table: $db.trackingSyncOutboxTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RepairsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RepairsTable,
          RepairRow,
          $$RepairsTableFilterComposer,
          $$RepairsTableOrderingComposer,
          $$RepairsTableAnnotationComposer,
          $$RepairsTableCreateCompanionBuilder,
          $$RepairsTableUpdateCompanionBuilder,
          (RepairRow, $$RepairsTableReferences),
          RepairRow,
          PrefetchHooks Function({bool trackingSyncOutboxTableRefs})
        > {
  $$RepairsTableTableManager(_$AppDatabase db, $RepairsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RepairsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RepairsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RepairsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> repairCode = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerPhone = const Value.absent(),
                Value<String?> deviceType = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String> reportedProblem = const Value.absent(),
                Value<String?> receivedAccessories = const Value.absent(),
                Value<String?> deviceAccessInfo = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> priceAmount = const Value.absent(),
                Value<String> customerPriceDecision = const Value.absent(),
                Value<String?> internalNotes = const Value.absent(),
                Value<String?> customerMessage = const Value.absent(),
                Value<int?> parentRepairId = const Value.absent(),
                Value<String?> trackingToken = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<DateTime?> readyAt = const Value.absent(),
                Value<DateTime?> deliveredAt = const Value.absent(),
              }) => RepairsCompanion(
                id: id,
                repairCode: repairCode,
                customerName: customerName,
                customerPhone: customerPhone,
                deviceType: deviceType,
                brand: brand,
                model: model,
                reportedProblem: reportedProblem,
                receivedAccessories: receivedAccessories,
                deviceAccessInfo: deviceAccessInfo,
                status: status,
                priceAmount: priceAmount,
                customerPriceDecision: customerPriceDecision,
                internalNotes: internalNotes,
                customerMessage: customerMessage,
                parentRepairId: parentRepairId,
                trackingToken: trackingToken,
                createdAt: createdAt,
                updatedAt: updatedAt,
                receivedAt: receivedAt,
                readyAt: readyAt,
                deliveredAt: deliveredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String repairCode,
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerPhone = const Value.absent(),
                Value<String?> deviceType = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> model = const Value.absent(),
                required String reportedProblem,
                Value<String?> receivedAccessories = const Value.absent(),
                Value<String?> deviceAccessInfo = const Value.absent(),
                required String status,
                Value<int?> priceAmount = const Value.absent(),
                Value<String> customerPriceDecision = const Value.absent(),
                Value<String?> internalNotes = const Value.absent(),
                Value<String?> customerMessage = const Value.absent(),
                Value<int?> parentRepairId = const Value.absent(),
                Value<String?> trackingToken = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required DateTime receivedAt,
                Value<DateTime?> readyAt = const Value.absent(),
                Value<DateTime?> deliveredAt = const Value.absent(),
              }) => RepairsCompanion.insert(
                id: id,
                repairCode: repairCode,
                customerName: customerName,
                customerPhone: customerPhone,
                deviceType: deviceType,
                brand: brand,
                model: model,
                reportedProblem: reportedProblem,
                receivedAccessories: receivedAccessories,
                deviceAccessInfo: deviceAccessInfo,
                status: status,
                priceAmount: priceAmount,
                customerPriceDecision: customerPriceDecision,
                internalNotes: internalNotes,
                customerMessage: customerMessage,
                parentRepairId: parentRepairId,
                trackingToken: trackingToken,
                createdAt: createdAt,
                updatedAt: updatedAt,
                receivedAt: receivedAt,
                readyAt: readyAt,
                deliveredAt: deliveredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RepairsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackingSyncOutboxTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (trackingSyncOutboxTableRefs) db.trackingSyncOutboxTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (trackingSyncOutboxTableRefs)
                    await $_getPrefetchedData<
                      RepairRow,
                      $RepairsTable,
                      TrackingSyncOutboxRow
                    >(
                      currentTable: table,
                      referencedTable: $$RepairsTableReferences
                          ._trackingSyncOutboxTableRefsTable(db),
                      managerFromTypedResult: (p0) => $$RepairsTableReferences(
                        db,
                        table,
                        p0,
                      ).trackingSyncOutboxTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.repairId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RepairsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RepairsTable,
      RepairRow,
      $$RepairsTableFilterComposer,
      $$RepairsTableOrderingComposer,
      $$RepairsTableAnnotationComposer,
      $$RepairsTableCreateCompanionBuilder,
      $$RepairsTableUpdateCompanionBuilder,
      (RepairRow, $$RepairsTableReferences),
      RepairRow,
      PrefetchHooks Function({bool trackingSyncOutboxTableRefs})
    >;
typedef $$RepairCodeSequenceTableTableCreateCompanionBuilder =
    RepairCodeSequenceTableCompanion Function({
      Value<int> id,
      required int lastUsedSequence,
    });
typedef $$RepairCodeSequenceTableTableUpdateCompanionBuilder =
    RepairCodeSequenceTableCompanion Function({
      Value<int> id,
      Value<int> lastUsedSequence,
    });

class $$RepairCodeSequenceTableTableFilterComposer
    extends Composer<_$AppDatabase, $RepairCodeSequenceTableTable> {
  $$RepairCodeSequenceTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUsedSequence => $composableBuilder(
    column: $table.lastUsedSequence,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RepairCodeSequenceTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RepairCodeSequenceTableTable> {
  $$RepairCodeSequenceTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUsedSequence => $composableBuilder(
    column: $table.lastUsedSequence,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RepairCodeSequenceTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RepairCodeSequenceTableTable> {
  $$RepairCodeSequenceTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lastUsedSequence => $composableBuilder(
    column: $table.lastUsedSequence,
    builder: (column) => column,
  );
}

class $$RepairCodeSequenceTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RepairCodeSequenceTableTable,
          RepairCodeSequenceRow,
          $$RepairCodeSequenceTableTableFilterComposer,
          $$RepairCodeSequenceTableTableOrderingComposer,
          $$RepairCodeSequenceTableTableAnnotationComposer,
          $$RepairCodeSequenceTableTableCreateCompanionBuilder,
          $$RepairCodeSequenceTableTableUpdateCompanionBuilder,
          (
            RepairCodeSequenceRow,
            BaseReferences<
              _$AppDatabase,
              $RepairCodeSequenceTableTable,
              RepairCodeSequenceRow
            >,
          ),
          RepairCodeSequenceRow,
          PrefetchHooks Function()
        > {
  $$RepairCodeSequenceTableTableTableManager(
    _$AppDatabase db,
    $RepairCodeSequenceTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RepairCodeSequenceTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RepairCodeSequenceTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RepairCodeSequenceTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> lastUsedSequence = const Value.absent(),
              }) => RepairCodeSequenceTableCompanion(
                id: id,
                lastUsedSequence: lastUsedSequence,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int lastUsedSequence,
              }) => RepairCodeSequenceTableCompanion.insert(
                id: id,
                lastUsedSequence: lastUsedSequence,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RepairCodeSequenceTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RepairCodeSequenceTableTable,
      RepairCodeSequenceRow,
      $$RepairCodeSequenceTableTableFilterComposer,
      $$RepairCodeSequenceTableTableOrderingComposer,
      $$RepairCodeSequenceTableTableAnnotationComposer,
      $$RepairCodeSequenceTableTableCreateCompanionBuilder,
      $$RepairCodeSequenceTableTableUpdateCompanionBuilder,
      (
        RepairCodeSequenceRow,
        BaseReferences<
          _$AppDatabase,
          $RepairCodeSequenceTableTable,
          RepairCodeSequenceRow
        >,
      ),
      RepairCodeSequenceRow,
      PrefetchHooks Function()
    >;
typedef $$ShopSettingsTableTableCreateCompanionBuilder =
    ShopSettingsTableCompanion Function({
      Value<int> id,
      required String shopName,
      Value<String?> shopSubtitle,
      Value<String?> phoneNumber,
      Value<String?> address,
      Value<String?> logoPath,
      required String repairCodePrefix,
      required int repairCodeNumberWidth,
      Value<String?> ticketFooter,
      Value<String?> warrantyTerms,
      Value<String?> defaultCustomerTicketPrinterId,
      Value<String?> defaultDeviceLabelPrinterId,
      Value<String?> publicShopId,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$ShopSettingsTableTableUpdateCompanionBuilder =
    ShopSettingsTableCompanion Function({
      Value<int> id,
      Value<String> shopName,
      Value<String?> shopSubtitle,
      Value<String?> phoneNumber,
      Value<String?> address,
      Value<String?> logoPath,
      Value<String> repairCodePrefix,
      Value<int> repairCodeNumberWidth,
      Value<String?> ticketFooter,
      Value<String?> warrantyTerms,
      Value<String?> defaultCustomerTicketPrinterId,
      Value<String?> defaultDeviceLabelPrinterId,
      Value<String?> publicShopId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$ShopSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ShopSettingsTableTable> {
  $$ShopSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopName => $composableBuilder(
    column: $table.shopName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopSubtitle => $composableBuilder(
    column: $table.shopSubtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repairCodePrefix => $composableBuilder(
    column: $table.repairCodePrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repairCodeNumberWidth => $composableBuilder(
    column: $table.repairCodeNumberWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ticketFooter => $composableBuilder(
    column: $table.ticketFooter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warrantyTerms => $composableBuilder(
    column: $table.warrantyTerms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultCustomerTicketPrinterId =>
      $composableBuilder(
        column: $table.defaultCustomerTicketPrinterId,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<String> get defaultDeviceLabelPrinterId => $composableBuilder(
    column: $table.defaultDeviceLabelPrinterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicShopId => $composableBuilder(
    column: $table.publicShopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShopSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ShopSettingsTableTable> {
  $$ShopSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopName => $composableBuilder(
    column: $table.shopName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopSubtitle => $composableBuilder(
    column: $table.shopSubtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repairCodePrefix => $composableBuilder(
    column: $table.repairCodePrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repairCodeNumberWidth => $composableBuilder(
    column: $table.repairCodeNumberWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ticketFooter => $composableBuilder(
    column: $table.ticketFooter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warrantyTerms => $composableBuilder(
    column: $table.warrantyTerms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultCustomerTicketPrinterId =>
      $composableBuilder(
        column: $table.defaultCustomerTicketPrinterId,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<String> get defaultDeviceLabelPrinterId => $composableBuilder(
    column: $table.defaultDeviceLabelPrinterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicShopId => $composableBuilder(
    column: $table.publicShopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShopSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShopSettingsTableTable> {
  $$ShopSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopName =>
      $composableBuilder(column: $table.shopName, builder: (column) => column);

  GeneratedColumn<String> get shopSubtitle => $composableBuilder(
    column: $table.shopSubtitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get logoPath =>
      $composableBuilder(column: $table.logoPath, builder: (column) => column);

  GeneratedColumn<String> get repairCodePrefix => $composableBuilder(
    column: $table.repairCodePrefix,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repairCodeNumberWidth => $composableBuilder(
    column: $table.repairCodeNumberWidth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ticketFooter => $composableBuilder(
    column: $table.ticketFooter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get warrantyTerms => $composableBuilder(
    column: $table.warrantyTerms,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultCustomerTicketPrinterId =>
      $composableBuilder(
        column: $table.defaultCustomerTicketPrinterId,
        builder: (column) => column,
      );

  GeneratedColumn<String> get defaultDeviceLabelPrinterId => $composableBuilder(
    column: $table.defaultDeviceLabelPrinterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get publicShopId => $composableBuilder(
    column: $table.publicShopId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ShopSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShopSettingsTableTable,
          ShopSettingsRow,
          $$ShopSettingsTableTableFilterComposer,
          $$ShopSettingsTableTableOrderingComposer,
          $$ShopSettingsTableTableAnnotationComposer,
          $$ShopSettingsTableTableCreateCompanionBuilder,
          $$ShopSettingsTableTableUpdateCompanionBuilder,
          (
            ShopSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $ShopSettingsTableTable,
              ShopSettingsRow
            >,
          ),
          ShopSettingsRow,
          PrefetchHooks Function()
        > {
  $$ShopSettingsTableTableTableManager(
    _$AppDatabase db,
    $ShopSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShopSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShopSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShopSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> shopName = const Value.absent(),
                Value<String?> shopSubtitle = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> logoPath = const Value.absent(),
                Value<String> repairCodePrefix = const Value.absent(),
                Value<int> repairCodeNumberWidth = const Value.absent(),
                Value<String?> ticketFooter = const Value.absent(),
                Value<String?> warrantyTerms = const Value.absent(),
                Value<String?> defaultCustomerTicketPrinterId =
                    const Value.absent(),
                Value<String?> defaultDeviceLabelPrinterId =
                    const Value.absent(),
                Value<String?> publicShopId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ShopSettingsTableCompanion(
                id: id,
                shopName: shopName,
                shopSubtitle: shopSubtitle,
                phoneNumber: phoneNumber,
                address: address,
                logoPath: logoPath,
                repairCodePrefix: repairCodePrefix,
                repairCodeNumberWidth: repairCodeNumberWidth,
                ticketFooter: ticketFooter,
                warrantyTerms: warrantyTerms,
                defaultCustomerTicketPrinterId: defaultCustomerTicketPrinterId,
                defaultDeviceLabelPrinterId: defaultDeviceLabelPrinterId,
                publicShopId: publicShopId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String shopName,
                Value<String?> shopSubtitle = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> logoPath = const Value.absent(),
                required String repairCodePrefix,
                required int repairCodeNumberWidth,
                Value<String?> ticketFooter = const Value.absent(),
                Value<String?> warrantyTerms = const Value.absent(),
                Value<String?> defaultCustomerTicketPrinterId =
                    const Value.absent(),
                Value<String?> defaultDeviceLabelPrinterId =
                    const Value.absent(),
                Value<String?> publicShopId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ShopSettingsTableCompanion.insert(
                id: id,
                shopName: shopName,
                shopSubtitle: shopSubtitle,
                phoneNumber: phoneNumber,
                address: address,
                logoPath: logoPath,
                repairCodePrefix: repairCodePrefix,
                repairCodeNumberWidth: repairCodeNumberWidth,
                ticketFooter: ticketFooter,
                warrantyTerms: warrantyTerms,
                defaultCustomerTicketPrinterId: defaultCustomerTicketPrinterId,
                defaultDeviceLabelPrinterId: defaultDeviceLabelPrinterId,
                publicShopId: publicShopId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShopSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShopSettingsTableTable,
      ShopSettingsRow,
      $$ShopSettingsTableTableFilterComposer,
      $$ShopSettingsTableTableOrderingComposer,
      $$ShopSettingsTableTableAnnotationComposer,
      $$ShopSettingsTableTableCreateCompanionBuilder,
      $$ShopSettingsTableTableUpdateCompanionBuilder,
      (
        ShopSettingsRow,
        BaseReferences<_$AppDatabase, $ShopSettingsTableTable, ShopSettingsRow>,
      ),
      ShopSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$CommonProblemsTableCreateCompanionBuilder =
    CommonProblemsCompanion Function({
      Value<int> id,
      required String title,
      required String normalizedTitle,
      required int usageCount,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$CommonProblemsTableUpdateCompanionBuilder =
    CommonProblemsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> normalizedTitle,
      Value<int> usageCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$CommonProblemsTableFilterComposer
    extends Composer<_$AppDatabase, $CommonProblemsTable> {
  $$CommonProblemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usageCount => $composableBuilder(
    column: $table.usageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CommonProblemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CommonProblemsTable> {
  $$CommonProblemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usageCount => $composableBuilder(
    column: $table.usageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CommonProblemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CommonProblemsTable> {
  $$CommonProblemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get usageCount => $composableBuilder(
    column: $table.usageCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CommonProblemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CommonProblemsTable,
          CommonProblemRow,
          $$CommonProblemsTableFilterComposer,
          $$CommonProblemsTableOrderingComposer,
          $$CommonProblemsTableAnnotationComposer,
          $$CommonProblemsTableCreateCompanionBuilder,
          $$CommonProblemsTableUpdateCompanionBuilder,
          (
            CommonProblemRow,
            BaseReferences<
              _$AppDatabase,
              $CommonProblemsTable,
              CommonProblemRow
            >,
          ),
          CommonProblemRow,
          PrefetchHooks Function()
        > {
  $$CommonProblemsTableTableManager(
    _$AppDatabase db,
    $CommonProblemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommonProblemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommonProblemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommonProblemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> normalizedTitle = const Value.absent(),
                Value<int> usageCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CommonProblemsCompanion(
                id: id,
                title: title,
                normalizedTitle: normalizedTitle,
                usageCount: usageCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String normalizedTitle,
                required int usageCount,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => CommonProblemsCompanion.insert(
                id: id,
                title: title,
                normalizedTitle: normalizedTitle,
                usageCount: usageCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CommonProblemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CommonProblemsTable,
      CommonProblemRow,
      $$CommonProblemsTableFilterComposer,
      $$CommonProblemsTableOrderingComposer,
      $$CommonProblemsTableAnnotationComposer,
      $$CommonProblemsTableCreateCompanionBuilder,
      $$CommonProblemsTableUpdateCompanionBuilder,
      (
        CommonProblemRow,
        BaseReferences<_$AppDatabase, $CommonProblemsTable, CommonProblemRow>,
      ),
      CommonProblemRow,
      PrefetchHooks Function()
    >;
typedef $$TrackingSyncOutboxTableTableCreateCompanionBuilder =
    TrackingSyncOutboxTableCompanion Function({
      Value<int> id,
      required int repairId,
      required String operation,
      required int attemptCount,
      Value<String?> lastError,
      required DateTime nextAttemptAt,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$TrackingSyncOutboxTableTableUpdateCompanionBuilder =
    TrackingSyncOutboxTableCompanion Function({
      Value<int> id,
      Value<int> repairId,
      Value<String> operation,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<DateTime> nextAttemptAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$TrackingSyncOutboxTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TrackingSyncOutboxTableTable,
          TrackingSyncOutboxRow
        > {
  $$TrackingSyncOutboxTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RepairsTable _repairIdTable(_$AppDatabase db) =>
      db.repairs.createAlias('tracking_sync_outbox__repair_id__repairs__id');

  $$RepairsTableProcessedTableManager get repairId {
    final $_column = $_itemColumn<int>('repair_id')!;

    final manager = $$RepairsTableTableManager(
      $_db,
      $_db.repairs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_repairIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackingSyncOutboxTableTableFilterComposer
    extends Composer<_$AppDatabase, $TrackingSyncOutboxTableTable> {
  $$TrackingSyncOutboxTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RepairsTableFilterComposer get repairId {
    final $$RepairsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.repairId,
      referencedTable: $db.repairs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RepairsTableFilterComposer(
            $db: $db,
            $table: $db.repairs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackingSyncOutboxTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackingSyncOutboxTableTable> {
  $$TrackingSyncOutboxTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RepairsTableOrderingComposer get repairId {
    final $$RepairsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.repairId,
      referencedTable: $db.repairs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RepairsTableOrderingComposer(
            $db: $db,
            $table: $db.repairs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackingSyncOutboxTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackingSyncOutboxTableTable> {
  $$TrackingSyncOutboxTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RepairsTableAnnotationComposer get repairId {
    final $$RepairsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.repairId,
      referencedTable: $db.repairs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RepairsTableAnnotationComposer(
            $db: $db,
            $table: $db.repairs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackingSyncOutboxTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackingSyncOutboxTableTable,
          TrackingSyncOutboxRow,
          $$TrackingSyncOutboxTableTableFilterComposer,
          $$TrackingSyncOutboxTableTableOrderingComposer,
          $$TrackingSyncOutboxTableTableAnnotationComposer,
          $$TrackingSyncOutboxTableTableCreateCompanionBuilder,
          $$TrackingSyncOutboxTableTableUpdateCompanionBuilder,
          (TrackingSyncOutboxRow, $$TrackingSyncOutboxTableTableReferences),
          TrackingSyncOutboxRow,
          PrefetchHooks Function({bool repairId})
        > {
  $$TrackingSyncOutboxTableTableTableManager(
    _$AppDatabase db,
    $TrackingSyncOutboxTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackingSyncOutboxTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TrackingSyncOutboxTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TrackingSyncOutboxTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> repairId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> nextAttemptAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TrackingSyncOutboxTableCompanion(
                id: id,
                repairId: repairId,
                operation: operation,
                attemptCount: attemptCount,
                lastError: lastError,
                nextAttemptAt: nextAttemptAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int repairId,
                required String operation,
                required int attemptCount,
                Value<String?> lastError = const Value.absent(),
                required DateTime nextAttemptAt,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => TrackingSyncOutboxTableCompanion.insert(
                id: id,
                repairId: repairId,
                operation: operation,
                attemptCount: attemptCount,
                lastError: lastError,
                nextAttemptAt: nextAttemptAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TrackingSyncOutboxTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({repairId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (repairId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.repairId,
                                referencedTable:
                                    $$TrackingSyncOutboxTableTableReferences
                                        ._repairIdTable(db),
                                referencedColumn:
                                    $$TrackingSyncOutboxTableTableReferences
                                        ._repairIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrackingSyncOutboxTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackingSyncOutboxTableTable,
      TrackingSyncOutboxRow,
      $$TrackingSyncOutboxTableTableFilterComposer,
      $$TrackingSyncOutboxTableTableOrderingComposer,
      $$TrackingSyncOutboxTableTableAnnotationComposer,
      $$TrackingSyncOutboxTableTableCreateCompanionBuilder,
      $$TrackingSyncOutboxTableTableUpdateCompanionBuilder,
      (TrackingSyncOutboxRow, $$TrackingSyncOutboxTableTableReferences),
      TrackingSyncOutboxRow,
      PrefetchHooks Function({bool repairId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RepairsTableTableManager get repairs =>
      $$RepairsTableTableManager(_db, _db.repairs);
  $$RepairCodeSequenceTableTableTableManager get repairCodeSequenceTable =>
      $$RepairCodeSequenceTableTableTableManager(
        _db,
        _db.repairCodeSequenceTable,
      );
  $$ShopSettingsTableTableTableManager get shopSettingsTable =>
      $$ShopSettingsTableTableTableManager(_db, _db.shopSettingsTable);
  $$CommonProblemsTableTableManager get commonProblems =>
      $$CommonProblemsTableTableManager(_db, _db.commonProblems);
  $$TrackingSyncOutboxTableTableTableManager get trackingSyncOutboxTable =>
      $$TrackingSyncOutboxTableTableTableManager(
        _db,
        _db.trackingSyncOutboxTable,
      );
}
