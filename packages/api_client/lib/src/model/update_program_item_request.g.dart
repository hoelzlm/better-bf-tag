// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_program_item_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateProgramItemRequestTypeEnum _$updateProgramItemRequestTypeEnum_meal =
    const UpdateProgramItemRequestTypeEnum._('meal');
const UpdateProgramItemRequestTypeEnum
_$updateProgramItemRequestTypeEnum_training =
    const UpdateProgramItemRequestTypeEnum._('training');
const UpdateProgramItemRequestTypeEnum
_$updateProgramItemRequestTypeEnum_maintenance =
    const UpdateProgramItemRequestTypeEnum._('maintenance');
const UpdateProgramItemRequestTypeEnum _$updateProgramItemRequestTypeEnum_rest =
    const UpdateProgramItemRequestTypeEnum._('rest');
const UpdateProgramItemRequestTypeEnum
_$updateProgramItemRequestTypeEnum_other =
    const UpdateProgramItemRequestTypeEnum._('other');

UpdateProgramItemRequestTypeEnum _$updateProgramItemRequestTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'meal':
      return _$updateProgramItemRequestTypeEnum_meal;
    case 'training':
      return _$updateProgramItemRequestTypeEnum_training;
    case 'maintenance':
      return _$updateProgramItemRequestTypeEnum_maintenance;
    case 'rest':
      return _$updateProgramItemRequestTypeEnum_rest;
    case 'other':
      return _$updateProgramItemRequestTypeEnum_other;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateProgramItemRequestTypeEnum>
_$updateProgramItemRequestTypeEnumValues =
    BuiltSet<UpdateProgramItemRequestTypeEnum>(
      const <UpdateProgramItemRequestTypeEnum>[
        _$updateProgramItemRequestTypeEnum_meal,
        _$updateProgramItemRequestTypeEnum_training,
        _$updateProgramItemRequestTypeEnum_maintenance,
        _$updateProgramItemRequestTypeEnum_rest,
        _$updateProgramItemRequestTypeEnum_other,
      ],
    );

Serializer<UpdateProgramItemRequestTypeEnum>
_$updateProgramItemRequestTypeEnumSerializer =
    _$UpdateProgramItemRequestTypeEnumSerializer();

class _$UpdateProgramItemRequestTypeEnumSerializer
    implements PrimitiveSerializer<UpdateProgramItemRequestTypeEnum> {
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
  final Iterable<Type> types = const <Type>[UpdateProgramItemRequestTypeEnum];
  @override
  final String wireName = 'UpdateProgramItemRequestTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateProgramItemRequestTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateProgramItemRequestTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateProgramItemRequestTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateProgramItemRequest extends UpdateProgramItemRequest {
  @override
  final String? title;
  @override
  final UpdateProgramItemRequestTypeEnum? type;
  @override
  final DateTime? startsAt;
  @override
  final DateTime? endsAt;

  factory _$UpdateProgramItemRequest([
    void Function(UpdateProgramItemRequestBuilder)? updates,
  ]) => (UpdateProgramItemRequestBuilder()..update(updates))._build();

  _$UpdateProgramItemRequest._({
    this.title,
    this.type,
    this.startsAt,
    this.endsAt,
  }) : super._();
  @override
  UpdateProgramItemRequest rebuild(
    void Function(UpdateProgramItemRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateProgramItemRequestBuilder toBuilder() =>
      UpdateProgramItemRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateProgramItemRequest &&
        title == other.title &&
        type == other.type &&
        startsAt == other.startsAt &&
        endsAt == other.endsAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, startsAt.hashCode);
    _$hash = $jc(_$hash, endsAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateProgramItemRequest')
          ..add('title', title)
          ..add('type', type)
          ..add('startsAt', startsAt)
          ..add('endsAt', endsAt))
        .toString();
  }
}

class UpdateProgramItemRequestBuilder
    implements
        Builder<UpdateProgramItemRequest, UpdateProgramItemRequestBuilder> {
  _$UpdateProgramItemRequest? _$v;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  UpdateProgramItemRequestTypeEnum? _type;
  UpdateProgramItemRequestTypeEnum? get type => _$this._type;
  set type(UpdateProgramItemRequestTypeEnum? type) => _$this._type = type;

  DateTime? _startsAt;
  DateTime? get startsAt => _$this._startsAt;
  set startsAt(DateTime? startsAt) => _$this._startsAt = startsAt;

  DateTime? _endsAt;
  DateTime? get endsAt => _$this._endsAt;
  set endsAt(DateTime? endsAt) => _$this._endsAt = endsAt;

  UpdateProgramItemRequestBuilder() {
    UpdateProgramItemRequest._defaults(this);
  }

  UpdateProgramItemRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _type = $v.type;
      _startsAt = $v.startsAt;
      _endsAt = $v.endsAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateProgramItemRequest other) {
    _$v = other as _$UpdateProgramItemRequest;
  }

  @override
  void update(void Function(UpdateProgramItemRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateProgramItemRequest build() => _build();

  _$UpdateProgramItemRequest _build() {
    final _$result =
        _$v ??
        _$UpdateProgramItemRequest._(
          title: title,
          type: type,
          startsAt: startsAt,
          endsAt: endsAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
