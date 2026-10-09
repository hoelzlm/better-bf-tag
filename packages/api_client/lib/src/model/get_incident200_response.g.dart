// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_incident200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const GetIncident200ResponseStateEnum _$getIncident200ResponseStateEnum_draft =
    const GetIncident200ResponseStateEnum._('draft');
const GetIncident200ResponseStateEnum
_$getIncident200ResponseStateEnum_running =
    const GetIncident200ResponseStateEnum._('running');
const GetIncident200ResponseStateEnum _$getIncident200ResponseStateEnum_closed =
    const GetIncident200ResponseStateEnum._('closed');
const GetIncident200ResponseStateEnum
_$getIncident200ResponseStateEnum_discarded =
    const GetIncident200ResponseStateEnum._('discarded');

GetIncident200ResponseStateEnum _$getIncident200ResponseStateEnumValueOf(
  String name,
) {
  switch (name) {
    case 'draft':
      return _$getIncident200ResponseStateEnum_draft;
    case 'running':
      return _$getIncident200ResponseStateEnum_running;
    case 'closed':
      return _$getIncident200ResponseStateEnum_closed;
    case 'discarded':
      return _$getIncident200ResponseStateEnum_discarded;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<GetIncident200ResponseStateEnum>
_$getIncident200ResponseStateEnumValues =
    BuiltSet<GetIncident200ResponseStateEnum>(
      const <GetIncident200ResponseStateEnum>[
        _$getIncident200ResponseStateEnum_draft,
        _$getIncident200ResponseStateEnum_running,
        _$getIncident200ResponseStateEnum_closed,
        _$getIncident200ResponseStateEnum_discarded,
      ],
    );

Serializer<GetIncident200ResponseStateEnum>
_$getIncident200ResponseStateEnumSerializer =
    _$GetIncident200ResponseStateEnumSerializer();

class _$GetIncident200ResponseStateEnumSerializer
    implements PrimitiveSerializer<GetIncident200ResponseStateEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'draft': 'draft',
    'running': 'running',
    'closed': 'closed',
    'discarded': 'discarded',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'draft': 'draft',
    'running': 'running',
    'closed': 'closed',
    'discarded': 'discarded',
  };

  @override
  final Iterable<Type> types = const <Type>[GetIncident200ResponseStateEnum];
  @override
  final String wireName = 'GetIncident200ResponseStateEnum';

  @override
  Object serialize(
    Serializers serializers,
    GetIncident200ResponseStateEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  GetIncident200ResponseStateEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => GetIncident200ResponseStateEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$GetIncident200Response extends GetIncident200Response {
  @override
  final String id;
  @override
  final String bfDayId;
  @override
  final int number;
  @override
  final String keyword;
  @override
  final String address;
  @override
  final String report;
  @override
  final GetIncident200ResponseStateEnum state;
  @override
  final String createdAt;
  @override
  final String updatedAt;
  @override
  final String? closedAt;
  @override
  final String? script;
  @override
  final BuiltList<GetSnapshot200ResponseAlarmsInner> alarms;

  factory _$GetIncident200Response([
    void Function(GetIncident200ResponseBuilder)? updates,
  ]) => (GetIncident200ResponseBuilder()..update(updates))._build();

  _$GetIncident200Response._({
    required this.id,
    required this.bfDayId,
    required this.number,
    required this.keyword,
    required this.address,
    required this.report,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    this.script,
    required this.alarms,
  }) : super._();
  @override
  GetIncident200Response rebuild(
    void Function(GetIncident200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetIncident200ResponseBuilder toBuilder() =>
      GetIncident200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetIncident200Response &&
        id == other.id &&
        bfDayId == other.bfDayId &&
        number == other.number &&
        keyword == other.keyword &&
        address == other.address &&
        report == other.report &&
        state == other.state &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        closedAt == other.closedAt &&
        script == other.script &&
        alarms == other.alarms;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, bfDayId.hashCode);
    _$hash = $jc(_$hash, number.hashCode);
    _$hash = $jc(_$hash, keyword.hashCode);
    _$hash = $jc(_$hash, address.hashCode);
    _$hash = $jc(_$hash, report.hashCode);
    _$hash = $jc(_$hash, state.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, closedAt.hashCode);
    _$hash = $jc(_$hash, script.hashCode);
    _$hash = $jc(_$hash, alarms.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GetIncident200Response')
          ..add('id', id)
          ..add('bfDayId', bfDayId)
          ..add('number', number)
          ..add('keyword', keyword)
          ..add('address', address)
          ..add('report', report)
          ..add('state', state)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('closedAt', closedAt)
          ..add('script', script)
          ..add('alarms', alarms))
        .toString();
  }
}

class GetIncident200ResponseBuilder
    implements Builder<GetIncident200Response, GetIncident200ResponseBuilder> {
  _$GetIncident200Response? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _bfDayId;
  String? get bfDayId => _$this._bfDayId;
  set bfDayId(String? bfDayId) => _$this._bfDayId = bfDayId;

  int? _number;
  int? get number => _$this._number;
  set number(int? number) => _$this._number = number;

  String? _keyword;
  String? get keyword => _$this._keyword;
  set keyword(String? keyword) => _$this._keyword = keyword;

  String? _address;
  String? get address => _$this._address;
  set address(String? address) => _$this._address = address;

  String? _report;
  String? get report => _$this._report;
  set report(String? report) => _$this._report = report;

  GetIncident200ResponseStateEnum? _state;
  GetIncident200ResponseStateEnum? get state => _$this._state;
  set state(GetIncident200ResponseStateEnum? state) => _$this._state = state;

  String? _createdAt;
  String? get createdAt => _$this._createdAt;
  set createdAt(String? createdAt) => _$this._createdAt = createdAt;

  String? _updatedAt;
  String? get updatedAt => _$this._updatedAt;
  set updatedAt(String? updatedAt) => _$this._updatedAt = updatedAt;

  String? _closedAt;
  String? get closedAt => _$this._closedAt;
  set closedAt(String? closedAt) => _$this._closedAt = closedAt;

  String? _script;
  String? get script => _$this._script;
  set script(String? script) => _$this._script = script;

  ListBuilder<GetSnapshot200ResponseAlarmsInner>? _alarms;
  ListBuilder<GetSnapshot200ResponseAlarmsInner> get alarms =>
      _$this._alarms ??= ListBuilder<GetSnapshot200ResponseAlarmsInner>();
  set alarms(ListBuilder<GetSnapshot200ResponseAlarmsInner>? alarms) =>
      _$this._alarms = alarms;

  GetIncident200ResponseBuilder() {
    GetIncident200Response._defaults(this);
  }

  GetIncident200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _bfDayId = $v.bfDayId;
      _number = $v.number;
      _keyword = $v.keyword;
      _address = $v.address;
      _report = $v.report;
      _state = $v.state;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _closedAt = $v.closedAt;
      _script = $v.script;
      _alarms = $v.alarms.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetIncident200Response other) {
    _$v = other as _$GetIncident200Response;
  }

  @override
  void update(void Function(GetIncident200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GetIncident200Response build() => _build();

  _$GetIncident200Response _build() {
    _$GetIncident200Response _$result;
    try {
      _$result =
          _$v ??
          _$GetIncident200Response._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'GetIncident200Response',
              'id',
            ),
            bfDayId: BuiltValueNullFieldError.checkNotNull(
              bfDayId,
              r'GetIncident200Response',
              'bfDayId',
            ),
            number: BuiltValueNullFieldError.checkNotNull(
              number,
              r'GetIncident200Response',
              'number',
            ),
            keyword: BuiltValueNullFieldError.checkNotNull(
              keyword,
              r'GetIncident200Response',
              'keyword',
            ),
            address: BuiltValueNullFieldError.checkNotNull(
              address,
              r'GetIncident200Response',
              'address',
            ),
            report: BuiltValueNullFieldError.checkNotNull(
              report,
              r'GetIncident200Response',
              'report',
            ),
            state: BuiltValueNullFieldError.checkNotNull(
              state,
              r'GetIncident200Response',
              'state',
            ),
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'GetIncident200Response',
              'createdAt',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'GetIncident200Response',
              'updatedAt',
            ),
            closedAt: closedAt,
            script: script,
            alarms: alarms.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'alarms';
        alarms.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'GetIncident200Response',
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
