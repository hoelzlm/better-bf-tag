// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_snapshot200_response_scheduled_alarms_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GetSnapshot200ResponseScheduledAlarmsInner
    extends GetSnapshot200ResponseScheduledAlarmsInner {
  @override
  final GetSnapshot200ResponseIncidentsInner incident;
  @override
  final GetSnapshot200ResponseAlarmsInner alarm;

  factory _$GetSnapshot200ResponseScheduledAlarmsInner([
    void Function(GetSnapshot200ResponseScheduledAlarmsInnerBuilder)? updates,
  ]) => (GetSnapshot200ResponseScheduledAlarmsInnerBuilder()..update(updates))
      ._build();

  _$GetSnapshot200ResponseScheduledAlarmsInner._({
    required this.incident,
    required this.alarm,
  }) : super._();
  @override
  GetSnapshot200ResponseScheduledAlarmsInner rebuild(
    void Function(GetSnapshot200ResponseScheduledAlarmsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetSnapshot200ResponseScheduledAlarmsInnerBuilder toBuilder() =>
      GetSnapshot200ResponseScheduledAlarmsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetSnapshot200ResponseScheduledAlarmsInner &&
        incident == other.incident &&
        alarm == other.alarm;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, incident.hashCode);
    _$hash = $jc(_$hash, alarm.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'GetSnapshot200ResponseScheduledAlarmsInner',
          )
          ..add('incident', incident)
          ..add('alarm', alarm))
        .toString();
  }
}

class GetSnapshot200ResponseScheduledAlarmsInnerBuilder
    implements
        Builder<
          GetSnapshot200ResponseScheduledAlarmsInner,
          GetSnapshot200ResponseScheduledAlarmsInnerBuilder
        > {
  _$GetSnapshot200ResponseScheduledAlarmsInner? _$v;

  GetSnapshot200ResponseIncidentsInnerBuilder? _incident;
  GetSnapshot200ResponseIncidentsInnerBuilder get incident =>
      _$this._incident ??= GetSnapshot200ResponseIncidentsInnerBuilder();
  set incident(GetSnapshot200ResponseIncidentsInnerBuilder? incident) =>
      _$this._incident = incident;

  GetSnapshot200ResponseAlarmsInnerBuilder? _alarm;
  GetSnapshot200ResponseAlarmsInnerBuilder get alarm =>
      _$this._alarm ??= GetSnapshot200ResponseAlarmsInnerBuilder();
  set alarm(GetSnapshot200ResponseAlarmsInnerBuilder? alarm) =>
      _$this._alarm = alarm;

  GetSnapshot200ResponseScheduledAlarmsInnerBuilder() {
    GetSnapshot200ResponseScheduledAlarmsInner._defaults(this);
  }

  GetSnapshot200ResponseScheduledAlarmsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _incident = $v.incident.toBuilder();
      _alarm = $v.alarm.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetSnapshot200ResponseScheduledAlarmsInner other) {
    _$v = other as _$GetSnapshot200ResponseScheduledAlarmsInner;
  }

  @override
  void update(
    void Function(GetSnapshot200ResponseScheduledAlarmsInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  GetSnapshot200ResponseScheduledAlarmsInner build() => _build();

  _$GetSnapshot200ResponseScheduledAlarmsInner _build() {
    _$GetSnapshot200ResponseScheduledAlarmsInner _$result;
    try {
      _$result =
          _$v ??
          _$GetSnapshot200ResponseScheduledAlarmsInner._(
            incident: incident.build(),
            alarm: alarm.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'incident';
        incident.build();
        _$failedField = 'alarm';
        alarm.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'GetSnapshot200ResponseScheduledAlarmsInner',
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
