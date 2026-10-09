// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_alarm200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateAlarm200Response extends CreateAlarm200Response {
  @override
  final GetSnapshot200ResponseAlarmsInner alarm;
  @override
  final BuiltList<CreateAlarm200ResponseDoubleCrewedInner> doubleCrewed;

  factory _$CreateAlarm200Response([
    void Function(CreateAlarm200ResponseBuilder)? updates,
  ]) => (CreateAlarm200ResponseBuilder()..update(updates))._build();

  _$CreateAlarm200Response._({required this.alarm, required this.doubleCrewed})
    : super._();
  @override
  CreateAlarm200Response rebuild(
    void Function(CreateAlarm200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateAlarm200ResponseBuilder toBuilder() =>
      CreateAlarm200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateAlarm200Response &&
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
    return (newBuiltValueToStringHelper(r'CreateAlarm200Response')
          ..add('alarm', alarm)
          ..add('doubleCrewed', doubleCrewed))
        .toString();
  }
}

class CreateAlarm200ResponseBuilder
    implements Builder<CreateAlarm200Response, CreateAlarm200ResponseBuilder> {
  _$CreateAlarm200Response? _$v;

  GetSnapshot200ResponseAlarmsInnerBuilder? _alarm;
  GetSnapshot200ResponseAlarmsInnerBuilder get alarm =>
      _$this._alarm ??= GetSnapshot200ResponseAlarmsInnerBuilder();
  set alarm(GetSnapshot200ResponseAlarmsInnerBuilder? alarm) =>
      _$this._alarm = alarm;

  ListBuilder<CreateAlarm200ResponseDoubleCrewedInner>? _doubleCrewed;
  ListBuilder<CreateAlarm200ResponseDoubleCrewedInner> get doubleCrewed =>
      _$this._doubleCrewed ??=
          ListBuilder<CreateAlarm200ResponseDoubleCrewedInner>();
  set doubleCrewed(
    ListBuilder<CreateAlarm200ResponseDoubleCrewedInner>? doubleCrewed,
  ) => _$this._doubleCrewed = doubleCrewed;

  CreateAlarm200ResponseBuilder() {
    CreateAlarm200Response._defaults(this);
  }

  CreateAlarm200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _alarm = $v.alarm.toBuilder();
      _doubleCrewed = $v.doubleCrewed.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateAlarm200Response other) {
    _$v = other as _$CreateAlarm200Response;
  }

  @override
  void update(void Function(CreateAlarm200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateAlarm200Response build() => _build();

  _$CreateAlarm200Response _build() {
    _$CreateAlarm200Response _$result;
    try {
      _$result =
          _$v ??
          _$CreateAlarm200Response._(
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
          r'CreateAlarm200Response',
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
