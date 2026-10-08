// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_person_devices200_response_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ListPersonDevices200ResponseInnerPlatformEnum
_$listPersonDevices200ResponseInnerPlatformEnum_android =
    const ListPersonDevices200ResponseInnerPlatformEnum._('android');
const ListPersonDevices200ResponseInnerPlatformEnum
_$listPersonDevices200ResponseInnerPlatformEnum_ios =
    const ListPersonDevices200ResponseInnerPlatformEnum._('ios');

ListPersonDevices200ResponseInnerPlatformEnum
_$listPersonDevices200ResponseInnerPlatformEnumValueOf(String name) {
  switch (name) {
    case 'android':
      return _$listPersonDevices200ResponseInnerPlatformEnum_android;
    case 'ios':
      return _$listPersonDevices200ResponseInnerPlatformEnum_ios;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ListPersonDevices200ResponseInnerPlatformEnum>
_$listPersonDevices200ResponseInnerPlatformEnumValues =
    BuiltSet<ListPersonDevices200ResponseInnerPlatformEnum>(
      const <ListPersonDevices200ResponseInnerPlatformEnum>[
        _$listPersonDevices200ResponseInnerPlatformEnum_android,
        _$listPersonDevices200ResponseInnerPlatformEnum_ios,
      ],
    );

Serializer<ListPersonDevices200ResponseInnerPlatformEnum>
_$listPersonDevices200ResponseInnerPlatformEnumSerializer =
    _$ListPersonDevices200ResponseInnerPlatformEnumSerializer();

class _$ListPersonDevices200ResponseInnerPlatformEnumSerializer
    implements
        PrimitiveSerializer<ListPersonDevices200ResponseInnerPlatformEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'android': 'android',
    'ios': 'ios',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'android': 'android',
    'ios': 'ios',
  };

  @override
  final Iterable<Type> types = const <Type>[
    ListPersonDevices200ResponseInnerPlatformEnum,
  ];
  @override
  final String wireName = 'ListPersonDevices200ResponseInnerPlatformEnum';

  @override
  Object serialize(
    Serializers serializers,
    ListPersonDevices200ResponseInnerPlatformEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ListPersonDevices200ResponseInnerPlatformEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ListPersonDevices200ResponseInnerPlatformEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ListPersonDevices200ResponseInner
    extends ListPersonDevices200ResponseInner {
  @override
  final String id;
  @override
  final ListPersonDevices200ResponseInnerPlatformEnum platform;
  @override
  final String? deviceName;
  @override
  final String appVersion;
  @override
  final String createdAt;
  @override
  final String lastSeenAt;
  @override
  final String? revokedAt;

  factory _$ListPersonDevices200ResponseInner([
    void Function(ListPersonDevices200ResponseInnerBuilder)? updates,
  ]) => (ListPersonDevices200ResponseInnerBuilder()..update(updates))._build();

  _$ListPersonDevices200ResponseInner._({
    required this.id,
    required this.platform,
    this.deviceName,
    required this.appVersion,
    required this.createdAt,
    required this.lastSeenAt,
    this.revokedAt,
  }) : super._();
  @override
  ListPersonDevices200ResponseInner rebuild(
    void Function(ListPersonDevices200ResponseInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ListPersonDevices200ResponseInnerBuilder toBuilder() =>
      ListPersonDevices200ResponseInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ListPersonDevices200ResponseInner &&
        id == other.id &&
        platform == other.platform &&
        deviceName == other.deviceName &&
        appVersion == other.appVersion &&
        createdAt == other.createdAt &&
        lastSeenAt == other.lastSeenAt &&
        revokedAt == other.revokedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, deviceName.hashCode);
    _$hash = $jc(_$hash, appVersion.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, lastSeenAt.hashCode);
    _$hash = $jc(_$hash, revokedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ListPersonDevices200ResponseInner')
          ..add('id', id)
          ..add('platform', platform)
          ..add('deviceName', deviceName)
          ..add('appVersion', appVersion)
          ..add('createdAt', createdAt)
          ..add('lastSeenAt', lastSeenAt)
          ..add('revokedAt', revokedAt))
        .toString();
  }
}

class ListPersonDevices200ResponseInnerBuilder
    implements
        Builder<
          ListPersonDevices200ResponseInner,
          ListPersonDevices200ResponseInnerBuilder
        > {
  _$ListPersonDevices200ResponseInner? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  ListPersonDevices200ResponseInnerPlatformEnum? _platform;
  ListPersonDevices200ResponseInnerPlatformEnum? get platform =>
      _$this._platform;
  set platform(ListPersonDevices200ResponseInnerPlatformEnum? platform) =>
      _$this._platform = platform;

  String? _deviceName;
  String? get deviceName => _$this._deviceName;
  set deviceName(String? deviceName) => _$this._deviceName = deviceName;

  String? _appVersion;
  String? get appVersion => _$this._appVersion;
  set appVersion(String? appVersion) => _$this._appVersion = appVersion;

  String? _createdAt;
  String? get createdAt => _$this._createdAt;
  set createdAt(String? createdAt) => _$this._createdAt = createdAt;

  String? _lastSeenAt;
  String? get lastSeenAt => _$this._lastSeenAt;
  set lastSeenAt(String? lastSeenAt) => _$this._lastSeenAt = lastSeenAt;

  String? _revokedAt;
  String? get revokedAt => _$this._revokedAt;
  set revokedAt(String? revokedAt) => _$this._revokedAt = revokedAt;

  ListPersonDevices200ResponseInnerBuilder() {
    ListPersonDevices200ResponseInner._defaults(this);
  }

  ListPersonDevices200ResponseInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _platform = $v.platform;
      _deviceName = $v.deviceName;
      _appVersion = $v.appVersion;
      _createdAt = $v.createdAt;
      _lastSeenAt = $v.lastSeenAt;
      _revokedAt = $v.revokedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ListPersonDevices200ResponseInner other) {
    _$v = other as _$ListPersonDevices200ResponseInner;
  }

  @override
  void update(
    void Function(ListPersonDevices200ResponseInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  ListPersonDevices200ResponseInner build() => _build();

  _$ListPersonDevices200ResponseInner _build() {
    final _$result =
        _$v ??
        _$ListPersonDevices200ResponseInner._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'ListPersonDevices200ResponseInner',
            'id',
          ),
          platform: BuiltValueNullFieldError.checkNotNull(
            platform,
            r'ListPersonDevices200ResponseInner',
            'platform',
          ),
          deviceName: deviceName,
          appVersion: BuiltValueNullFieldError.checkNotNull(
            appVersion,
            r'ListPersonDevices200ResponseInner',
            'appVersion',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'ListPersonDevices200ResponseInner',
            'createdAt',
          ),
          lastSeenAt: BuiltValueNullFieldError.checkNotNull(
            lastSeenAt,
            r'ListPersonDevices200ResponseInner',
            'lastSeenAt',
          ),
          revokedAt: revokedAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
