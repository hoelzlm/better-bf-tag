// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trigger_alarm_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TriggerAlarmRequest extends TriggerAlarmRequest {
  @override
  final String? id;
  @override
  final BuiltList<String> vehicleIds;

  factory _$TriggerAlarmRequest([
    void Function(TriggerAlarmRequestBuilder)? updates,
  ]) => (TriggerAlarmRequestBuilder()..update(updates))._build();

  _$TriggerAlarmRequest._({this.id, required this.vehicleIds}) : super._();
  @override
  TriggerAlarmRequest rebuild(
    void Function(TriggerAlarmRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  TriggerAlarmRequestBuilder toBuilder() =>
      TriggerAlarmRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TriggerAlarmRequest &&
        id == other.id &&
        vehicleIds == other.vehicleIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, vehicleIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TriggerAlarmRequest')
          ..add('id', id)
          ..add('vehicleIds', vehicleIds))
        .toString();
  }
}

class TriggerAlarmRequestBuilder
    implements Builder<TriggerAlarmRequest, TriggerAlarmRequestBuilder> {
  _$TriggerAlarmRequest? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  ListBuilder<String>? _vehicleIds;
  ListBuilder<String> get vehicleIds =>
      _$this._vehicleIds ??= ListBuilder<String>();
  set vehicleIds(ListBuilder<String>? vehicleIds) =>
      _$this._vehicleIds = vehicleIds;

  TriggerAlarmRequestBuilder() {
    TriggerAlarmRequest._defaults(this);
  }

  TriggerAlarmRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _vehicleIds = $v.vehicleIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TriggerAlarmRequest other) {
    _$v = other as _$TriggerAlarmRequest;
  }

  @override
  void update(void Function(TriggerAlarmRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TriggerAlarmRequest build() => _build();

  _$TriggerAlarmRequest _build() {
    _$TriggerAlarmRequest _$result;
    try {
      _$result =
          _$v ??
          _$TriggerAlarmRequest._(id: id, vehicleIds: vehicleIds.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'vehicleIds';
        vehicleIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'TriggerAlarmRequest',
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
