// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login401_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Login401Response extends Login401Response {
  @override
  final Login401ResponseError error;

  factory _$Login401Response([
    void Function(Login401ResponseBuilder)? updates,
  ]) => (Login401ResponseBuilder()..update(updates))._build();

  _$Login401Response._({required this.error}) : super._();
  @override
  Login401Response rebuild(void Function(Login401ResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  Login401ResponseBuilder toBuilder() =>
      Login401ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Login401Response && error == other.error;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, error.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'Login401Response',
    )..add('error', error)).toString();
  }
}

class Login401ResponseBuilder
    implements Builder<Login401Response, Login401ResponseBuilder> {
  _$Login401Response? _$v;

  Login401ResponseErrorBuilder? _error;
  Login401ResponseErrorBuilder get error =>
      _$this._error ??= Login401ResponseErrorBuilder();
  set error(Login401ResponseErrorBuilder? error) => _$this._error = error;

  Login401ResponseBuilder() {
    Login401Response._defaults(this);
  }

  Login401ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _error = $v.error.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Login401Response other) {
    _$v = other as _$Login401Response;
  }

  @override
  void update(void Function(Login401ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Login401Response build() => _build();

  _$Login401Response _build() {
    _$Login401Response _$result;
    try {
      _$result = _$v ?? _$Login401Response._(error: error.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'error';
        error.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'Login401Response',
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
