// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_person_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CreatePersonRequestPersonTypeEnum
_$createPersonRequestPersonTypeEnum_youth =
    const CreatePersonRequestPersonTypeEnum._('youth');
const CreatePersonRequestPersonTypeEnum
_$createPersonRequestPersonTypeEnum_supervisor =
    const CreatePersonRequestPersonTypeEnum._('supervisor');

CreatePersonRequestPersonTypeEnum _$createPersonRequestPersonTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'youth':
      return _$createPersonRequestPersonTypeEnum_youth;
    case 'supervisor':
      return _$createPersonRequestPersonTypeEnum_supervisor;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreatePersonRequestPersonTypeEnum>
_$createPersonRequestPersonTypeEnumValues =
    BuiltSet<CreatePersonRequestPersonTypeEnum>(
      const <CreatePersonRequestPersonTypeEnum>[
        _$createPersonRequestPersonTypeEnum_youth,
        _$createPersonRequestPersonTypeEnum_supervisor,
      ],
    );

const CreatePersonRequestPermissionEnum
_$createPersonRequestPermissionEnum_crew =
    const CreatePersonRequestPermissionEnum._('crew');
const CreatePersonRequestPermissionEnum
_$createPersonRequestPermissionEnum_preparation =
    const CreatePersonRequestPermissionEnum._('preparation');
const CreatePersonRequestPermissionEnum
_$createPersonRequestPermissionEnum_dispatch =
    const CreatePersonRequestPermissionEnum._('dispatch');
const CreatePersonRequestPermissionEnum
_$createPersonRequestPermissionEnum_admin =
    const CreatePersonRequestPermissionEnum._('admin');

CreatePersonRequestPermissionEnum _$createPersonRequestPermissionEnumValueOf(
  String name,
) {
  switch (name) {
    case 'crew':
      return _$createPersonRequestPermissionEnum_crew;
    case 'preparation':
      return _$createPersonRequestPermissionEnum_preparation;
    case 'dispatch':
      return _$createPersonRequestPermissionEnum_dispatch;
    case 'admin':
      return _$createPersonRequestPermissionEnum_admin;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreatePersonRequestPermissionEnum>
_$createPersonRequestPermissionEnumValues =
    BuiltSet<CreatePersonRequestPermissionEnum>(
      const <CreatePersonRequestPermissionEnum>[
        _$createPersonRequestPermissionEnum_crew,
        _$createPersonRequestPermissionEnum_preparation,
        _$createPersonRequestPermissionEnum_dispatch,
        _$createPersonRequestPermissionEnum_admin,
      ],
    );

Serializer<CreatePersonRequestPersonTypeEnum>
_$createPersonRequestPersonTypeEnumSerializer =
    _$CreatePersonRequestPersonTypeEnumSerializer();
Serializer<CreatePersonRequestPermissionEnum>
_$createPersonRequestPermissionEnumSerializer =
    _$CreatePersonRequestPermissionEnumSerializer();

class _$CreatePersonRequestPersonTypeEnumSerializer
    implements PrimitiveSerializer<CreatePersonRequestPersonTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'youth': 'youth',
    'supervisor': 'supervisor',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'youth': 'youth',
    'supervisor': 'supervisor',
  };

  @override
  final Iterable<Type> types = const <Type>[CreatePersonRequestPersonTypeEnum];
  @override
  final String wireName = 'CreatePersonRequestPersonTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    CreatePersonRequestPersonTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreatePersonRequestPersonTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreatePersonRequestPersonTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreatePersonRequestPermissionEnumSerializer
    implements PrimitiveSerializer<CreatePersonRequestPermissionEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'crew': 'crew',
    'preparation': 'preparation',
    'dispatch': 'dispatch',
    'admin': 'admin',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'crew': 'crew',
    'preparation': 'preparation',
    'dispatch': 'dispatch',
    'admin': 'admin',
  };

  @override
  final Iterable<Type> types = const <Type>[CreatePersonRequestPermissionEnum];
  @override
  final String wireName = 'CreatePersonRequestPermissionEnum';

  @override
  Object serialize(
    Serializers serializers,
    CreatePersonRequestPermissionEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreatePersonRequestPermissionEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreatePersonRequestPermissionEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreatePersonRequest extends CreatePersonRequest {
  @override
  final String displayName;
  @override
  final CreatePersonRequestPersonTypeEnum personType;
  @override
  final CreatePersonRequestPermissionEnum permission;

  factory _$CreatePersonRequest([
    void Function(CreatePersonRequestBuilder)? updates,
  ]) => (CreatePersonRequestBuilder()..update(updates))._build();

  _$CreatePersonRequest._({
    required this.displayName,
    required this.personType,
    required this.permission,
  }) : super._();
  @override
  CreatePersonRequest rebuild(
    void Function(CreatePersonRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreatePersonRequestBuilder toBuilder() =>
      CreatePersonRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreatePersonRequest &&
        displayName == other.displayName &&
        personType == other.personType &&
        permission == other.permission;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, personType.hashCode);
    _$hash = $jc(_$hash, permission.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreatePersonRequest')
          ..add('displayName', displayName)
          ..add('personType', personType)
          ..add('permission', permission))
        .toString();
  }
}

class CreatePersonRequestBuilder
    implements Builder<CreatePersonRequest, CreatePersonRequestBuilder> {
  _$CreatePersonRequest? _$v;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  CreatePersonRequestPersonTypeEnum? _personType;
  CreatePersonRequestPersonTypeEnum? get personType => _$this._personType;
  set personType(CreatePersonRequestPersonTypeEnum? personType) =>
      _$this._personType = personType;

  CreatePersonRequestPermissionEnum? _permission;
  CreatePersonRequestPermissionEnum? get permission => _$this._permission;
  set permission(CreatePersonRequestPermissionEnum? permission) =>
      _$this._permission = permission;

  CreatePersonRequestBuilder() {
    CreatePersonRequest._defaults(this);
  }

  CreatePersonRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _displayName = $v.displayName;
      _personType = $v.personType;
      _permission = $v.permission;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreatePersonRequest other) {
    _$v = other as _$CreatePersonRequest;
  }

  @override
  void update(void Function(CreatePersonRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreatePersonRequest build() => _build();

  _$CreatePersonRequest _build() {
    final _$result =
        _$v ??
        _$CreatePersonRequest._(
          displayName: BuiltValueNullFieldError.checkNotNull(
            displayName,
            r'CreatePersonRequest',
            'displayName',
          ),
          personType: BuiltValueNullFieldError.checkNotNull(
            personType,
            r'CreatePersonRequest',
            'personType',
          ),
          permission: BuiltValueNullFieldError.checkNotNull(
            permission,
            r'CreatePersonRequest',
            'permission',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
