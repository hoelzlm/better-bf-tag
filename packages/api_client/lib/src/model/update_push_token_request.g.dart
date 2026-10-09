// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_push_token_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdatePushTokenRequest extends UpdatePushTokenRequest {
  @override
  final String token;

  factory _$UpdatePushTokenRequest([
    void Function(UpdatePushTokenRequestBuilder)? updates,
  ]) => (UpdatePushTokenRequestBuilder()..update(updates))._build();

  _$UpdatePushTokenRequest._({required this.token}) : super._();
  @override
  UpdatePushTokenRequest rebuild(
    void Function(UpdatePushTokenRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdatePushTokenRequestBuilder toBuilder() =>
      UpdatePushTokenRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdatePushTokenRequest && token == other.token;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, token.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'UpdatePushTokenRequest',
    )..add('token', token)).toString();
  }
}

class UpdatePushTokenRequestBuilder
    implements Builder<UpdatePushTokenRequest, UpdatePushTokenRequestBuilder> {
  _$UpdatePushTokenRequest? _$v;

  String? _token;
  String? get token => _$this._token;
  set token(String? token) => _$this._token = token;

  UpdatePushTokenRequestBuilder() {
    UpdatePushTokenRequest._defaults(this);
  }

  UpdatePushTokenRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _token = $v.token;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdatePushTokenRequest other) {
    _$v = other as _$UpdatePushTokenRequest;
  }

  @override
  void update(void Function(UpdatePushTokenRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdatePushTokenRequest build() => _build();

  _$UpdatePushTokenRequest _build() {
    final _$result =
        _$v ??
        _$UpdatePushTokenRequest._(
          token: BuiltValueNullFieldError.checkNotNull(
            token,
            r'UpdatePushTokenRequest',
            'token',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
