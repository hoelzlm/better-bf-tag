// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_vehicle_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateVehicleRequest extends UpdateVehicleRequest {
  @override
  final String? callSign;
  @override
  final String? shortName;
  @override
  final String? type;
  @override
  final bool? active;

  factory _$UpdateVehicleRequest([
    void Function(UpdateVehicleRequestBuilder)? updates,
  ]) => (UpdateVehicleRequestBuilder()..update(updates))._build();

  _$UpdateVehicleRequest._({
    this.callSign,
    this.shortName,
    this.type,
    this.active,
  }) : super._();
  @override
  UpdateVehicleRequest rebuild(
    void Function(UpdateVehicleRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateVehicleRequestBuilder toBuilder() =>
      UpdateVehicleRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateVehicleRequest &&
        callSign == other.callSign &&
        shortName == other.shortName &&
        type == other.type &&
        active == other.active;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, callSign.hashCode);
    _$hash = $jc(_$hash, shortName.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateVehicleRequest')
          ..add('callSign', callSign)
          ..add('shortName', shortName)
          ..add('type', type)
          ..add('active', active))
        .toString();
  }
}

class UpdateVehicleRequestBuilder
    implements Builder<UpdateVehicleRequest, UpdateVehicleRequestBuilder> {
  _$UpdateVehicleRequest? _$v;

  String? _callSign;
  String? get callSign => _$this._callSign;
  set callSign(String? callSign) => _$this._callSign = callSign;

  String? _shortName;
  String? get shortName => _$this._shortName;
  set shortName(String? shortName) => _$this._shortName = shortName;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  UpdateVehicleRequestBuilder() {
    UpdateVehicleRequest._defaults(this);
  }

  UpdateVehicleRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _callSign = $v.callSign;
      _shortName = $v.shortName;
      _type = $v.type;
      _active = $v.active;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateVehicleRequest other) {
    _$v = other as _$UpdateVehicleRequest;
  }

  @override
  void update(void Function(UpdateVehicleRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateVehicleRequest build() => _build();

  _$UpdateVehicleRequest _build() {
    final _$result =
        _$v ??
        _$UpdateVehicleRequest._(
          callSign: callSign,
          shortName: shortName,
          type: type,
          active: active,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
