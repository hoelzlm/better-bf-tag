// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_persons200_response_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ListPersons200ResponseInnerPersonTypeEnum
_$listPersons200ResponseInnerPersonTypeEnum_youth =
    const ListPersons200ResponseInnerPersonTypeEnum._('youth');
const ListPersons200ResponseInnerPersonTypeEnum
_$listPersons200ResponseInnerPersonTypeEnum_supervisor =
    const ListPersons200ResponseInnerPersonTypeEnum._('supervisor');

ListPersons200ResponseInnerPersonTypeEnum
_$listPersons200ResponseInnerPersonTypeEnumValueOf(String name) {
  switch (name) {
    case 'youth':
      return _$listPersons200ResponseInnerPersonTypeEnum_youth;
    case 'supervisor':
      return _$listPersons200ResponseInnerPersonTypeEnum_supervisor;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ListPersons200ResponseInnerPersonTypeEnum>
_$listPersons200ResponseInnerPersonTypeEnumValues =
    BuiltSet<ListPersons200ResponseInnerPersonTypeEnum>(
      const <ListPersons200ResponseInnerPersonTypeEnum>[
        _$listPersons200ResponseInnerPersonTypeEnum_youth,
        _$listPersons200ResponseInnerPersonTypeEnum_supervisor,
      ],
    );

const ListPersons200ResponseInnerPermissionEnum
_$listPersons200ResponseInnerPermissionEnum_crew =
    const ListPersons200ResponseInnerPermissionEnum._('crew');
const ListPersons200ResponseInnerPermissionEnum
_$listPersons200ResponseInnerPermissionEnum_preparation =
    const ListPersons200ResponseInnerPermissionEnum._('preparation');
const ListPersons200ResponseInnerPermissionEnum
_$listPersons200ResponseInnerPermissionEnum_dispatch =
    const ListPersons200ResponseInnerPermissionEnum._('dispatch');
const ListPersons200ResponseInnerPermissionEnum
_$listPersons200ResponseInnerPermissionEnum_admin =
    const ListPersons200ResponseInnerPermissionEnum._('admin');

ListPersons200ResponseInnerPermissionEnum
_$listPersons200ResponseInnerPermissionEnumValueOf(String name) {
  switch (name) {
    case 'crew':
      return _$listPersons200ResponseInnerPermissionEnum_crew;
    case 'preparation':
      return _$listPersons200ResponseInnerPermissionEnum_preparation;
    case 'dispatch':
      return _$listPersons200ResponseInnerPermissionEnum_dispatch;
    case 'admin':
      return _$listPersons200ResponseInnerPermissionEnum_admin;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ListPersons200ResponseInnerPermissionEnum>
_$listPersons200ResponseInnerPermissionEnumValues =
    BuiltSet<ListPersons200ResponseInnerPermissionEnum>(
      const <ListPersons200ResponseInnerPermissionEnum>[
        _$listPersons200ResponseInnerPermissionEnum_crew,
        _$listPersons200ResponseInnerPermissionEnum_preparation,
        _$listPersons200ResponseInnerPermissionEnum_dispatch,
        _$listPersons200ResponseInnerPermissionEnum_admin,
      ],
    );

Serializer<ListPersons200ResponseInnerPersonTypeEnum>
_$listPersons200ResponseInnerPersonTypeEnumSerializer =
    _$ListPersons200ResponseInnerPersonTypeEnumSerializer();
Serializer<ListPersons200ResponseInnerPermissionEnum>
_$listPersons200ResponseInnerPermissionEnumSerializer =
    _$ListPersons200ResponseInnerPermissionEnumSerializer();

class _$ListPersons200ResponseInnerPersonTypeEnumSerializer
    implements PrimitiveSerializer<ListPersons200ResponseInnerPersonTypeEnum> {
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
    ListPersons200ResponseInnerPersonTypeEnum,
  ];
  @override
  final String wireName = 'ListPersons200ResponseInnerPersonTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    ListPersons200ResponseInnerPersonTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ListPersons200ResponseInnerPersonTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ListPersons200ResponseInnerPersonTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ListPersons200ResponseInnerPermissionEnumSerializer
    implements PrimitiveSerializer<ListPersons200ResponseInnerPermissionEnum> {
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
    ListPersons200ResponseInnerPermissionEnum,
  ];
  @override
  final String wireName = 'ListPersons200ResponseInnerPermissionEnum';

  @override
  Object serialize(
    Serializers serializers,
    ListPersons200ResponseInnerPermissionEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ListPersons200ResponseInnerPermissionEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ListPersons200ResponseInnerPermissionEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ListPersons200ResponseInner extends ListPersons200ResponseInner {
  @override
  final String id;
  @override
  final String displayName;
  @override
  final ListPersons200ResponseInnerPersonTypeEnum personType;
  @override
  final ListPersons200ResponseInnerPermissionEnum permission;
  @override
  final bool active;
  @override
  final bool hasWebAccess;
  @override
  final String? username;

  factory _$ListPersons200ResponseInner([
    void Function(ListPersons200ResponseInnerBuilder)? updates,
  ]) => (ListPersons200ResponseInnerBuilder()..update(updates))._build();

  _$ListPersons200ResponseInner._({
    required this.id,
    required this.displayName,
    required this.personType,
    required this.permission,
    required this.active,
    required this.hasWebAccess,
    this.username,
  }) : super._();
  @override
  ListPersons200ResponseInner rebuild(
    void Function(ListPersons200ResponseInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ListPersons200ResponseInnerBuilder toBuilder() =>
      ListPersons200ResponseInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ListPersons200ResponseInner &&
        id == other.id &&
        displayName == other.displayName &&
        personType == other.personType &&
        permission == other.permission &&
        active == other.active &&
        hasWebAccess == other.hasWebAccess &&
        username == other.username;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, personType.hashCode);
    _$hash = $jc(_$hash, permission.hashCode);
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jc(_$hash, hasWebAccess.hashCode);
    _$hash = $jc(_$hash, username.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ListPersons200ResponseInner')
          ..add('id', id)
          ..add('displayName', displayName)
          ..add('personType', personType)
          ..add('permission', permission)
          ..add('active', active)
          ..add('hasWebAccess', hasWebAccess)
          ..add('username', username))
        .toString();
  }
}

class ListPersons200ResponseInnerBuilder
    implements
        Builder<
          ListPersons200ResponseInner,
          ListPersons200ResponseInnerBuilder
        > {
  _$ListPersons200ResponseInner? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  ListPersons200ResponseInnerPersonTypeEnum? _personType;
  ListPersons200ResponseInnerPersonTypeEnum? get personType =>
      _$this._personType;
  set personType(ListPersons200ResponseInnerPersonTypeEnum? personType) =>
      _$this._personType = personType;

  ListPersons200ResponseInnerPermissionEnum? _permission;
  ListPersons200ResponseInnerPermissionEnum? get permission =>
      _$this._permission;
  set permission(ListPersons200ResponseInnerPermissionEnum? permission) =>
      _$this._permission = permission;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  bool? _hasWebAccess;
  bool? get hasWebAccess => _$this._hasWebAccess;
  set hasWebAccess(bool? hasWebAccess) => _$this._hasWebAccess = hasWebAccess;

  String? _username;
  String? get username => _$this._username;
  set username(String? username) => _$this._username = username;

  ListPersons200ResponseInnerBuilder() {
    ListPersons200ResponseInner._defaults(this);
  }

  ListPersons200ResponseInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _displayName = $v.displayName;
      _personType = $v.personType;
      _permission = $v.permission;
      _active = $v.active;
      _hasWebAccess = $v.hasWebAccess;
      _username = $v.username;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ListPersons200ResponseInner other) {
    _$v = other as _$ListPersons200ResponseInner;
  }

  @override
  void update(void Function(ListPersons200ResponseInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ListPersons200ResponseInner build() => _build();

  _$ListPersons200ResponseInner _build() {
    final _$result =
        _$v ??
        _$ListPersons200ResponseInner._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'ListPersons200ResponseInner',
            'id',
          ),
          displayName: BuiltValueNullFieldError.checkNotNull(
            displayName,
            r'ListPersons200ResponseInner',
            'displayName',
          ),
          personType: BuiltValueNullFieldError.checkNotNull(
            personType,
            r'ListPersons200ResponseInner',
            'personType',
          ),
          permission: BuiltValueNullFieldError.checkNotNull(
            permission,
            r'ListPersons200ResponseInner',
            'permission',
          ),
          active: BuiltValueNullFieldError.checkNotNull(
            active,
            r'ListPersons200ResponseInner',
            'active',
          ),
          hasWebAccess: BuiltValueNullFieldError.checkNotNull(
            hasWebAccess,
            r'ListPersons200ResponseInner',
            'hasWebAccess',
          ),
          username: username,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
