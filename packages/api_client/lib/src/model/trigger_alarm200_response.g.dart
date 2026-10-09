// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trigger_alarm200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TriggerAlarm200Response extends TriggerAlarm200Response {
  @override
  final GetSnapshot200ResponseAlarmsInner alarm;
  @override
  final BuiltList<TriggerAlarm200ResponseDoubleCrewedInner> doubleCrewed;

  factory _$TriggerAlarm200Response([
    void Function(TriggerAlarm200ResponseBuilder)? updates,
  ]) => (TriggerAlarm200ResponseBuilder()..update(updates))._build();

  _$TriggerAlarm200Response._({required this.alarm, required this.doubleCrewed})
    : super._();
  @override
  TriggerAlarm200Response rebuild(
    void Function(TriggerAlarm200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  TriggerAlarm200ResponseBuilder toBuilder() =>
      TriggerAlarm200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TriggerAlarm200Response &&
        alarm == other.alarm &&
        doubleCrewed == other.doubleCrewed;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, alarm.hashCode);
    _$hash = $jc(_$hash, doubleCrewed.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TriggerAlarm200Response')
          ..add('alarm', alarm)
          ..add('doubleCrewed', doubleCrewed))
        .toString();
  }
}

class TriggerAlarm200ResponseBuilder
    implements
        Builder<TriggerAlarm200Response, TriggerAlarm200ResponseBuilder> {
  _$TriggerAlarm200Response? _$v;

  GetSnapshot200ResponseAlarmsInnerBuilder? _alarm;
  GetSnapshot200ResponseAlarmsInnerBuilder get alarm =>
      _$this._alarm ??= GetSnapshot200ResponseAlarmsInnerBuilder();
  set alarm(GetSnapshot200ResponseAlarmsInnerBuilder? alarm) =>
      _$this._alarm = alarm;

  ListBuilder<TriggerAlarm200ResponseDoubleCrewedInner>? _doubleCrewed;
  ListBuilder<TriggerAlarm200ResponseDoubleCrewedInner> get doubleCrewed =>
      _$this._doubleCrewed ??=
          ListBuilder<TriggerAlarm200ResponseDoubleCrewedInner>();
  set doubleCrewed(
    ListBuilder<TriggerAlarm200ResponseDoubleCrewedInner>? doubleCrewed,
  ) => _$this._doubleCrewed = doubleCrewed;

  TriggerAlarm200ResponseBuilder() {
    TriggerAlarm200Response._defaults(this);
  }

  TriggerAlarm200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _alarm = $v.alarm.toBuilder();
      _doubleCrewed = $v.doubleCrewed.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TriggerAlarm200Response other) {
    _$v = other as _$TriggerAlarm200Response;
  }

  @override
  void update(void Function(TriggerAlarm200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TriggerAlarm200Response build() => _build();

  _$TriggerAlarm200Response _build() {
    _$TriggerAlarm200Response _$result;
    try {
      _$result =
          _$v ??
          _$TriggerAlarm200Response._(
            alarm: alarm.build(),
            doubleCrewed: doubleCrewed.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'alarm';
        alarm.build();
        _$failedField = 'doubleCrewed';
        doubleCrewed.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'TriggerAlarm200Response',
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
