// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_snapshot200_response_program_items_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const GetSnapshot200ResponseProgramItemsInnerTypeEnum
_$getSnapshot200ResponseProgramItemsInnerTypeEnum_meal =
    const GetSnapshot200ResponseProgramItemsInnerTypeEnum._('meal');
const GetSnapshot200ResponseProgramItemsInnerTypeEnum
_$getSnapshot200ResponseProgramItemsInnerTypeEnum_training =
    const GetSnapshot200ResponseProgramItemsInnerTypeEnum._('training');
const GetSnapshot200ResponseProgramItemsInnerTypeEnum
_$getSnapshot200ResponseProgramItemsInnerTypeEnum_maintenance =
    const GetSnapshot200ResponseProgramItemsInnerTypeEnum._('maintenance');
const GetSnapshot200ResponseProgramItemsInnerTypeEnum
_$getSnapshot200ResponseProgramItemsInnerTypeEnum_rest =
    const GetSnapshot200ResponseProgramItemsInnerTypeEnum._('rest');
const GetSnapshot200ResponseProgramItemsInnerTypeEnum
_$getSnapshot200ResponseProgramItemsInnerTypeEnum_other =
    const GetSnapshot200ResponseProgramItemsInnerTypeEnum._('other');

GetSnapshot200ResponseProgramItemsInnerTypeEnum
_$getSnapshot200ResponseProgramItemsInnerTypeEnumValueOf(String name) {
  switch (name) {
    case 'meal':
      return _$getSnapshot200ResponseProgramItemsInnerTypeEnum_meal;
    case 'training':
      return _$getSnapshot200ResponseProgramItemsInnerTypeEnum_training;
    case 'maintenance':
      return _$getSnapshot200ResponseProgramItemsInnerTypeEnum_maintenance;
    case 'rest':
      return _$getSnapshot200ResponseProgramItemsInnerTypeEnum_rest;
    case 'other':
      return _$getSnapshot200ResponseProgramItemsInnerTypeEnum_other;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<GetSnapshot200ResponseProgramItemsInnerTypeEnum>
_$getSnapshot200ResponseProgramItemsInnerTypeEnumValues =
    BuiltSet<GetSnapshot200ResponseProgramItemsInnerTypeEnum>(
      const <GetSnapshot200ResponseProgramItemsInnerTypeEnum>[
        _$getSnapshot200ResponseProgramItemsInnerTypeEnum_meal,
        _$getSnapshot200ResponseProgramItemsInnerTypeEnum_training,
        _$getSnapshot200ResponseProgramItemsInnerTypeEnum_maintenance,
        _$getSnapshot200ResponseProgramItemsInnerTypeEnum_rest,
        _$getSnapshot200ResponseProgramItemsInnerTypeEnum_other,
      ],
    );

Serializer<GetSnapshot200ResponseProgramItemsInnerTypeEnum>
_$getSnapshot200ResponseProgramItemsInnerTypeEnumSerializer =
    _$GetSnapshot200ResponseProgramItemsInnerTypeEnumSerializer();

class _$GetSnapshot200ResponseProgramItemsInnerTypeEnumSerializer
    implements
        PrimitiveSerializer<GetSnapshot200ResponseProgramItemsInnerTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'meal': 'meal',
    'training': 'training',
    'maintenance': 'maintenance',
    'rest': 'rest',
    'other': 'other',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'meal': 'meal',
    'training': 'training',
    'maintenance': 'maintenance',
    'rest': 'rest',
    'other': 'other',
  };

  @override
  final Iterable<Type> types = const <Type>[
    GetSnapshot200ResponseProgramItemsInnerTypeEnum,
  ];
  @override
  final String wireName = 'GetSnapshot200ResponseProgramItemsInnerTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    GetSnapshot200ResponseProgramItemsInnerTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  GetSnapshot200ResponseProgramItemsInnerTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => GetSnapshot200ResponseProgramItemsInnerTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$GetSnapshot200ResponseProgramItemsInner
    extends GetSnapshot200ResponseProgramItemsInner {
  @override
  final String id;
  @override
  final String bfDayId;
  @override
  final String title;
  @override
  final GetSnapshot200ResponseProgramItemsInnerTypeEnum type;
  @override
  final String startsAt;
  @override
  final String endsAt;

  factory _$GetSnapshot200ResponseProgramItemsInner([
    void Function(GetSnapshot200ResponseProgramItemsInnerBuilder)? updates,
  ]) => (GetSnapshot200ResponseProgramItemsInnerBuilder()..update(updates))
      ._build();

  _$GetSnapshot200ResponseProgramItemsInner._({
    required this.id,
    required this.bfDayId,
    required this.title,
    required this.type,
    required this.startsAt,
    required this.endsAt,
  }) : super._();
  @override
  GetSnapshot200ResponseProgramItemsInner rebuild(
    void Function(GetSnapshot200ResponseProgramItemsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetSnapshot200ResponseProgramItemsInnerBuilder toBuilder() =>
      GetSnapshot200ResponseProgramItemsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetSnapshot200ResponseProgramItemsInner &&
        id == other.id &&
        bfDayId == other.bfDayId &&
        title == other.title &&
        type == other.type &&
        startsAt == other.startsAt &&
        endsAt == other.endsAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, bfDayId.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, startsAt.hashCode);
    _$hash = $jc(_$hash, endsAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'GetSnapshot200ResponseProgramItemsInner',
          )
          ..add('id', id)
          ..add('bfDayId', bfDayId)
          ..add('title', title)
          ..add('type', type)
          ..add('startsAt', startsAt)
          ..add('endsAt', endsAt))
        .toString();
  }
}

class GetSnapshot200ResponseProgramItemsInnerBuilder
    implements
        Builder<
          GetSnapshot200ResponseProgramItemsInner,
          GetSnapshot200ResponseProgramItemsInnerBuilder
        > {
  _$GetSnapshot200ResponseProgramItemsInner? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _bfDayId;
  String? get bfDayId => _$this._bfDayId;
  set bfDayId(String? bfDayId) => _$this._bfDayId = bfDayId;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  GetSnapshot200ResponseProgramItemsInnerTypeEnum? _type;
  GetSnapshot200ResponseProgramItemsInnerTypeEnum? get type => _$this._type;
  set type(GetSnapshot200ResponseProgramItemsInnerTypeEnum? type) =>
      _$this._type = type;

  String? _startsAt;
  String? get startsAt => _$this._startsAt;
  set startsAt(String? startsAt) => _$this._startsAt = startsAt;

  String? _endsAt;
  String? get endsAt => _$this._endsAt;
  set endsAt(String? endsAt) => _$this._endsAt = endsAt;

  GetSnapshot200ResponseProgramItemsInnerBuilder() {
    GetSnapshot200ResponseProgramItemsInner._defaults(this);
  }

  GetSnapshot200ResponseProgramItemsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _bfDayId = $v.bfDayId;
      _title = $v.title;
      _type = $v.type;
      _startsAt = $v.startsAt;
      _endsAt = $v.endsAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetSnapshot200ResponseProgramItemsInner other) {
    _$v = other as _$GetSnapshot200ResponseProgramItemsInner;
  }

  @override
  void update(
    void Function(GetSnapshot200ResponseProgramItemsInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  GetSnapshot200ResponseProgramItemsInner build() => _build();

  _$GetSnapshot200ResponseProgramItemsInner _build() {
    final _$result =
        _$v ??
        _$GetSnapshot200ResponseProgramItemsInner._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'GetSnapshot200ResponseProgramItemsInner',
            'id',
          ),
          bfDayId: BuiltValueNullFieldError.checkNotNull(
            bfDayId,
            r'GetSnapshot200ResponseProgramItemsInner',
            'bfDayId',
          ),
          title: BuiltValueNullFieldError.checkNotNull(
            title,
            r'GetSnapshot200ResponseProgramItemsInner',
            'title',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'GetSnapshot200ResponseProgramItemsInner',
            'type',
          ),
          startsAt: BuiltValueNullFieldError.checkNotNull(
            startsAt,
            r'GetSnapshot200ResponseProgramItemsInner',
            'startsAt',
          ),
          endsAt: BuiltValueNullFieldError.checkNotNull(
            endsAt,
            r'GetSnapshot200ResponseProgramItemsInner',
            'endsAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
