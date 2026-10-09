// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_snapshot200_response_alarms_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const GetSnapshot200ResponseAlarmsInnerStateEnum
_$getSnapshot200ResponseAlarmsInnerStateEnum_planned =
    const GetSnapshot200ResponseAlarmsInnerStateEnum._('planned');
const GetSnapshot200ResponseAlarmsInnerStateEnum
_$getSnapshot200ResponseAlarmsInnerStateEnum_triggered =
    const GetSnapshot200ResponseAlarmsInnerStateEnum._('triggered');
const GetSnapshot200ResponseAlarmsInnerStateEnum
_$getSnapshot200ResponseAlarmsInnerStateEnum_missed =
    const GetSnapshot200ResponseAlarmsInnerStateEnum._('missed');
const GetSnapshot200ResponseAlarmsInnerStateEnum
_$getSnapshot200ResponseAlarmsInnerStateEnum_discarded =
    const GetSnapshot200ResponseAlarmsInnerStateEnum._('discarded');

GetSnapshot200ResponseAlarmsInnerStateEnum
_$getSnapshot200ResponseAlarmsInnerStateEnumValueOf(String name) {
  switch (name) {
    case 'planned':
      return _$getSnapshot200ResponseAlarmsInnerStateEnum_planned;
    case 'triggered':
      return _$getSnapshot200ResponseAlarmsInnerStateEnum_triggered;
    case 'missed':
      return _$getSnapshot200ResponseAlarmsInnerStateEnum_missed;
    case 'discarded':
      return _$getSnapshot200ResponseAlarmsInnerStateEnum_discarded;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<GetSnapshot200ResponseAlarmsInnerStateEnum>
_$getSnapshot200ResponseAlarmsInnerStateEnumValues =
    BuiltSet<GetSnapshot200ResponseAlarmsInnerStateEnum>(
      const <GetSnapshot200ResponseAlarmsInnerStateEnum>[
        _$getSnapshot200ResponseAlarmsInnerStateEnum_planned,
        _$getSnapshot200ResponseAlarmsInnerStateEnum_triggered,
        _$getSnapshot200ResponseAlarmsInnerStateEnum_missed,
        _$getSnapshot200ResponseAlarmsInnerStateEnum_discarded,
      ],
    );

Serializer<GetSnapshot200ResponseAlarmsInnerStateEnum>
_$getSnapshot200ResponseAlarmsInnerStateEnumSerializer =
    _$GetSnapshot200ResponseAlarmsInnerStateEnumSerializer();

class _$GetSnapshot200ResponseAlarmsInnerStateEnumSerializer
    implements PrimitiveSerializer<GetSnapshot200ResponseAlarmsInnerStateEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'planned': 'planned',
    'triggered': 'triggered',
    'missed': 'missed',
    'discarded': 'discarded',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'planned': 'planned',
    'triggered': 'triggered',
    'missed': 'missed',
    'discarded': 'discarded',
  };

  @override
  final Iterable<Type> types = const <Type>[
    GetSnapshot200ResponseAlarmsInnerStateEnum,
  ];
  @override
  final String wireName = 'GetSnapshot200ResponseAlarmsInnerStateEnum';

  @override
  Object serialize(
    Serializers serializers,
    GetSnapshot200ResponseAlarmsInnerStateEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  GetSnapshot200ResponseAlarmsInnerStateEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => GetSnapshot200ResponseAlarmsInnerStateEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$GetSnapshot200ResponseAlarmsInner
    extends GetSnapshot200ResponseAlarmsInner {
  @override
  final String id;
  @override
  final String incidentId;
  @override
  final GetSnapshot200ResponseAlarmsInnerStateEnum state;
  @override
  final String? scheduledAt;
  @override
  final String? triggeredAt;
  @override
  final BuiltList<String> vehicleIds;
  @override
  final BuiltList<GetSnapshot200ResponseAlarmsInnerRecipientsInner> recipients;
  @override
  final int pushDelivered;
  @override
  final int pushRejected;

  factory _$GetSnapshot200ResponseAlarmsInner([
    void Function(GetSnapshot200ResponseAlarmsInnerBuilder)? updates,
  ]) => (GetSnapshot200ResponseAlarmsInnerBuilder()..update(updates))._build();

  _$GetSnapshot200ResponseAlarmsInner._({
    required this.id,
    required this.incidentId,
    required this.state,
    this.scheduledAt,
    this.triggeredAt,
    required this.vehicleIds,
    required this.recipients,
    required this.pushDelivered,
    required this.pushRejected,
  }) : super._();
  @override
  GetSnapshot200ResponseAlarmsInner rebuild(
    void Function(GetSnapshot200ResponseAlarmsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetSnapshot200ResponseAlarmsInnerBuilder toBuilder() =>
      GetSnapshot200ResponseAlarmsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetSnapshot200ResponseAlarmsInner &&
        id == other.id &&
        incidentId == other.incidentId &&
        state == other.state &&
        scheduledAt == other.scheduledAt &&
        triggeredAt == other.triggeredAt &&
        vehicleIds == other.vehicleIds &&
        recipients == other.recipients &&
        pushDelivered == other.pushDelivered &&
        pushRejected == other.pushRejected;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, incidentId.hashCode);
    _$hash = $jc(_$hash, state.hashCode);
    _$hash = $jc(_$hash, scheduledAt.hashCode);
    _$hash = $jc(_$hash, triggeredAt.hashCode);
    _$hash = $jc(_$hash, vehicleIds.hashCode);
    _$hash = $jc(_$hash, recipients.hashCode);
    _$hash = $jc(_$hash, pushDelivered.hashCode);
    _$hash = $jc(_$hash, pushRejected.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GetSnapshot200ResponseAlarmsInner')
          ..add('id', id)
          ..add('incidentId', incidentId)
          ..add('state', state)
          ..add('scheduledAt', scheduledAt)
          ..add('triggeredAt', triggeredAt)
          ..add('vehicleIds', vehicleIds)
          ..add('recipients', recipients)
          ..add('pushDelivered', pushDelivered)
          ..add('pushRejected', pushRejected))
        .toString();
  }
}

class GetSnapshot200ResponseAlarmsInnerBuilder
    implements
        Builder<
          GetSnapshot200ResponseAlarmsInner,
          GetSnapshot200ResponseAlarmsInnerBuilder
        > {
  _$GetSnapshot200ResponseAlarmsInner? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _incidentId;
  String? get incidentId => _$this._incidentId;
  set incidentId(String? incidentId) => _$this._incidentId = incidentId;

  GetSnapshot200ResponseAlarmsInnerStateEnum? _state;
  GetSnapshot200ResponseAlarmsInnerStateEnum? get state => _$this._state;
  set state(GetSnapshot200ResponseAlarmsInnerStateEnum? state) =>
      _$this._state = state;

  String? _scheduledAt;
  String? get scheduledAt => _$this._scheduledAt;
  set scheduledAt(String? scheduledAt) => _$this._scheduledAt = scheduledAt;

  String? _triggeredAt;
  String? get triggeredAt => _$this._triggeredAt;
  set triggeredAt(String? triggeredAt) => _$this._triggeredAt = triggeredAt;

  ListBuilder<String>? _vehicleIds;
  ListBuilder<String> get vehicleIds =>
      _$this._vehicleIds ??= ListBuilder<String>();
  set vehicleIds(ListBuilder<String>? vehicleIds) =>
      _$this._vehicleIds = vehicleIds;

  ListBuilder<GetSnapshot200ResponseAlarmsInnerRecipientsInner>? _recipients;
  ListBuilder<GetSnapshot200ResponseAlarmsInnerRecipientsInner>
  get recipients => _$this._recipients ??=
      ListBuilder<GetSnapshot200ResponseAlarmsInnerRecipientsInner>();
  set recipients(
    ListBuilder<GetSnapshot200ResponseAlarmsInnerRecipientsInner>? recipients,
  ) => _$this._recipients = recipients;

  int? _pushDelivered;
  int? get pushDelivered => _$this._pushDelivered;
  set pushDelivered(int? pushDelivered) =>
      _$this._pushDelivered = pushDelivered;

  int? _pushRejected;
  int? get pushRejected => _$this._pushRejected;
  set pushRejected(int? pushRejected) => _$this._pushRejected = pushRejected;

  GetSnapshot200ResponseAlarmsInnerBuilder() {
    GetSnapshot200ResponseAlarmsInner._defaults(this);
  }

  GetSnapshot200ResponseAlarmsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _incidentId = $v.incidentId;
      _state = $v.state;
      _scheduledAt = $v.scheduledAt;
      _triggeredAt = $v.triggeredAt;
      _vehicleIds = $v.vehicleIds.toBuilder();
      _recipients = $v.recipients.toBuilder();
      _pushDelivered = $v.pushDelivered;
      _pushRejected = $v.pushRejected;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetSnapshot200ResponseAlarmsInner other) {
    _$v = other as _$GetSnapshot200ResponseAlarmsInner;
  }

  @override
  void update(
    void Function(GetSnapshot200ResponseAlarmsInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  GetSnapshot200ResponseAlarmsInner build() => _build();

  _$GetSnapshot200ResponseAlarmsInner _build() {
    _$GetSnapshot200ResponseAlarmsInner _$result;
    try {
      _$result =
          _$v ??
          _$GetSnapshot200ResponseAlarmsInner._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'GetSnapshot200ResponseAlarmsInner',
              'id',
            ),
            incidentId: BuiltValueNullFieldError.checkNotNull(
              incidentId,
              r'GetSnapshot200ResponseAlarmsInner',
              'incidentId',
            ),
            state: BuiltValueNullFieldError.checkNotNull(
              state,
              r'GetSnapshot200ResponseAlarmsInner',
              'state',
            ),
            scheduledAt: scheduledAt,
            triggeredAt: triggeredAt,
            vehicleIds: vehicleIds.build(),
            recipients: recipients.build(),
            pushDelivered: BuiltValueNullFieldError.checkNotNull(
              pushDelivered,
              r'GetSnapshot200ResponseAlarmsInner',
              'pushDelivered',
            ),
            pushRejected: BuiltValueNullFieldError.checkNotNull(
              pushRejected,
              r'GetSnapshot200ResponseAlarmsInner',
              'pushRejected',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'vehicleIds';
        vehicleIds.build();
        _$failedField = 'recipients';
        recipients.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'GetSnapshot200ResponseAlarmsInner',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
