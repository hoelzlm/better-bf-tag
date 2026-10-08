// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_person_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdatePersonRequestPersonTypeEnum
_$updatePersonRequestPersonTypeEnum_youth =
    const UpdatePersonRequestPersonTypeEnum._('youth');
const UpdatePersonRequestPersonTypeEnum
_$updatePersonRequestPersonTypeEnum_supervisor =
    const UpdatePersonRequestPersonTypeEnum._('supervisor');

UpdatePersonRequestPersonTypeEnum _$updatePersonRequestPersonTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'youth':
      return _$updatePersonRequestPersonTypeEnum_youth;
    case 'supervisor':
      return _$updatePersonRequestPersonTypeEnum_supervisor;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdatePersonRequestPersonTypeEnum>
_$updatePersonRequestPersonTypeEnumValues =
    BuiltSet<UpdatePersonRequestPersonTypeEnum>(
      const <UpdatePersonRequestPersonTypeEnum>[
        _$updatePersonRequestPersonTypeEnum_youth,
        _$updatePersonRequestPersonTypeEnum_supervisor,
      ],
    );

const UpdatePersonRequestPermissionEnum
_$updatePersonRequestPermissionEnum_crew =
    const UpdatePersonRequestPermissionEnum._('crew');
const UpdatePersonRequestPermissionEnum
_$updatePersonRequestPermissionEnum_preparation =
    const UpdatePersonRequestPermissionEnum._('preparation');
const UpdatePersonRequestPermissionEnum
_$updatePersonRequestPermissionEnum_dispatch =
    const UpdatePersonRequestPermissionEnum._('dispatch');
const UpdatePersonRequestPermissionEnum
_$updatePersonRequestPermissionEnum_admin =
    const UpdatePersonRequestPermissionEnum._('admin');

UpdatePersonRequestPermissionEnum _$updatePersonRequestPermissionEnumValueOf(
  String name,
) {
  switch (name) {
    case 'crew':
      return _$updatePersonRequestPermissionEnum_crew;
    case 'preparation':
      return _$updatePersonRequestPermissionEnum_preparation;
    case 'dispatch':
      return _$updatePersonRequestPermissionEnum_dispatch;
    case 'admin':
      return _$updatePersonRequestPermissionEnum_admin;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdatePersonRequestPermissionEnum>
_$updatePersonRequestPermissionEnumValues =
    BuiltSet<UpdatePersonRequestPermissionEnum>(
      const <UpdatePersonRequestPermissionEnum>[
        _$updatePersonRequestPermissionEnum_crew,
        _$updatePersonRequestPermissionEnum_preparation,
        _$updatePersonRequestPermissionEnum_dispatch,
        _$updatePersonRequestPermissionEnum_admin,
      ],
    );

Serializer<UpdatePersonRequestPersonTypeEnum>
_$updatePersonRequestPersonTypeEnumSerializer =
    _$UpdatePersonRequestPersonTypeEnumSerializer();
Serializer<UpdatePersonRequestPermissionEnum>
_$updatePersonRequestPermissionEnumSerializer =
    _$UpdatePersonRequestPermissionEnumSerializer();

class _$UpdatePersonRequestPersonTypeEnumSerializer
    implements PrimitiveSerializer<UpdatePersonRequestPersonTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'youth': 'youth',
    'supervisor': 'supervisor',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'youth': 'youth',
    'supervisor': 'supervisor',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdatePersonRequestPersonTypeEnum];
  @override
  final String wireName = 'UpdatePersonRequestPersonTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdatePersonRequestPersonTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdatePersonRequestPersonTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdatePersonRequestPersonTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdatePersonRequestPermissionEnumSerializer
    implements PrimitiveSerializer<UpdatePersonRequestPermissionEnum> {
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
  final Iterable<Type> types = const <Type>[UpdatePersonRequestPermissionEnum];
  @override
  final String wireName = 'UpdatePersonRequestPermissionEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdatePersonRequestPermissionEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdatePersonRequestPermissionEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdatePersonRequestPermissionEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdatePersonRequest extends UpdatePersonRequest {
  @override
  final String? displayName;
  @override
  final UpdatePersonRequestPersonTypeEnum? personType;
  @override
  final UpdatePersonRequestPermissionEnum? permission;
  @override
  final bool? active;

  factory _$UpdatePersonRequest([
    void Function(UpdatePersonRequestBuilder)? updates,
  ]) => (UpdatePersonRequestBuilder()..update(updates))._build();

  _$UpdatePersonRequest._({
    this.displayName,
    this.personType,
    this.permission,
    this.active,
  }) : super._();
  @override
  UpdatePersonRequest rebuild(
    void Function(UpdatePersonRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdatePersonRequestBuilder toBuilder() =>
      UpdatePersonRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdatePersonRequest &&
        displayName == other.displayName &&
        personType == other.personType &&
        permission == other.permission &&
        active == other.active;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, personType.hashCode);
    _$hash = $jc(_$hash, permission.hashCode);
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdatePersonRequest')
          ..add('displayName', displayName)
          ..add('personType', personType)
          ..add('permission', permission)
          ..add('active', active))
        .toString();
  }
}

class UpdatePersonRequestBuilder
    implements Builder<UpdatePersonRequest, UpdatePersonRequestBuilder> {
  _$UpdatePersonRequest? _$v;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  UpdatePersonRequestPersonTypeEnum? _personType;
  UpdatePersonRequestPersonTypeEnum? get personType => _$this._personType;
  set personType(UpdatePersonRequestPersonTypeEnum? personType) =>
      _$this._personType = personType;

  UpdatePersonRequestPermissionEnum? _permission;
  UpdatePersonRequestPermissionEnum? get permission => _$this._permission;
  set permission(UpdatePersonRequestPermissionEnum? permission) =>
      _$this._permission = permission;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  UpdatePersonRequestBuilder() {
    UpdatePersonRequest._defaults(this);
  }

  UpdatePersonRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _displayName = $v.displayName;
      _personType = $v.personType;
      _permission = $v.permission;
      _active = $v.active;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdatePersonRequest other) {
    _$v = other as _$UpdatePersonRequest;
  }

  @override
  void update(void Function(UpdatePersonRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdatePersonRequest build() => _build();

  _$UpdatePersonRequest _build() {
    final _$result =
        _$v ??
        _$UpdatePersonRequest._(
          displayName: displayName,
          personType: personType,
          permission: permission,
          active: active,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
