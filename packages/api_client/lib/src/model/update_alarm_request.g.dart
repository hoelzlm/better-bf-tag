// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_alarm_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateAlarmRequest extends UpdateAlarmRequest {
  @override
  final DateTime? scheduledAt;
  @override
  final int? offsetMinutes;
  @override
  final BuiltList<String>? vehicleIds;

  factory _$UpdateAlarmRequest([
    void Function(UpdateAlarmRequestBuilder)? updates,
  ]) => (UpdateAlarmRequestBuilder()..update(updates))._build();

  _$UpdateAlarmRequest._({
    this.scheduledAt,
    this.offsetMinutes,
    this.vehicleIds,
  }) : super._();
  @override
  UpdateAlarmRequest rebuild(
    void Function(UpdateAlarmRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateAlarmRequestBuilder toBuilder() =>
      UpdateAlarmRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateAlarmRequest &&
        scheduledAt == other.scheduledAt &&
        offsetMinutes == other.offsetMinutes &&
        vehicleIds == other.vehicleIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, scheduledAt.hashCode);
    _$hash = $jc(_$hash, offsetMinutes.hashCode);
    _$hash = $jc(_$hash, vehicleIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateAlarmRequest')
          ..add('scheduledAt', scheduledAt)
          ..add('offsetMinutes', offsetMinutes)
          ..add('vehicleIds', vehicleIds))
        .toString();
  }
}

class UpdateAlarmRequestBuilder
    implements Builder<UpdateAlarmRequest, UpdateAlarmRequestBuilder> {
  _$UpdateAlarmRequest? _$v;

  DateTime? _scheduledAt;
  DateTime? get scheduledAt => _$this._scheduledAt;
  set scheduledAt(DateTime? scheduledAt) => _$this._scheduledAt = scheduledAt;

  int? _offsetMinutes;
  int? get offsetMinutes => _$this._offsetMinutes;
  set offsetMinutes(int? offsetMinutes) =>
      _$this._offsetMinutes = offsetMinutes;

  ListBuilder<String>? _vehicleIds;
  ListBuilder<String> get vehicleIds =>
      _$this._vehicleIds ??= ListBuilder<String>();
  set vehicleIds(ListBuilder<String>? vehicleIds) =>
      _$this._vehicleIds = vehicleIds;

  UpdateAlarmRequestBuilder() {
    UpdateAlarmRequest._defaults(this);
  }

  UpdateAlarmRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _scheduledAt = $v.scheduledAt;
      _offsetMinutes = $v.offsetMinutes;
      _vehicleIds = $v.vehicleIds?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateAlarmRequest other) {
    _$v = other as _$UpdateAlarmRequest;
  }

  @override
  void update(void Function(UpdateAlarmRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateAlarmRequest build() => _build();

  _$UpdateAlarmRequest _build() {
    _$UpdateAlarmRequest _$result;
    try {
      _$result =
          _$v ??
          _$UpdateAlarmRequest._(
            scheduledAt: scheduledAt,
            offsetMinutes: offsetMinutes,
            vehicleIds: _vehicleIds?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'vehicleIds';
        _vehicleIds?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'UpdateAlarmRequest',
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
