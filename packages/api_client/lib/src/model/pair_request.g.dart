// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pair_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PairRequestPlatformEnum _$pairRequestPlatformEnum_android =
    const PairRequestPlatformEnum._('android');
const PairRequestPlatformEnum _$pairRequestPlatformEnum_ios =
    const PairRequestPlatformEnum._('ios');

PairRequestPlatformEnum _$pairRequestPlatformEnumValueOf(String name) {
  switch (name) {
    case 'android':
      return _$pairRequestPlatformEnum_android;
    case 'ios':
      return _$pairRequestPlatformEnum_ios;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PairRequestPlatformEnum> _$pairRequestPlatformEnumValues =
    BuiltSet<PairRequestPlatformEnum>(const <PairRequestPlatformEnum>[
      _$pairRequestPlatformEnum_android,
      _$pairRequestPlatformEnum_ios,
    ]);

Serializer<PairRequestPlatformEnum> _$pairRequestPlatformEnumSerializer =
    _$PairRequestPlatformEnumSerializer();

class _$PairRequestPlatformEnumSerializer
    implements PrimitiveSerializer<PairRequestPlatformEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'android': 'android',
    'ios': 'ios',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'android': 'android',
    'ios': 'ios',
  };

  @override
  final Iterable<Type> types = const <Type>[PairRequestPlatformEnum];
  @override
  final String wireName = 'PairRequestPlatformEnum';

  @override
  Object serialize(
    Serializers serializers,
    PairRequestPlatformEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PairRequestPlatformEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PairRequestPlatformEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PairRequest extends PairRequest {
  @override
  final String code;
  @override
  final PairRequestPlatformEnum platform;
  @override
  final String appVersion;
  @override
  final String? deviceName;

  factory _$PairRequest([void Function(PairRequestBuilder)? updates]) =>
      (PairRequestBuilder()..update(updates))._build();

  _$PairRequest._({
    required this.code,
    required this.platform,
    required this.appVersion,
    this.deviceName,
  }) : super._();
  @override
  PairRequest rebuild(void Function(PairRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PairRequestBuilder toBuilder() => PairRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PairRequest &&
        code == other.code &&
        platform == other.platform &&
        appVersion == other.appVersion &&
        deviceName == other.deviceName;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, appVersion.hashCode);
    _$hash = $jc(_$hash, deviceName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PairRequest')
          ..add('code', code)
          ..add('platform', platform)
          ..add('appVersion', appVersion)
          ..add('deviceName', deviceName))
        .toString();
  }
}

class PairRequestBuilder implements Builder<PairRequest, PairRequestBuilder> {
  _$PairRequest? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  PairRequestPlatformEnum? _platform;
  PairRequestPlatformEnum? get platform => _$this._platform;
  set platform(PairRequestPlatformEnum? platform) =>
      _$this._platform = platform;

  String? _appVersion;
  String? get appVersion => _$this._appVersion;
  set appVersion(String? appVersion) => _$this._appVersion = appVersion;

  String? _deviceName;
  String? get deviceName => _$this._deviceName;
  set deviceName(String? deviceName) => _$this._deviceName = deviceName;

  PairRequestBuilder() {
    PairRequest._defaults(this);
  }

  PairRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _platform = $v.platform;
      _appVersion = $v.appVersion;
      _deviceName = $v.deviceName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PairRequest other) {
    _$v = other as _$PairRequest;
  }

  @override
  void update(void Function(PairRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PairRequest build() => _build();

  _$PairRequest _build() {
    final _$result =
        _$v ??
        _$PairRequest._(
          code: BuiltValueNullFieldError.checkNotNull(
            code,
            r'PairRequest',
            'code',
          ),
          platform: BuiltValueNullFieldError.checkNotNull(
            platform,
            r'PairRequest',
            'platform',
          ),
          appVersion: BuiltValueNullFieldError.checkNotNull(
            appVersion,
            r'PairRequest',
            'appVersion',
          ),
          deviceName: deviceName,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
