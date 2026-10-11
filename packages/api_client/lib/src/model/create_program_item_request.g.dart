// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_program_item_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CreateProgramItemRequestTypeEnum _$createProgramItemRequestTypeEnum_meal =
    const CreateProgramItemRequestTypeEnum._('meal');
const CreateProgramItemRequestTypeEnum
_$createProgramItemRequestTypeEnum_training =
    const CreateProgramItemRequestTypeEnum._('training');
const CreateProgramItemRequestTypeEnum
_$createProgramItemRequestTypeEnum_maintenance =
    const CreateProgramItemRequestTypeEnum._('maintenance');
const CreateProgramItemRequestTypeEnum _$createProgramItemRequestTypeEnum_rest =
    const CreateProgramItemRequestTypeEnum._('rest');
const CreateProgramItemRequestTypeEnum
_$createProgramItemRequestTypeEnum_other =
    const CreateProgramItemRequestTypeEnum._('other');

CreateProgramItemRequestTypeEnum _$createProgramItemRequestTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'meal':
      return _$createProgramItemRequestTypeEnum_meal;
    case 'training':
      return _$createProgramItemRequestTypeEnum_training;
    case 'maintenance':
      return _$createProgramItemRequestTypeEnum_maintenance;
    case 'rest':
      return _$createProgramItemRequestTypeEnum_rest;
    case 'other':
      return _$createProgramItemRequestTypeEnum_other;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreateProgramItemRequestTypeEnum>
_$createProgramItemRequestTypeEnumValues =
    BuiltSet<CreateProgramItemRequestTypeEnum>(
      const <CreateProgramItemRequestTypeEnum>[
        _$createProgramItemRequestTypeEnum_meal,
        _$createProgramItemRequestTypeEnum_training,
        _$createProgramItemRequestTypeEnum_maintenance,
        _$createProgramItemRequestTypeEnum_rest,
        _$createProgramItemRequestTypeEnum_other,
      ],
    );

Serializer<CreateProgramItemRequestTypeEnum>
_$createProgramItemRequestTypeEnumSerializer =
    _$CreateProgramItemRequestTypeEnumSerializer();

class _$CreateProgramItemRequestTypeEnumSerializer
    implements PrimitiveSerializer<CreateProgramItemRequestTypeEnum> {
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
  final Iterable<Type> types = const <Type>[CreateProgramItemRequestTypeEnum];
  @override
  final String wireName = 'CreateProgramItemRequestTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    CreateProgramItemRequestTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreateProgramItemRequestTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreateProgramItemRequestTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreateProgramItemRequest extends CreateProgramItemRequest {
  @override
  final String title;
  @override
  final CreateProgramItemRequestTypeEnum type;
  @override
  final DateTime startsAt;
  @override
  final DateTime endsAt;

  factory _$CreateProgramItemRequest([
    void Function(CreateProgramItemRequestBuilder)? updates,
  ]) => (CreateProgramItemRequestBuilder()..update(updates))._build();

  _$CreateProgramItemRequest._({
    required this.title,
    required this.type,
    required this.startsAt,
    required this.endsAt,
  }) : super._();
  @override
  CreateProgramItemRequest rebuild(
    void Function(CreateProgramItemRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateProgramItemRequestBuilder toBuilder() =>
      CreateProgramItemRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateProgramItemRequest &&
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
    return (newBuiltValueToStringHelper(r'CreateProgramItemRequest')
          ..add('title', title)
          ..add('type', type)
          ..add('startsAt', startsAt)
          ..add('endsAt', endsAt))
        .toString();
  }
}

class CreateProgramItemRequestBuilder
    implements
        Builder<CreateProgramItemRequest, CreateProgramItemRequestBuilder> {
  _$CreateProgramItemRequest? _$v;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  CreateProgramItemRequestTypeEnum? _type;
  CreateProgramItemRequestTypeEnum? get type => _$this._type;
  set type(CreateProgramItemRequestTypeEnum? type) => _$this._type = type;

  DateTime? _startsAt;
  DateTime? get startsAt => _$this._startsAt;
  set startsAt(DateTime? startsAt) => _$this._startsAt = startsAt;

  DateTime? _endsAt;
  DateTime? get endsAt => _$this._endsAt;
  set endsAt(DateTime? endsAt) => _$this._endsAt = endsAt;

  CreateProgramItemRequestBuilder() {
    CreateProgramItemRequest._defaults(this);
  }

  CreateProgramItemRequestBuilder get _$this {
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
  void replace(CreateProgramItemRequest other) {
    _$v = other as _$CreateProgramItemRequest;
  }

  @override
  void update(void Function(CreateProgramItemRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateProgramItemRequest build() => _build();

  _$CreateProgramItemRequest _build() {
    final _$result =
        _$v ??
        _$CreateProgramItemRequest._(
          title: BuiltValueNullFieldError.checkNotNull(
            title,
            r'CreateProgramItemRequest',
            'title',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'CreateProgramItemRequest',
            'type',
          ),
          startsAt: BuiltValueNullFieldError.checkNotNull(
            startsAt,
            r'CreateProgramItemRequest',
            'startsAt',
          ),
          endsAt: BuiltValueNullFieldError.checkNotNull(
            endsAt,
            r'CreateProgramItemRequest',
            'endsAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
