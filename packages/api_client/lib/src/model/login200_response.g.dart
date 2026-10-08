// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Login200Response extends Login200Response {
  @override
  final String accessToken;
  @override
  final num expiresIn;
  @override
  final Login200ResponsePerson person;

  factory _$Login200Response([
    void Function(Login200ResponseBuilder)? updates,
  ]) => (Login200ResponseBuilder()..update(updates))._build();

  _$Login200Response._({
    required this.accessToken,
    required this.expiresIn,
    required this.person,
  }) : super._();
  @override
  Login200Response rebuild(void Function(Login200ResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  Login200ResponseBuilder toBuilder() =>
      Login200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Login200Response &&
        accessToken == other.accessToken &&
        expiresIn == other.expiresIn &&
        person == other.person;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accessToken.hashCode);
    _$hash = $jc(_$hash, expiresIn.hashCode);
    _$hash = $jc(_$hash, person.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Login200Response')
          ..add('accessToken', accessToken)
          ..add('expiresIn', expiresIn)
          ..add('person', person))
        .toString();
  }
}

class Login200ResponseBuilder
    implements Builder<Login200Response, Login200ResponseBuilder> {
  _$Login200Response? _$v;

  String? _accessToken;
  String? get accessToken => _$this._accessToken;
  set accessToken(String? accessToken) => _$this._accessToken = accessToken;

  num? _expiresIn;
  num? get expiresIn => _$this._expiresIn;
  set expiresIn(num? expiresIn) => _$this._expiresIn = expiresIn;

  Login200ResponsePersonBuilder? _person;
  Login200ResponsePersonBuilder get person =>
      _$this._person ??= Login200ResponsePersonBuilder();
  set person(Login200ResponsePersonBuilder? person) => _$this._person = person;

  Login200ResponseBuilder() {
    Login200Response._defaults(this);
  }

  Login200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accessToken = $v.accessToken;
      _expiresIn = $v.expiresIn;
      _person = $v.person.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Login200Response other) {
    _$v = other as _$Login200Response;
  }

  @override
  void update(void Function(Login200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Login200Response build() => _build();

  _$Login200Response _build() {
    _$Login200Response _$result;
    try {
      _$result =
          _$v ??
          _$Login200Response._(
            accessToken: BuiltValueNullFieldError.checkNotNull(
              accessToken,
              r'Login200Response',
              'accessToken',
            ),
            expiresIn: BuiltValueNullFieldError.checkNotNull(
              expiresIn,
              r'Login200Response',
              'expiresIn',
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
          r'Login200Response',
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
