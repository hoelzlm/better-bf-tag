// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_monitor_pairing_code201_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateMonitorPairingCode201Response
    extends CreateMonitorPairingCode201Response {
  @override
  final String monitorId;
  @override
  final String name;
  @override
  final String code;
  @override
  final String expiresAt;

  factory _$CreateMonitorPairingCode201Response([
    void Function(CreateMonitorPairingCode201ResponseBuilder)? updates,
  ]) =>
      (CreateMonitorPairingCode201ResponseBuilder()..update(updates))._build();

  _$CreateMonitorPairingCode201Response._({
    required this.monitorId,
    required this.name,
    required this.code,
    required this.expiresAt,
  }) : super._();
  @override
  CreateMonitorPairingCode201Response rebuild(
    void Function(CreateMonitorPairingCode201ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateMonitorPairingCode201ResponseBuilder toBuilder() =>
      CreateMonitorPairingCode201ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateMonitorPairingCode201Response &&
        monitorId == other.monitorId &&
        name == other.name &&
        code == other.code &&
        expiresAt == other.expiresAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, monitorId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, expiresAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateMonitorPairingCode201Response')
          ..add('monitorId', monitorId)
          ..add('name', name)
          ..add('code', code)
          ..add('expiresAt', expiresAt))
        .toString();
  }
}

class CreateMonitorPairingCode201ResponseBuilder
    implements
        Builder<
          CreateMonitorPairingCode201Response,
          CreateMonitorPairingCode201ResponseBuilder
        > {
  _$CreateMonitorPairingCode201Response? _$v;

  String? _monitorId;
  String? get monitorId => _$this._monitorId;
  set monitorId(String? monitorId) => _$this._monitorId = monitorId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _expiresAt;
  String? get expiresAt => _$this._expiresAt;
  set expiresAt(String? expiresAt) => _$this._expiresAt = expiresAt;

  CreateMonitorPairingCode201ResponseBuilder() {
    CreateMonitorPairingCode201Response._defaults(this);
  }

  CreateMonitorPairingCode201ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _monitorId = $v.monitorId;
      _name = $v.name;
      _code = $v.code;
      _expiresAt = $v.expiresAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateMonitorPairingCode201Response other) {
    _$v = other as _$CreateMonitorPairingCode201Response;
  }

  @override
  void update(
    void Function(CreateMonitorPairingCode201ResponseBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  CreateMonitorPairingCode201Response build() => _build();

  _$CreateMonitorPairingCode201Response _build() {
    final _$result =
        _$v ??
        _$CreateMonitorPairingCode201Response._(
          monitorId: BuiltValueNullFieldError.checkNotNull(
            monitorId,
            r'CreateMonitorPairingCode201Response',
            'monitorId',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'CreateMonitorPairingCode201Response',
            'name',
          ),
          code: BuiltValueNullFieldError.checkNotNull(
            code,
            r'CreateMonitorPairingCode201Response',
            'code',
          ),
          expiresAt: BuiltValueNullFieldError.checkNotNull(
            expiresAt,
            r'CreateMonitorPairingCode201Response',
            'expiresAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
