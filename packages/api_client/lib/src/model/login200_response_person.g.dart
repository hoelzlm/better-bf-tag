// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login200_response_person.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const Login200ResponsePersonPersonTypeEnum
_$login200ResponsePersonPersonTypeEnum_youth =
    const Login200ResponsePersonPersonTypeEnum._('youth');
const Login200ResponsePersonPersonTypeEnum
_$login200ResponsePersonPersonTypeEnum_supervisor =
    const Login200ResponsePersonPersonTypeEnum._('supervisor');

Login200ResponsePersonPersonTypeEnum
_$login200ResponsePersonPersonTypeEnumValueOf(String name) {
  switch (name) {
    case 'youth':
      return _$login200ResponsePersonPersonTypeEnum_youth;
    case 'supervisor':
      return _$login200ResponsePersonPersonTypeEnum_supervisor;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<Login200ResponsePersonPersonTypeEnum>
_$login200ResponsePersonPersonTypeEnumValues =
    BuiltSet<Login200ResponsePersonPersonTypeEnum>(
      const <Login200ResponsePersonPersonTypeEnum>[
        _$login200ResponsePersonPersonTypeEnum_youth,
        _$login200ResponsePersonPersonTypeEnum_supervisor,
      ],
    );

const Login200ResponsePersonPermissionEnum
_$login200ResponsePersonPermissionEnum_crew =
    const Login200ResponsePersonPermissionEnum._('crew');
const Login200ResponsePersonPermissionEnum
_$login200ResponsePersonPermissionEnum_preparation =
    const Login200ResponsePersonPermissionEnum._('preparation');
const Login200ResponsePersonPermissionEnum
_$login200ResponsePersonPermissionEnum_dispatch =
    const Login200ResponsePersonPermissionEnum._('dispatch');
const Login200ResponsePersonPermissionEnum
_$login200ResponsePersonPermissionEnum_admin =
    const Login200ResponsePersonPermissionEnum._('admin');

Login200ResponsePersonPermissionEnum
_$login200ResponsePersonPermissionEnumValueOf(String name) {
  switch (name) {
    case 'crew':
      return _$login200ResponsePersonPermissionEnum_crew;
    case 'preparation':
      return _$login200ResponsePersonPermissionEnum_preparation;
    case 'dispatch':
      return _$login200ResponsePersonPermissionEnum_dispatch;
    case 'admin':
      return _$login200ResponsePersonPermissionEnum_admin;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<Login200ResponsePersonPermissionEnum>
_$login200ResponsePersonPermissionEnumValues =
    BuiltSet<Login200ResponsePersonPermissionEnum>(
      const <Login200ResponsePersonPermissionEnum>[
        _$login200ResponsePersonPermissionEnum_crew,
        _$login200ResponsePersonPermissionEnum_preparation,
        _$login200ResponsePersonPermissionEnum_dispatch,
        _$login200ResponsePersonPermissionEnum_admin,
      ],
    );

Serializer<Login200ResponsePersonPersonTypeEnum>
_$login200ResponsePersonPersonTypeEnumSerializer =
    _$Login200ResponsePersonPersonTypeEnumSerializer();
Serializer<Login200ResponsePersonPermissionEnum>
_$login200ResponsePersonPermissionEnumSerializer =
    _$Login200ResponsePersonPermissionEnumSerializer();

class _$Login200ResponsePersonPersonTypeEnumSerializer
    implements PrimitiveSerializer<Login200ResponsePersonPersonTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'youth': 'youth',
    'supervisor': 'supervisor',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'youth': 'youth',
    'supervisor': 'supervisor',
  };

  @override
  final Iterable<Type> types = const <Type>[
    Login200ResponsePersonPersonTypeEnum,
  ];
  @override
  final String wireName = 'Login200ResponsePersonPersonTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    Login200ResponsePersonPersonTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  Login200ResponsePersonPersonTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => Login200ResponsePersonPersonTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$Login200ResponsePersonPermissionEnumSerializer
    implements PrimitiveSerializer<Login200ResponsePersonPermissionEnum> {
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
  final Iterable<Type> types = const <Type>[
    Login200ResponsePersonPermissionEnum,
  ];
  @override
  final String wireName = 'Login200ResponsePersonPermissionEnum';

  @override
  Object serialize(
    Serializers serializers,
    Login200ResponsePersonPermissionEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  Login200ResponsePersonPermissionEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => Login200ResponsePersonPermissionEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$Login200ResponsePerson extends Login200ResponsePerson {
  @override
  final String id;
  @override
  final String displayName;
  @override
  final Login200ResponsePersonPersonTypeEnum personType;
  @override
  final Login200ResponsePersonPermissionEnum permission;

  factory _$Login200ResponsePerson([
    void Function(Login200ResponsePersonBuilder)? updates,
  ]) => (Login200ResponsePersonBuilder()..update(updates))._build();

  _$Login200ResponsePerson._({
    required this.id,
    required this.displayName,
    required this.personType,
    required this.permission,
  }) : super._();
  @override
  Login200ResponsePerson rebuild(
    void Function(Login200ResponsePersonBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  Login200ResponsePersonBuilder toBuilder() =>
      Login200ResponsePersonBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Login200ResponsePerson &&
        id == other.id &&
        displayName == other.displayName &&
        personType == other.personType &&
        permission == other.permission;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, personType.hashCode);
    _$hash = $jc(_$hash, permission.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Login200ResponsePerson')
          ..add('id', id)
          ..add('displayName', displayName)
          ..add('personType', personType)
          ..add('permission', permission))
        .toString();
  }
}

class Login200ResponsePersonBuilder
    implements Builder<Login200ResponsePerson, Login200ResponsePersonBuilder> {
  _$Login200ResponsePerson? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  Login200ResponsePersonPersonTypeEnum? _personType;
  Login200ResponsePersonPersonTypeEnum? get personType => _$this._personType;
  set personType(Login200ResponsePersonPersonTypeEnum? personType) =>
      _$this._personType = personType;

  Login200ResponsePersonPermissionEnum? _permission;
  Login200ResponsePersonPermissionEnum? get permission => _$this._permission;
  set permission(Login200ResponsePersonPermissionEnum? permission) =>
      _$this._permission = permission;

  Login200ResponsePersonBuilder() {
    Login200ResponsePerson._defaults(this);
  }

  Login200ResponsePersonBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _displayName = $v.displayName;
      _personType = $v.personType;
      _permission = $v.permission;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Login200ResponsePerson other) {
    _$v = other as _$Login200ResponsePerson;
  }

  @override
  void update(void Function(Login200ResponsePersonBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Login200ResponsePerson build() => _build();

  _$Login200ResponsePerson _build() {
    final _$result =
        _$v ??
        _$Login200ResponsePerson._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'Login200ResponsePerson',
            'id',
          ),
          displayName: BuiltValueNullFieldError.checkNotNull(
            displayName,
            r'Login200ResponsePerson',
            'displayName',
          ),
          personType: BuiltValueNullFieldError.checkNotNull(
            personType,
            r'Login200ResponsePerson',
            'personType',
          ),
          permission: BuiltValueNullFieldError.checkNotNull(
            permission,
            r'Login200ResponsePerson',
            'permission',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
