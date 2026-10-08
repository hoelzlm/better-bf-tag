// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login401_response_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Login401ResponseError extends Login401ResponseError {
  @override
  final String code;
  @override
  final String message;

  factory _$Login401ResponseError([
    void Function(Login401ResponseErrorBuilder)? updates,
  ]) => (Login401ResponseErrorBuilder()..update(updates))._build();

  _$Login401ResponseError._({required this.code, required this.message})
    : super._();
  @override
  Login401ResponseError rebuild(
    void Function(Login401ResponseErrorBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  Login401ResponseErrorBuilder toBuilder() =>
      Login401ResponseErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Login401ResponseError &&
        code == other.code &&
        message == other.message;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Login401ResponseError')
          ..add('code', code)
          ..add('message', message))
        .toString();
  }
}

class Login401ResponseErrorBuilder
    implements Builder<Login401ResponseError, Login401ResponseErrorBuilder> {
  _$Login401ResponseError? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  Login401ResponseErrorBuilder() {
    Login401ResponseError._defaults(this);
  }

  Login401ResponseErrorBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Login401ResponseError other) {
    _$v = other as _$Login401ResponseError;
  }

  @override
  void update(void Function(Login401ResponseErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Login401ResponseError build() => _build();

  _$Login401ResponseError _build() {
    final _$result =
        _$v ??
        _$Login401ResponseError._(
          code: BuiltValueNullFieldError.checkNotNull(
            code,
            r'Login401ResponseError',
            'code',
          ),
          message: BuiltValueNullFieldError.checkNotNull(
            message,
            r'Login401ResponseError',
            'message',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
