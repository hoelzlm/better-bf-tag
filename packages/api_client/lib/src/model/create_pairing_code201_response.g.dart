// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_pairing_code201_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreatePairingCode201Response extends CreatePairingCode201Response {
  @override
  final String personId;
  @override
  final String displayName;
  @override
  final String code;
  @override
  final String expiresAt;

  factory _$CreatePairingCode201Response([
    void Function(CreatePairingCode201ResponseBuilder)? updates,
  ]) => (CreatePairingCode201ResponseBuilder()..update(updates))._build();

  _$CreatePairingCode201Response._({
    required this.personId,
    required this.displayName,
    required this.code,
    required this.expiresAt,
  }) : super._();
  @override
  CreatePairingCode201Response rebuild(
    void Function(CreatePairingCode201ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreatePairingCode201ResponseBuilder toBuilder() =>
      CreatePairingCode201ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreatePairingCode201Response &&
        personId == other.personId &&
        displayName == other.displayName &&
        code == other.code &&
        expiresAt == other.expiresAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, expiresAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreatePairingCode201Response')
          ..add('personId', personId)
          ..add('displayName', displayName)
          ..add('code', code)
          ..add('expiresAt', expiresAt))
        .toString();
  }
}

class CreatePairingCode201ResponseBuilder
    implements
        Builder<
          CreatePairingCode201Response,
          CreatePairingCode201ResponseBuilder
        > {
  _$CreatePairingCode201Response? _$v;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(String? personId) => _$this._personId = personId;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _expiresAt;
  String? get expiresAt => _$this._expiresAt;
  set expiresAt(String? expiresAt) => _$this._expiresAt = expiresAt;

  CreatePairingCode201ResponseBuilder() {
    CreatePairingCode201Response._defaults(this);
  }

  CreatePairingCode201ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _personId = $v.personId;
      _displayName = $v.displayName;
      _code = $v.code;
      _expiresAt = $v.expiresAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreatePairingCode201Response other) {
    _$v = other as _$CreatePairingCode201Response;
  }

  @override
  void update(void Function(CreatePairingCode201ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreatePairingCode201Response build() => _build();

  _$CreatePairingCode201Response _build() {
    final _$result =
        _$v ??
        _$CreatePairingCode201Response._(
          personId: BuiltValueNullFieldError.checkNotNull(
            personId,
            r'CreatePairingCode201Response',
            'personId',
          ),
          displayName: BuiltValueNullFieldError.checkNotNull(
            displayName,
            r'CreatePairingCode201Response',
            'displayName',
          ),
          code: BuiltValueNullFieldError.checkNotNull(
            code,
            r'CreatePairingCode201Response',
            'code',
          ),
          expiresAt: BuiltValueNullFieldError.checkNotNull(
            expiresAt,
            r'CreatePairingCode201Response',
            'expiresAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
