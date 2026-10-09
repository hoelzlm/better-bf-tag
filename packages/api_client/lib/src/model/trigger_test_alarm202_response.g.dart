// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trigger_test_alarm202_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TriggerTestAlarm202Response extends TriggerTestAlarm202Response {
  @override
  final bool scheduled;

  factory _$TriggerTestAlarm202Response([
    void Function(TriggerTestAlarm202ResponseBuilder)? updates,
  ]) => (TriggerTestAlarm202ResponseBuilder()..update(updates))._build();

  _$TriggerTestAlarm202Response._({required this.scheduled}) : super._();
  @override
  TriggerTestAlarm202Response rebuild(
    void Function(TriggerTestAlarm202ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  TriggerTestAlarm202ResponseBuilder toBuilder() =>
      TriggerTestAlarm202ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TriggerTestAlarm202Response && scheduled == other.scheduled;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, scheduled.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'TriggerTestAlarm202Response',
    )..add('scheduled', scheduled)).toString();
  }
}

class TriggerTestAlarm202ResponseBuilder
    implements
        Builder<
          TriggerTestAlarm202Response,
          TriggerTestAlarm202ResponseBuilder
        > {
  _$TriggerTestAlarm202Response? _$v;

  bool? _scheduled;
  bool? get scheduled => _$this._scheduled;
  set scheduled(bool? scheduled) => _$this._scheduled = scheduled;

  TriggerTestAlarm202ResponseBuilder() {
    TriggerTestAlarm202Response._defaults(this);
  }

  TriggerTestAlarm202ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _scheduled = $v.scheduled;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TriggerTestAlarm202Response other) {
    _$v = other as _$TriggerTestAlarm202Response;
  }

  @override
  void update(void Function(TriggerTestAlarm202ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TriggerTestAlarm202Response build() => _build();

  _$TriggerTestAlarm202Response _build() {
    final _$result =
        _$v ??
        _$TriggerTestAlarm202Response._(
          scheduled: BuiltValueNullFieldError.checkNotNull(
            scheduled,
            r'TriggerTestAlarm202Response',
            'scheduled',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
