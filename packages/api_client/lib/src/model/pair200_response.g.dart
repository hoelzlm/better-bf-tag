// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pair200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Pair200Response extends Pair200Response {
  @override
  final String accessToken;
  @override
  final String refreshToken;
  @override
  final num expiresIn;
  @override
  final String deviceId;
  @override
  final Login200ResponsePerson person;

  factory _$Pair200Response([void Function(Pair200ResponseBuilder)? updates]) =>
      (Pair200ResponseBuilder()..update(updates))._build();

  _$Pair200Response._({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.deviceId,
    required this.person,
  }) : super._();
  @override
  Pair200Response rebuild(void Function(Pair200ResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  Pair200ResponseBuilder toBuilder() => Pair200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Pair200Response &&
        accessToken == other.accessToken &&
        refreshToken == other.refreshToken &&
        expiresIn == other.expiresIn &&
        deviceId == other.deviceId &&
        person == other.person;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accessToken.hashCode);
    _$hash = $jc(_$hash, refreshToken.hashCode);
    _$hash = $jc(_$hash, expiresIn.hashCode);
    _$hash = $jc(_$hash, deviceId.hashCode);
    _$hash = $jc(_$hash, person.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Pair200Response')
          ..add('accessToken', accessToken)
          ..add('refreshToken', refreshToken)
          ..add('expiresIn', expiresIn)
          ..add('deviceId', deviceId)
          ..add('person', person))
        .toString();
  }
}

class Pair200ResponseBuilder
    implements Builder<Pair200Response, Pair200ResponseBuilder> {
  _$Pair200Response? _$v;

  String? _accessToken;
  String? get accessToken => _$this._accessToken;
  set accessToken(String? accessToken) => _$this._accessToken = accessToken;

  String? _refreshToken;
  String? get refreshToken => _$this._refreshToken;
  set refreshToken(String? refreshToken) => _$this._refreshToken = refreshToken;

  num? _expiresIn;
  num? get expiresIn => _$this._expiresIn;
  set expiresIn(num? expiresIn) => _$this._expiresIn = expiresIn;

  String? _deviceId;
  String? get deviceId => _$this._deviceId;
  set deviceId(String? deviceId) => _$this._deviceId = deviceId;

  Login200ResponsePersonBuilder? _person;
  Login200ResponsePersonBuilder get person =>
      _$this._person ??= Login200ResponsePersonBuilder();
  set person(Login200ResponsePersonBuilder? person) => _$this._person = person;

  Pair200ResponseBuilder() {
    Pair200Response._defaults(this);
  }

  Pair200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accessToken = $v.accessToken;
      _refreshToken = $v.refreshToken;
      _expiresIn = $v.expiresIn;
      _deviceId = $v.deviceId;
      _person = $v.person.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Pair200Response other) {
    _$v = other as _$Pair200Response;
  }

  @override
  void update(void Function(Pair200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Pair200Response build() => _build();

  _$Pair200Response _build() {
    _$Pair200Response _$result;
    try {
      _$result =
          _$v ??
          _$Pair200Response._(
            accessToken: BuiltValueNullFieldError.checkNotNull(
              accessToken,
              r'Pair200Response',
              'accessToken',
            ),
            refreshToken: BuiltValueNullFieldError.checkNotNull(
              refreshToken,
              r'Pair200Response',
              'refreshToken',
            ),
            expiresIn: BuiltValueNullFieldError.checkNotNull(
              expiresIn,
              r'Pair200Response',
              'expiresIn',
            ),
            deviceId: BuiltValueNullFieldError.checkNotNull(
              deviceId,
              r'Pair200Response',
              'deviceId',
            ),
            person: person.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'person';
        person.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'Pair200Response',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
