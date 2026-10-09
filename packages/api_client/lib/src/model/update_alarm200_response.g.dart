// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_alarm200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateAlarm200Response extends UpdateAlarm200Response {
  @override
  final GetSnapshot200ResponseAlarmsInner alarm;

  factory _$UpdateAlarm200Response([
    void Function(UpdateAlarm200ResponseBuilder)? updates,
  ]) => (UpdateAlarm200ResponseBuilder()..update(updates))._build();

  _$UpdateAlarm200Response._({required this.alarm}) : super._();
  @override
  UpdateAlarm200Response rebuild(
    void Function(UpdateAlarm200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateAlarm200ResponseBuilder toBuilder() =>
      UpdateAlarm200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateAlarm200Response && alarm == other.alarm;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, alarm.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'UpdateAlarm200Response',
    )..add('alarm', alarm)).toString();
  }
}

class UpdateAlarm200ResponseBuilder
    implements Builder<UpdateAlarm200Response, UpdateAlarm200ResponseBuilder> {
  _$UpdateAlarm200Response? _$v;

  GetSnapshot200ResponseAlarmsInnerBuilder? _alarm;
  GetSnapshot200ResponseAlarmsInnerBuilder get alarm =>
      _$this._alarm ??= GetSnapshot200ResponseAlarmsInnerBuilder();
  set alarm(GetSnapshot200ResponseAlarmsInnerBuilder? alarm) =>
      _$this._alarm = alarm;

  UpdateAlarm200ResponseBuilder() {
    UpdateAlarm200Response._defaults(this);
  }

  UpdateAlarm200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _alarm = $v.alarm.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateAlarm200Response other) {
    _$v = other as _$UpdateAlarm200Response;
  }

  @override
  void update(void Function(UpdateAlarm200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateAlarm200Response build() => _build();

  _$UpdateAlarm200Response _build() {
    _$UpdateAlarm200Response _$result;
    try {
      _$result = _$v ?? _$UpdateAlarm200Response._(alarm: alarm.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'alarm';
        alarm.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'UpdateAlarm200Response',
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
