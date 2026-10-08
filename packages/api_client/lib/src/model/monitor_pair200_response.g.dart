// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monitor_pair200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MonitorPair200Response extends MonitorPair200Response {
  @override
  final String accessToken;
  @override
  final String refreshToken;
  @override
  final num expiresIn;
  @override
  final MonitorPair200ResponseMonitor monitor;

  factory _$MonitorPair200Response([
    void Function(MonitorPair200ResponseBuilder)? updates,
  ]) => (MonitorPair200ResponseBuilder()..update(updates))._build();

  _$MonitorPair200Response._({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.monitor,
  }) : super._();
  @override
  MonitorPair200Response rebuild(
    void Function(MonitorPair200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  MonitorPair200ResponseBuilder toBuilder() =>
      MonitorPair200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MonitorPair200Response &&
        accessToken == other.accessToken &&
        refreshToken == other.refreshToken &&
        expiresIn == other.expiresIn &&
        monitor == other.monitor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accessToken.hashCode);
    _$hash = $jc(_$hash, refreshToken.hashCode);
    _$hash = $jc(_$hash, expiresIn.hashCode);
    _$hash = $jc(_$hash, monitor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MonitorPair200Response')
          ..add('accessToken', accessToken)
          ..add('refreshToken', refreshToken)
          ..add('expiresIn', expiresIn)
          ..add('monitor', monitor))
        .toString();
  }
}

class MonitorPair200ResponseBuilder
    implements Builder<MonitorPair200Response, MonitorPair200ResponseBuilder> {
  _$MonitorPair200Response? _$v;

  String? _accessToken;
  String? get accessToken => _$this._accessToken;
  set accessToken(String? accessToken) => _$this._accessToken = accessToken;

  String? _refreshToken;
  String? get refreshToken => _$this._refreshToken;
  set refreshToken(String? refreshToken) => _$this._refreshToken = refreshToken;

  num? _expiresIn;
  num? get expiresIn => _$this._expiresIn;
  set expiresIn(num? expiresIn) => _$this._expiresIn = expiresIn;

  MonitorPair200ResponseMonitorBuilder? _monitor;
  MonitorPair200ResponseMonitorBuilder get monitor =>
      _$this._monitor ??= MonitorPair200ResponseMonitorBuilder();
  set monitor(MonitorPair200ResponseMonitorBuilder? monitor) =>
      _$this._monitor = monitor;

  MonitorPair200ResponseBuilder() {
    MonitorPair200Response._defaults(this);
  }

  MonitorPair200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accessToken = $v.accessToken;
      _refreshToken = $v.refreshToken;
      _expiresIn = $v.expiresIn;
      _monitor = $v.monitor.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MonitorPair200Response other) {
    _$v = other as _$MonitorPair200Response;
  }

  @override
  void update(void Function(MonitorPair200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MonitorPair200Response build() => _build();

  _$MonitorPair200Response _build() {
    _$MonitorPair200Response _$result;
    try {
      _$result =
          _$v ??
          _$MonitorPair200Response._(
            accessToken: BuiltValueNullFieldError.checkNotNull(
              accessToken,
              r'MonitorPair200Response',
              'accessToken',
            ),
            refreshToken: BuiltValueNullFieldError.checkNotNull(
              refreshToken,
              r'MonitorPair200Response',
              'refreshToken',
            ),
            expiresIn: BuiltValueNullFieldError.checkNotNull(
              expiresIn,
              r'MonitorPair200Response',
              'expiresIn',
            ),
            monitor: monitor.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'monitor';
        monitor.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'MonitorPair200Response',
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
