// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_participants200_response_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ListParticipants200ResponseInnerPersonTypeEnum
_$listParticipants200ResponseInnerPersonTypeEnum_youth =
    const ListParticipants200ResponseInnerPersonTypeEnum._('youth');
const ListParticipants200ResponseInnerPersonTypeEnum
_$listParticipants200ResponseInnerPersonTypeEnum_supervisor =
    const ListParticipants200ResponseInnerPersonTypeEnum._('supervisor');

ListParticipants200ResponseInnerPersonTypeEnum
_$listParticipants200ResponseInnerPersonTypeEnumValueOf(String name) {
  switch (name) {
    case 'youth':
      return _$listParticipants200ResponseInnerPersonTypeEnum_youth;
    case 'supervisor':
      return _$listParticipants200ResponseInnerPersonTypeEnum_supervisor;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ListParticipants200ResponseInnerPersonTypeEnum>
_$listParticipants200ResponseInnerPersonTypeEnumValues =
    BuiltSet<ListParticipants200ResponseInnerPersonTypeEnum>(
      const <ListParticipants200ResponseInnerPersonTypeEnum>[
        _$listParticipants200ResponseInnerPersonTypeEnum_youth,
        _$listParticipants200ResponseInnerPersonTypeEnum_supervisor,
      ],
    );

const ListParticipants200ResponseInnerPermissionEnum
_$listParticipants200ResponseInnerPermissionEnum_crew =
    const ListParticipants200ResponseInnerPermissionEnum._('crew');
const ListParticipants200ResponseInnerPermissionEnum
_$listParticipants200ResponseInnerPermissionEnum_preparation =
    const ListParticipants200ResponseInnerPermissionEnum._('preparation');
const ListParticipants200ResponseInnerPermissionEnum
_$listParticipants200ResponseInnerPermissionEnum_dispatch =
    const ListParticipants200ResponseInnerPermissionEnum._('dispatch');
const ListParticipants200ResponseInnerPermissionEnum
_$listParticipants200ResponseInnerPermissionEnum_admin =
    const ListParticipants200ResponseInnerPermissionEnum._('admin');

ListParticipants200ResponseInnerPermissionEnum
_$listParticipants200ResponseInnerPermissionEnumValueOf(String name) {
  switch (name) {
    case 'crew':
      return _$listParticipants200ResponseInnerPermissionEnum_crew;
    case 'preparation':
      return _$listParticipants200ResponseInnerPermissionEnum_preparation;
    case 'dispatch':
      return _$listParticipants200ResponseInnerPermissionEnum_dispatch;
    case 'admin':
      return _$listParticipants200ResponseInnerPermissionEnum_admin;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ListParticipants200ResponseInnerPermissionEnum>
_$listParticipants200ResponseInnerPermissionEnumValues =
    BuiltSet<ListParticipants200ResponseInnerPermissionEnum>(
      const <ListParticipants200ResponseInnerPermissionEnum>[
        _$listParticipants200ResponseInnerPermissionEnum_crew,
        _$listParticipants200ResponseInnerPermissionEnum_preparation,
        _$listParticipants200ResponseInnerPermissionEnum_dispatch,
        _$listParticipants200ResponseInnerPermissionEnum_admin,
      ],
    );

Serializer<ListParticipants200ResponseInnerPersonTypeEnum>
_$listParticipants200ResponseInnerPersonTypeEnumSerializer =
    _$ListParticipants200ResponseInnerPersonTypeEnumSerializer();
Serializer<ListParticipants200ResponseInnerPermissionEnum>
_$listParticipants200ResponseInnerPermissionEnumSerializer =
    _$ListParticipants200ResponseInnerPermissionEnumSerializer();

class _$ListParticipants200ResponseInnerPersonTypeEnumSerializer
    implements
        PrimitiveSerializer<ListParticipants200ResponseInnerPersonTypeEnum> {
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
    ListParticipants200ResponseInnerPersonTypeEnum,
  ];
  @override
  final String wireName = 'ListParticipants200ResponseInnerPersonTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    ListParticipants200ResponseInnerPersonTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ListParticipants200ResponseInnerPersonTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ListParticipants200ResponseInnerPersonTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ListParticipants200ResponseInnerPermissionEnumSerializer
    implements
        PrimitiveSerializer<ListParticipants200ResponseInnerPermissionEnum> {
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
    ListParticipants200ResponseInnerPermissionEnum,
  ];
  @override
  final String wireName = 'ListParticipants200ResponseInnerPermissionEnum';

  @override
  Object serialize(
    Serializers serializers,
    ListParticipants200ResponseInnerPermissionEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ListParticipants200ResponseInnerPermissionEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ListParticipants200ResponseInnerPermissionEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ListParticipants200ResponseInner
    extends ListParticipants200ResponseInner {
  @override
  final String personId;
  @override
  final String displayName;
  @override
  final ListParticipants200ResponseInnerPersonTypeEnum personType;
  @override
  final ListParticipants200ResponseInnerPermissionEnum permission;
  @override
  final String fireDepartmentId;

  factory _$ListParticipants200ResponseInner([
    void Function(ListParticipants200ResponseInnerBuilder)? updates,
  ]) => (ListParticipants200ResponseInnerBuilder()..update(updates))._build();

  _$ListParticipants200ResponseInner._({
    required this.personId,
    required this.displayName,
    required this.personType,
    required this.permission,
    required this.fireDepartmentId,
  }) : super._();
  @override
  ListParticipants200ResponseInner rebuild(
    void Function(ListParticipants200ResponseInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ListParticipants200ResponseInnerBuilder toBuilder() =>
      ListParticipants200ResponseInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ListParticipants200ResponseInner &&
        personId == other.personId &&
        displayName == other.displayName &&
        personType == other.personType &&
        permission == other.permission &&
        fireDepartmentId == other.fireDepartmentId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, personType.hashCode);
    _$hash = $jc(_$hash, permission.hashCode);
    _$hash = $jc(_$hash, fireDepartmentId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ListParticipants200ResponseInner')
          ..add('personId', personId)
          ..add('displayName', displayName)
          ..add('personType', personType)
          ..add('permission', permission)
          ..add('fireDepartmentId', fireDepartmentId))
        .toString();
  }
}

class ListParticipants200ResponseInnerBuilder
    implements
        Builder<
          ListParticipants200ResponseInner,
          ListParticipants200ResponseInnerBuilder
        > {
  _$ListParticipants200ResponseInner? _$v;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(String? personId) => _$this._personId = personId;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  ListParticipants200ResponseInnerPersonTypeEnum? _personType;
  ListParticipants200ResponseInnerPersonTypeEnum? get personType =>
      _$this._personType;
  set personType(ListParticipants200ResponseInnerPersonTypeEnum? personType) =>
      _$this._personType = personType;

  ListParticipants200ResponseInnerPermissionEnum? _permission;
  ListParticipants200ResponseInnerPermissionEnum? get permission =>
      _$this._permission;
  set permission(ListParticipants200ResponseInnerPermissionEnum? permission) =>
      _$this._permission = permission;

  String? _fireDepartmentId;
  String? get fireDepartmentId => _$this._fireDepartmentId;
  set fireDepartmentId(String? fireDepartmentId) =>
      _$this._fireDepartmentId = fireDepartmentId;

  ListParticipants200ResponseInnerBuilder() {
    ListParticipants200ResponseInner._defaults(this);
  }

  ListParticipants200ResponseInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _personId = $v.personId;
      _displayName = $v.displayName;
      _personType = $v.personType;
      _permission = $v.permission;
      _fireDepartmentId = $v.fireDepartmentId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ListParticipants200ResponseInner other) {
    _$v = other as _$ListParticipants200ResponseInner;
  }

  @override
  void update(void Function(ListParticipants200ResponseInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ListParticipants200ResponseInner build() => _build();

  _$ListParticipants200ResponseInner _build() {
    final _$result =
        _$v ??
        _$ListParticipants200ResponseInner._(
          personId: BuiltValueNullFieldError.checkNotNull(
            personId,
            r'ListParticipants200ResponseInner',
            'personId',
          ),
          displayName: BuiltValueNullFieldError.checkNotNull(
            displayName,
            r'ListParticipants200ResponseInner',
            'displayName',
          ),
          personType: BuiltValueNullFieldError.checkNotNull(
            personType,
            r'ListParticipants200ResponseInner',
            'personType',
          ),
          permission: BuiltValueNullFieldError.checkNotNull(
            permission,
            r'ListParticipants200ResponseInner',
            'permission',
          ),
          fireDepartmentId: BuiltValueNullFieldError.checkNotNull(
            fireDepartmentId,
            r'ListParticipants200ResponseInner',
            'fireDepartmentId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
