// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_snapshot200_response_incidents_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const GetSnapshot200ResponseIncidentsInnerStateEnum
_$getSnapshot200ResponseIncidentsInnerStateEnum_draft =
    const GetSnapshot200ResponseIncidentsInnerStateEnum._('draft');
const GetSnapshot200ResponseIncidentsInnerStateEnum
_$getSnapshot200ResponseIncidentsInnerStateEnum_running =
    const GetSnapshot200ResponseIncidentsInnerStateEnum._('running');
const GetSnapshot200ResponseIncidentsInnerStateEnum
_$getSnapshot200ResponseIncidentsInnerStateEnum_closed =
    const GetSnapshot200ResponseIncidentsInnerStateEnum._('closed');
const GetSnapshot200ResponseIncidentsInnerStateEnum
_$getSnapshot200ResponseIncidentsInnerStateEnum_discarded =
    const GetSnapshot200ResponseIncidentsInnerStateEnum._('discarded');

GetSnapshot200ResponseIncidentsInnerStateEnum
_$getSnapshot200ResponseIncidentsInnerStateEnumValueOf(String name) {
  switch (name) {
    case 'draft':
      return _$getSnapshot200ResponseIncidentsInnerStateEnum_draft;
    case 'running':
      return _$getSnapshot200ResponseIncidentsInnerStateEnum_running;
    case 'closed':
      return _$getSnapshot200ResponseIncidentsInnerStateEnum_closed;
    case 'discarded':
      return _$getSnapshot200ResponseIncidentsInnerStateEnum_discarded;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<GetSnapshot200ResponseIncidentsInnerStateEnum>
_$getSnapshot200ResponseIncidentsInnerStateEnumValues =
    BuiltSet<GetSnapshot200ResponseIncidentsInnerStateEnum>(
      const <GetSnapshot200ResponseIncidentsInnerStateEnum>[
        _$getSnapshot200ResponseIncidentsInnerStateEnum_draft,
        _$getSnapshot200ResponseIncidentsInnerStateEnum_running,
        _$getSnapshot200ResponseIncidentsInnerStateEnum_closed,
        _$getSnapshot200ResponseIncidentsInnerStateEnum_discarded,
      ],
    );

Serializer<GetSnapshot200ResponseIncidentsInnerStateEnum>
_$getSnapshot200ResponseIncidentsInnerStateEnumSerializer =
    _$GetSnapshot200ResponseIncidentsInnerStateEnumSerializer();

class _$GetSnapshot200ResponseIncidentsInnerStateEnumSerializer
    implements
        PrimitiveSerializer<GetSnapshot200ResponseIncidentsInnerStateEnum> {
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
  final Iterable<Type> types = const <Type>[
    GetSnapshot200ResponseIncidentsInnerStateEnum,
  ];
  @override
  final String wireName = 'GetSnapshot200ResponseIncidentsInnerStateEnum';

  @override
  Object serialize(
    Serializers serializers,
    GetSnapshot200ResponseIncidentsInnerStateEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  GetSnapshot200ResponseIncidentsInnerStateEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => GetSnapshot200ResponseIncidentsInnerStateEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$GetSnapshot200ResponseIncidentsInner
    extends GetSnapshot200ResponseIncidentsInner {
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
  final GetSnapshot200ResponseIncidentsInnerStateEnum state;
  @override
  final String createdAt;
  @override
  final String updatedAt;
  @override
  final String? closedAt;
  @override
  final String? script;

  factory _$GetSnapshot200ResponseIncidentsInner([
    void Function(GetSnapshot200ResponseIncidentsInnerBuilder)? updates,
  ]) =>
      (GetSnapshot200ResponseIncidentsInnerBuilder()..update(updates))._build();

  _$GetSnapshot200ResponseIncidentsInner._({
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
  }) : super._();
  @override
  GetSnapshot200ResponseIncidentsInner rebuild(
    void Function(GetSnapshot200ResponseIncidentsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetSnapshot200ResponseIncidentsInnerBuilder toBuilder() =>
      GetSnapshot200ResponseIncidentsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetSnapshot200ResponseIncidentsInner &&
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
        script == other.script;
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
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GetSnapshot200ResponseIncidentsInner')
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
          ..add('script', script))
        .toString();
  }
}

class GetSnapshot200ResponseIncidentsInnerBuilder
    implements
        Builder<
          GetSnapshot200ResponseIncidentsInner,
          GetSnapshot200ResponseIncidentsInnerBuilder
        > {
  _$GetSnapshot200ResponseIncidentsInner? _$v;

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

  GetSnapshot200ResponseIncidentsInnerStateEnum? _state;
  GetSnapshot200ResponseIncidentsInnerStateEnum? get state => _$this._state;
  set state(GetSnapshot200ResponseIncidentsInnerStateEnum? state) =>
      _$this._state = state;

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

  GetSnapshot200ResponseIncidentsInnerBuilder() {
    GetSnapshot200ResponseIncidentsInner._defaults(this);
  }

  GetSnapshot200ResponseIncidentsInnerBuilder get _$this {
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
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetSnapshot200ResponseIncidentsInner other) {
    _$v = other as _$GetSnapshot200ResponseIncidentsInner;
  }

  @override
  void update(
    void Function(GetSnapshot200ResponseIncidentsInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  GetSnapshot200ResponseIncidentsInner build() => _build();

  _$GetSnapshot200ResponseIncidentsInner _build() {
    final _$result =
        _$v ??
        _$GetSnapshot200ResponseIncidentsInner._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'GetSnapshot200ResponseIncidentsInner',
            'id',
          ),
          bfDayId: BuiltValueNullFieldError.checkNotNull(
            bfDayId,
            r'GetSnapshot200ResponseIncidentsInner',
            'bfDayId',
          ),
          number: BuiltValueNullFieldError.checkNotNull(
            number,
            r'GetSnapshot200ResponseIncidentsInner',
            'number',
          ),
          keyword: BuiltValueNullFieldError.checkNotNull(
            keyword,
            r'GetSnapshot200ResponseIncidentsInner',
            'keyword',
          ),
          address: BuiltValueNullFieldError.checkNotNull(
            address,
            r'GetSnapshot200ResponseIncidentsInner',
            'address',
          ),
          report: BuiltValueNullFieldError.checkNotNull(
            report,
            r'GetSnapshot200ResponseIncidentsInner',
            'report',
          ),
          state: BuiltValueNullFieldError.checkNotNull(
            state,
            r'GetSnapshot200ResponseIncidentsInner',
            'state',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'GetSnapshot200ResponseIncidentsInner',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'GetSnapshot200ResponseIncidentsInner',
            'updatedAt',
          ),
          closedAt: closedAt,
          script: script,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
