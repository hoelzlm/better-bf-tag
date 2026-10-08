// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reorder_vehicles_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReorderVehiclesRequest extends ReorderVehiclesRequest {
  @override
  final BuiltList<String> vehicleIds;

  factory _$ReorderVehiclesRequest([
    void Function(ReorderVehiclesRequestBuilder)? updates,
  ]) => (ReorderVehiclesRequestBuilder()..update(updates))._build();

  _$ReorderVehiclesRequest._({required this.vehicleIds}) : super._();
  @override
  ReorderVehiclesRequest rebuild(
    void Function(ReorderVehiclesRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ReorderVehiclesRequestBuilder toBuilder() =>
      ReorderVehiclesRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReorderVehiclesRequest && vehicleIds == other.vehicleIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, vehicleIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ReorderVehiclesRequest',
    )..add('vehicleIds', vehicleIds)).toString();
  }
}

class ReorderVehiclesRequestBuilder
    implements Builder<ReorderVehiclesRequest, ReorderVehiclesRequestBuilder> {
  _$ReorderVehiclesRequest? _$v;

  ListBuilder<String>? _vehicleIds;
  ListBuilder<String> get vehicleIds =>
      _$this._vehicleIds ??= ListBuilder<String>();
  set vehicleIds(ListBuilder<String>? vehicleIds) =>
      _$this._vehicleIds = vehicleIds;

  ReorderVehiclesRequestBuilder() {
    ReorderVehiclesRequest._defaults(this);
  }

  ReorderVehiclesRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _vehicleIds = $v.vehicleIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReorderVehiclesRequest other) {
    _$v = other as _$ReorderVehiclesRequest;
  }

  @override
  void update(void Function(ReorderVehiclesRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReorderVehiclesRequest build() => _build();

  _$ReorderVehiclesRequest _build() {
    _$ReorderVehiclesRequest _$result;
    try {
      _$result =
          _$v ?? _$ReorderVehiclesRequest._(vehicleIds: vehicleIds.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'vehicleIds';
        vehicleIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ReorderVehiclesRequest',
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
