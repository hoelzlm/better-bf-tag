// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_vehicle_status_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SetVehicleStatusRequest extends SetVehicleStatusRequest {
  @override
  final int status;

  factory _$SetVehicleStatusRequest([
    void Function(SetVehicleStatusRequestBuilder)? updates,
  ]) => (SetVehicleStatusRequestBuilder()..update(updates))._build();

  _$SetVehicleStatusRequest._({required this.status}) : super._();
  @override
  SetVehicleStatusRequest rebuild(
    void Function(SetVehicleStatusRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  SetVehicleStatusRequestBuilder toBuilder() =>
      SetVehicleStatusRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SetVehicleStatusRequest && status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'SetVehicleStatusRequest',
    )..add('status', status)).toString();
  }
}

class SetVehicleStatusRequestBuilder
    implements
        Builder<SetVehicleStatusRequest, SetVehicleStatusRequestBuilder> {
  _$SetVehicleStatusRequest? _$v;

  int? _status;
  int? get status => _$this._status;
  set status(int? status) => _$this._status = status;

  SetVehicleStatusRequestBuilder() {
    SetVehicleStatusRequest._defaults(this);
  }

  SetVehicleStatusRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SetVehicleStatusRequest other) {
    _$v = other as _$SetVehicleStatusRequest;
  }

  @override
  void update(void Function(SetVehicleStatusRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SetVehicleStatusRequest build() => _build();

  _$SetVehicleStatusRequest _build() {
    final _$result =
        _$v ??
        _$SetVehicleStatusRequest._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'SetVehicleStatusRequest',
            'status',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
