// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_web_access_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SetWebAccessRequest extends SetWebAccessRequest {
  @override
  final String username;
  @override
  final String password;

  factory _$SetWebAccessRequest([
    void Function(SetWebAccessRequestBuilder)? updates,
  ]) => (SetWebAccessRequestBuilder()..update(updates))._build();

  _$SetWebAccessRequest._({required this.username, required this.password})
    : super._();
  @override
  SetWebAccessRequest rebuild(
    void Function(SetWebAccessRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  SetWebAccessRequestBuilder toBuilder() =>
      SetWebAccessRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SetWebAccessRequest &&
        username == other.username &&
        password == other.password;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, username.hashCode);
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SetWebAccessRequest')
          ..add('username', username)
          ..add('password', password))
        .toString();
  }
}

class SetWebAccessRequestBuilder
    implements Builder<SetWebAccessRequest, SetWebAccessRequestBuilder> {
  _$SetWebAccessRequest? _$v;

  String? _username;
  String? get username => _$this._username;
  set username(String? username) => _$this._username = username;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  SetWebAccessRequestBuilder() {
    SetWebAccessRequest._defaults(this);
  }

  SetWebAccessRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _username = $v.username;
      _password = $v.password;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SetWebAccessRequest other) {
    _$v = other as _$SetWebAccessRequest;
  }

  @override
  void update(void Function(SetWebAccessRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SetWebAccessRequest build() => _build();

  _$SetWebAccessRequest _build() {
    final _$result =
        _$v ??
        _$SetWebAccessRequest._(
          username: BuiltValueNullFieldError.checkNotNull(
            username,
            r'SetWebAccessRequest',
            'username',
          ),
          password: BuiltValueNullFieldError.checkNotNull(
            password,
            r'SetWebAccessRequest',
            'password',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
