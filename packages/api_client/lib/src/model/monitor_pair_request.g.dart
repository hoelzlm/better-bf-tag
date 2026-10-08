// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monitor_pair_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MonitorPairRequest extends MonitorPairRequest {
  @override
  final String code;

  factory _$MonitorPairRequest([
    void Function(MonitorPairRequestBuilder)? updates,
  ]) => (MonitorPairRequestBuilder()..update(updates))._build();

  _$MonitorPairRequest._({required this.code}) : super._();
  @override
  MonitorPairRequest rebuild(
    void Function(MonitorPairRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  MonitorPairRequestBuilder toBuilder() =>
      MonitorPairRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MonitorPairRequest && code == other.code;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'MonitorPairRequest',
    )..add('code', code)).toString();
  }
}

class MonitorPairRequestBuilder
    implements Builder<MonitorPairRequest, MonitorPairRequestBuilder> {
  _$MonitorPairRequest? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  MonitorPairRequestBuilder() {
    MonitorPairRequest._defaults(this);
  }

  MonitorPairRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MonitorPairRequest other) {
    _$v = other as _$MonitorPairRequest;
  }

  @override
  void update(void Function(MonitorPairRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MonitorPairRequest build() => _build();

  _$MonitorPairRequest _build() {
    final _$result =
        _$v ??
        _$MonitorPairRequest._(
          code: BuiltValueNullFieldError.checkNotNull(
            code,
            r'MonitorPairRequest',
            'code',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
