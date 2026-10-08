// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_bf_days200_response_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ListBfDays200ResponseInnerStateEnum
_$listBfDays200ResponseInnerStateEnum_planning =
    const ListBfDays200ResponseInnerStateEnum._('planning');
const ListBfDays200ResponseInnerStateEnum
_$listBfDays200ResponseInnerStateEnum_running =
    const ListBfDays200ResponseInnerStateEnum._('running');
const ListBfDays200ResponseInnerStateEnum
_$listBfDays200ResponseInnerStateEnum_ended =
    const ListBfDays200ResponseInnerStateEnum._('ended');

ListBfDays200ResponseInnerStateEnum
_$listBfDays200ResponseInnerStateEnumValueOf(String name) {
  switch (name) {
    case 'planning':
      return _$listBfDays200ResponseInnerStateEnum_planning;
    case 'running':
      return _$listBfDays200ResponseInnerStateEnum_running;
    case 'ended':
      return _$listBfDays200ResponseInnerStateEnum_ended;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ListBfDays200ResponseInnerStateEnum>
_$listBfDays200ResponseInnerStateEnumValues =
    BuiltSet<ListBfDays200ResponseInnerStateEnum>(
      const <ListBfDays200ResponseInnerStateEnum>[
        _$listBfDays200ResponseInnerStateEnum_planning,
        _$listBfDays200ResponseInnerStateEnum_running,
        _$listBfDays200ResponseInnerStateEnum_ended,
      ],
    );

Serializer<ListBfDays200ResponseInnerStateEnum>
_$listBfDays200ResponseInnerStateEnumSerializer =
    _$ListBfDays200ResponseInnerStateEnumSerializer();

class _$ListBfDays200ResponseInnerStateEnumSerializer
    implements PrimitiveSerializer<ListBfDays200ResponseInnerStateEnum> {
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
    ListBfDays200ResponseInnerStateEnum,
  ];
  @override
  final String wireName = 'ListBfDays200ResponseInnerStateEnum';

  @override
  Object serialize(
    Serializers serializers,
    ListBfDays200ResponseInnerStateEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ListBfDays200ResponseInnerStateEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ListBfDays200ResponseInnerStateEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ListBfDays200ResponseInner extends ListBfDays200ResponseInner {
  @override
  final String id;
  @override
  final String name;
  @override
  final String startsAt;
  @override
  final String endsAt;
  @override
  final ListBfDays200ResponseInnerStateEnum state;
  @override
  final String? anonymizedAt;
  @override
  final String createdAt;

  factory _$ListBfDays200ResponseInner([
    void Function(ListBfDays200ResponseInnerBuilder)? updates,
  ]) => (ListBfDays200ResponseInnerBuilder()..update(updates))._build();

  _$ListBfDays200ResponseInner._({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.state,
    this.anonymizedAt,
    required this.createdAt,
  }) : super._();
  @override
  ListBfDays200ResponseInner rebuild(
    void Function(ListBfDays200ResponseInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ListBfDays200ResponseInnerBuilder toBuilder() =>
      ListBfDays200ResponseInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ListBfDays200ResponseInner &&
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
    return (newBuiltValueToStringHelper(r'ListBfDays200ResponseInner')
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

class ListBfDays200ResponseInnerBuilder
    implements
        Builder<ListBfDays200ResponseInner, ListBfDays200ResponseInnerBuilder> {
  _$ListBfDays200ResponseInner? _$v;

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

  ListBfDays200ResponseInnerStateEnum? _state;
  ListBfDays200ResponseInnerStateEnum? get state => _$this._state;
  set state(ListBfDays200ResponseInnerStateEnum? state) =>
      _$this._state = state;

  String? _anonymizedAt;
  String? get anonymizedAt => _$this._anonymizedAt;
  set anonymizedAt(String? anonymizedAt) => _$this._anonymizedAt = anonymizedAt;

  String? _createdAt;
  String? get createdAt => _$this._createdAt;
  set createdAt(String? createdAt) => _$this._createdAt = createdAt;

  ListBfDays200ResponseInnerBuilder() {
    ListBfDays200ResponseInner._defaults(this);
  }

  ListBfDays200ResponseInnerBuilder get _$this {
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
  void replace(ListBfDays200ResponseInner other) {
    _$v = other as _$ListBfDays200ResponseInner;
  }

  @override
  void update(void Function(ListBfDays200ResponseInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ListBfDays200ResponseInner build() => _build();

  _$ListBfDays200ResponseInner _build() {
    final _$result =
        _$v ??
        _$ListBfDays200ResponseInner._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'ListBfDays200ResponseInner',
            'id',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'ListBfDays200ResponseInner',
            'name',
          ),
          startsAt: BuiltValueNullFieldError.checkNotNull(
            startsAt,
            r'ListBfDays200ResponseInner',
            'startsAt',
          ),
          endsAt: BuiltValueNullFieldError.checkNotNull(
            endsAt,
            r'ListBfDays200ResponseInner',
            'endsAt',
          ),
          state: BuiltValueNullFieldError.checkNotNull(
            state,
            r'ListBfDays200ResponseInner',
            'state',
          ),
          anonymizedAt: anonymizedAt,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'ListBfDays200ResponseInner',
            'createdAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
