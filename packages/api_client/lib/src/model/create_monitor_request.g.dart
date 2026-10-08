// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_monitor_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateMonitorRequest extends CreateMonitorRequest {
  @override
  final String name;

  factory _$CreateMonitorRequest([
    void Function(CreateMonitorRequestBuilder)? updates,
  ]) => (CreateMonitorRequestBuilder()..update(updates))._build();

  _$CreateMonitorRequest._({required this.name}) : super._();
  @override
  CreateMonitorRequest rebuild(
    void Function(CreateMonitorRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateMonitorRequestBuilder toBuilder() =>
      CreateMonitorRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateMonitorRequest && name == other.name;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'CreateMonitorRequest',
    )..add('name', name)).toString();
  }
}

class CreateMonitorRequestBuilder
    implements Builder<CreateMonitorRequest, CreateMonitorRequestBuilder> {
  _$CreateMonitorRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  CreateMonitorRequestBuilder() {
    CreateMonitorRequest._defaults(this);
  }

  CreateMonitorRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateMonitorRequest other) {
    _$v = other as _$CreateMonitorRequest;
  }

  @override
  void update(void Function(CreateMonitorRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateMonitorRequest build() => _build();

  _$CreateMonitorRequest _build() {
    final _$result =
        _$v ??
        _$CreateMonitorRequest._(
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'CreateMonitorRequest',
            'name',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
