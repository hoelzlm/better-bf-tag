// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_refresh_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeviceRefreshRequest extends DeviceRefreshRequest {
  @override
  final String refreshToken;

  factory _$DeviceRefreshRequest([
    void Function(DeviceRefreshRequestBuilder)? updates,
  ]) => (DeviceRefreshRequestBuilder()..update(updates))._build();

  _$DeviceRefreshRequest._({required this.refreshToken}) : super._();
  @override
  DeviceRefreshRequest rebuild(
    void Function(DeviceRefreshRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DeviceRefreshRequestBuilder toBuilder() =>
      DeviceRefreshRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeviceRefreshRequest && refreshToken == other.refreshToken;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, refreshToken.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'DeviceRefreshRequest',
    )..add('refreshToken', refreshToken)).toString();
  }
}

class DeviceRefreshRequestBuilder
    implements Builder<DeviceRefreshRequest, DeviceRefreshRequestBuilder> {
  _$DeviceRefreshRequest? _$v;

  String? _refreshToken;
  String? get refreshToken => _$this._refreshToken;
  set refreshToken(String? refreshToken) => _$this._refreshToken = refreshToken;

  DeviceRefreshRequestBuilder() {
    DeviceRefreshRequest._defaults(this);
  }

  DeviceRefreshRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _refreshToken = $v.refreshToken;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeviceRefreshRequest other) {
    _$v = other as _$DeviceRefreshRequest;
  }

  @override
  void update(void Function(DeviceRefreshRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeviceRefreshRequest build() => _build();

  _$DeviceRefreshRequest _build() {
    final _$result =
        _$v ??
        _$DeviceRefreshRequest._(
          refreshToken: BuiltValueNullFieldError.checkNotNull(
            refreshToken,
            r'DeviceRefreshRequest',
            'refreshToken',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
