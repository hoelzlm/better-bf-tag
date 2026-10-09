// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_alarm_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateAlarmRequest extends CreateAlarmRequest {
  @override
  final String? id;
  @override
  final BuiltList<String> vehicleIds;
  @override
  final DateTime? scheduledAt;
  @override
  final int? offsetMinutes;

  factory _$CreateAlarmRequest([
    void Function(CreateAlarmRequestBuilder)? updates,
  ]) => (CreateAlarmRequestBuilder()..update(updates))._build();

  _$CreateAlarmRequest._({
    this.id,
    required this.vehicleIds,
    this.scheduledAt,
    this.offsetMinutes,
  }) : super._();
  @override
  CreateAlarmRequest rebuild(
    void Function(CreateAlarmRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateAlarmRequestBuilder toBuilder() =>
      CreateAlarmRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateAlarmRequest &&
        id == other.id &&
        vehicleIds == other.vehicleIds &&
        scheduledAt == other.scheduledAt &&
        offsetMinutes == other.offsetMinutes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, vehicleIds.hashCode);
    _$hash = $jc(_$hash, scheduledAt.hashCode);
    _$hash = $jc(_$hash, offsetMinutes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateAlarmRequest')
          ..add('id', id)
          ..add('vehicleIds', vehicleIds)
          ..add('scheduledAt', scheduledAt)
          ..add('offsetMinutes', offsetMinutes))
        .toString();
  }
}

class CreateAlarmRequestBuilder
    implements Builder<CreateAlarmRequest, CreateAlarmRequestBuilder> {
  _$CreateAlarmRequest? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  ListBuilder<String>? _vehicleIds;
  ListBuilder<String> get vehicleIds =>
      _$this._vehicleIds ??= ListBuilder<String>();
  set vehicleIds(ListBuilder<String>? vehicleIds) =>
      _$this._vehicleIds = vehicleIds;

  DateTime? _scheduledAt;
  DateTime? get scheduledAt => _$this._scheduledAt;
  set scheduledAt(DateTime? scheduledAt) => _$this._scheduledAt = scheduledAt;

  int? _offsetMinutes;
  int? get offsetMinutes => _$this._offsetMinutes;
  set offsetMinutes(int? offsetMinutes) =>
      _$this._offsetMinutes = offsetMinutes;

  CreateAlarmRequestBuilder() {
    CreateAlarmRequest._defaults(this);
  }

  CreateAlarmRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _vehicleIds = $v.vehicleIds.toBuilder();
      _scheduledAt = $v.scheduledAt;
      _offsetMinutes = $v.offsetMinutes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateAlarmRequest other) {
    _$v = other as _$CreateAlarmRequest;
  }

  @override
  void update(void Function(CreateAlarmRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateAlarmRequest build() => _build();

  _$CreateAlarmRequest _build() {
    _$CreateAlarmRequest _$result;
    try {
      _$result =
          _$v ??
          _$CreateAlarmRequest._(
            id: id,
            vehicleIds: vehicleIds.build(),
            scheduledAt: scheduledAt,
            offsetMinutes: offsetMinutes,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'vehicleIds';
        vehicleIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'CreateAlarmRequest',
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
