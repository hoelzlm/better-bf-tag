// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trigger_test_alarm_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TriggerTestAlarmRequest extends TriggerTestAlarmRequest {
  @override
  final int? delaySeconds;

  factory _$TriggerTestAlarmRequest([
    void Function(TriggerTestAlarmRequestBuilder)? updates,
  ]) => (TriggerTestAlarmRequestBuilder()..update(updates))._build();

  _$TriggerTestAlarmRequest._({this.delaySeconds}) : super._();
  @override
  TriggerTestAlarmRequest rebuild(
    void Function(TriggerTestAlarmRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  TriggerTestAlarmRequestBuilder toBuilder() =>
      TriggerTestAlarmRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TriggerTestAlarmRequest &&
        delaySeconds == other.delaySeconds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, delaySeconds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'TriggerTestAlarmRequest',
    )..add('delaySeconds', delaySeconds)).toString();
  }
}

class TriggerTestAlarmRequestBuilder
    implements
        Builder<TriggerTestAlarmRequest, TriggerTestAlarmRequestBuilder> {
  _$TriggerTestAlarmRequest? _$v;

  int? _delaySeconds;
  int? get delaySeconds => _$this._delaySeconds;
  set delaySeconds(int? delaySeconds) => _$this._delaySeconds = delaySeconds;

  TriggerTestAlarmRequestBuilder() {
    TriggerTestAlarmRequest._defaults(this);
  }

  TriggerTestAlarmRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _delaySeconds = $v.delaySeconds;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TriggerTestAlarmRequest other) {
    _$v = other as _$TriggerTestAlarmRequest;
  }

  @override
  void update(void Function(TriggerTestAlarmRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TriggerTestAlarmRequest build() => _build();

  _$TriggerTestAlarmRequest _build() {
    final _$result =
        _$v ?? _$TriggerTestAlarmRequest._(delaySeconds: delaySeconds);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
