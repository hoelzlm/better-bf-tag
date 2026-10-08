// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_snapshot200_response_bf_day.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const GetSnapshot200ResponseBfDayStateEnum
_$getSnapshot200ResponseBfDayStateEnum_planning =
    const GetSnapshot200ResponseBfDayStateEnum._('planning');
const GetSnapshot200ResponseBfDayStateEnum
_$getSnapshot200ResponseBfDayStateEnum_running =
    const GetSnapshot200ResponseBfDayStateEnum._('running');
const GetSnapshot200ResponseBfDayStateEnum
_$getSnapshot200ResponseBfDayStateEnum_ended =
    const GetSnapshot200ResponseBfDayStateEnum._('ended');

GetSnapshot200ResponseBfDayStateEnum
_$getSnapshot200ResponseBfDayStateEnumValueOf(String name) {
  switch (name) {
    case 'planning':
      return _$getSnapshot200ResponseBfDayStateEnum_planning;
    case 'running':
      return _$getSnapshot200ResponseBfDayStateEnum_running;
    case 'ended':
      return _$getSnapshot200ResponseBfDayStateEnum_ended;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<GetSnapshot200ResponseBfDayStateEnum>
_$getSnapshot200ResponseBfDayStateEnumValues =
    BuiltSet<GetSnapshot200ResponseBfDayStateEnum>(
      const <GetSnapshot200ResponseBfDayStateEnum>[
        _$getSnapshot200ResponseBfDayStateEnum_planning,
        _$getSnapshot200ResponseBfDayStateEnum_running,
        _$getSnapshot200ResponseBfDayStateEnum_ended,
      ],
    );

Serializer<GetSnapshot200ResponseBfDayStateEnum>
_$getSnapshot200ResponseBfDayStateEnumSerializer =
    _$GetSnapshot200ResponseBfDayStateEnumSerializer();

class _$GetSnapshot200ResponseBfDayStateEnumSerializer
    implements PrimitiveSerializer<GetSnapshot200ResponseBfDayStateEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'planning': 'planning',
    'running': 'running',
    'ended': 'ended',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'planning': 'planning',
    'running': 'running',
    'ended': 'ended',
  };

  @override
  final Iterable<Type> types = const <Type>[
    GetSnapshot200ResponseBfDayStateEnum,
  ];
  @override
  final String wireName = 'GetSnapshot200ResponseBfDayStateEnum';

  @override
  Object serialize(
    Serializers serializers,
    GetSnapshot200ResponseBfDayStateEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  GetSnapshot200ResponseBfDayStateEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => GetSnapshot200ResponseBfDayStateEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$GetSnapshot200ResponseBfDay extends GetSnapshot200ResponseBfDay {
  @override
  final String id;
  @override
  final String name;
  @override
  final String startsAt;
  @override
  final String endsAt;
  @override
  final GetSnapshot200ResponseBfDayStateEnum state;
  @override
  final String? anonymizedAt;
  @override
  final String createdAt;

  factory _$GetSnapshot200ResponseBfDay([
    void Function(GetSnapshot200ResponseBfDayBuilder)? updates,
  ]) => (GetSnapshot200ResponseBfDayBuilder()..update(updates))._build();

  _$GetSnapshot200ResponseBfDay._({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.state,
    this.anonymizedAt,
    required this.createdAt,
  }) : super._();
  @override
  GetSnapshot200ResponseBfDay rebuild(
    void Function(GetSnapshot200ResponseBfDayBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetSnapshot200ResponseBfDayBuilder toBuilder() =>
      GetSnapshot200ResponseBfDayBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetSnapshot200ResponseBfDay &&
        id == other.id &&
        name == other.name &&
        startsAt == other.startsAt &&
        endsAt == other.endsAt &&
        state == other.state &&
        anonymizedAt == other.anonymizedAt &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, startsAt.hashCode);
    _$hash = $jc(_$hash, endsAt.hashCode);
    _$hash = $jc(_$hash, state.hashCode);
    _$hash = $jc(_$hash, anonymizedAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GetSnapshot200ResponseBfDay')
          ..add('id', id)
          ..add('name', name)
          ..add('startsAt', startsAt)
          ..add('endsAt', endsAt)
          ..add('state', state)
          ..add('anonymizedAt', anonymizedAt)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class GetSnapshot200ResponseBfDayBuilder
    implements
        Builder<
          GetSnapshot200ResponseBfDay,
          GetSnapshot200ResponseBfDayBuilder
        > {
  _$GetSnapshot200ResponseBfDay? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _startsAt;
  String? get startsAt => _$this._startsAt;
  set startsAt(String? startsAt) => _$this._startsAt = startsAt;

  String? _endsAt;
  String? get endsAt => _$this._endsAt;
  set endsAt(String? endsAt) => _$this._endsAt = endsAt;

  GetSnapshot200ResponseBfDayStateEnum? _state;
  GetSnapshot200ResponseBfDayStateEnum? get state => _$this._state;
  set state(GetSnapshot200ResponseBfDayStateEnum? state) =>
      _$this._state = state;

  String? _anonymizedAt;
  String? get anonymizedAt => _$this._anonymizedAt;
  set anonymizedAt(String? anonymizedAt) => _$this._anonymizedAt = anonymizedAt;

  String? _createdAt;
  String? get createdAt => _$this._createdAt;
  set createdAt(String? createdAt) => _$this._createdAt = createdAt;

  GetSnapshot200ResponseBfDayBuilder() {
    GetSnapshot200ResponseBfDay._defaults(this);
  }

  GetSnapshot200ResponseBfDayBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _startsAt = $v.startsAt;
      _endsAt = $v.endsAt;
      _state = $v.state;
      _anonymizedAt = $v.anonymizedAt;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetSnapshot200ResponseBfDay other) {
    _$v = other as _$GetSnapshot200ResponseBfDay;
  }

  @override
  void update(void Function(GetSnapshot200ResponseBfDayBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GetSnapshot200ResponseBfDay build() => _build();

  _$GetSnapshot200ResponseBfDay _build() {
    final _$result =
        _$v ??
        _$GetSnapshot200ResponseBfDay._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'GetSnapshot200ResponseBfDay',
            'id',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'GetSnapshot200ResponseBfDay',
            'name',
          ),
          startsAt: BuiltValueNullFieldError.checkNotNull(
            startsAt,
            r'GetSnapshot200ResponseBfDay',
            'startsAt',
          ),
          endsAt: BuiltValueNullFieldError.checkNotNull(
            endsAt,
            r'GetSnapshot200ResponseBfDay',
            'endsAt',
          ),
          state: BuiltValueNullFieldError.checkNotNull(
            state,
            r'GetSnapshot200ResponseBfDay',
            'state',
          ),
          anonymizedAt: anonymizedAt,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'GetSnapshot200ResponseBfDay',
            'createdAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
