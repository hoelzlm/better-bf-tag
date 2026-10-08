// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_vehicle_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateVehicleRequest extends CreateVehicleRequest {
  @override
  final String callSign;
  @override
  final String shortName;
  @override
  final String type;

  factory _$CreateVehicleRequest([
    void Function(CreateVehicleRequestBuilder)? updates,
  ]) => (CreateVehicleRequestBuilder()..update(updates))._build();

  _$CreateVehicleRequest._({
    required this.callSign,
    required this.shortName,
    required this.type,
  }) : super._();
  @override
  CreateVehicleRequest rebuild(
    void Function(CreateVehicleRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateVehicleRequestBuilder toBuilder() =>
      CreateVehicleRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateVehicleRequest &&
        callSign == other.callSign &&
        shortName == other.shortName &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, callSign.hashCode);
    _$hash = $jc(_$hash, shortName.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateVehicleRequest')
          ..add('callSign', callSign)
          ..add('shortName', shortName)
          ..add('type', type))
        .toString();
  }
}

class CreateVehicleRequestBuilder
    implements Builder<CreateVehicleRequest, CreateVehicleRequestBuilder> {
  _$CreateVehicleRequest? _$v;

  String? _callSign;
  String? get callSign => _$this._callSign;
  set callSign(String? callSign) => _$this._callSign = callSign;

  String? _shortName;
  String? get shortName => _$this._shortName;
  set shortName(String? shortName) => _$this._shortName = shortName;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  CreateVehicleRequestBuilder() {
    CreateVehicleRequest._defaults(this);
  }

  CreateVehicleRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _callSign = $v.callSign;
      _shortName = $v.shortName;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateVehicleRequest other) {
    _$v = other as _$CreateVehicleRequest;
  }

  @override
  void update(void Function(CreateVehicleRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateVehicleRequest build() => _build();

  _$CreateVehicleRequest _build() {
    final _$result =
        _$v ??
        _$CreateVehicleRequest._(
          callSign: BuiltValueNullFieldError.checkNotNull(
            callSign,
            r'CreateVehicleRequest',
            'callSign',
          ),
          shortName: BuiltValueNullFieldError.checkNotNull(
            shortName,
            r'CreateVehicleRequest',
            'shortName',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'CreateVehicleRequest',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
