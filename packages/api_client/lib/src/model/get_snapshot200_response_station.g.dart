// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_snapshot200_response_station.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GetSnapshot200ResponseStation extends GetSnapshot200ResponseStation {
  @override
  final num latitude;
  @override
  final num longitude;

  factory _$GetSnapshot200ResponseStation([
    void Function(GetSnapshot200ResponseStationBuilder)? updates,
  ]) => (GetSnapshot200ResponseStationBuilder()..update(updates))._build();

  _$GetSnapshot200ResponseStation._({
    required this.latitude,
    required this.longitude,
  }) : super._();
  @override
  GetSnapshot200ResponseStation rebuild(
    void Function(GetSnapshot200ResponseStationBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetSnapshot200ResponseStationBuilder toBuilder() =>
      GetSnapshot200ResponseStationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetSnapshot200ResponseStation &&
        latitude == other.latitude &&
        longitude == other.longitude;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, latitude.hashCode);
    _$hash = $jc(_$hash, longitude.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GetSnapshot200ResponseStation')
          ..add('latitude', latitude)
          ..add('longitude', longitude))
        .toString();
  }
}

class GetSnapshot200ResponseStationBuilder
    implements
        Builder<
          GetSnapshot200ResponseStation,
          GetSnapshot200ResponseStationBuilder
        > {
  _$GetSnapshot200ResponseStation? _$v;

  num? _latitude;
  num? get latitude => _$this._latitude;
  set latitude(num? latitude) => _$this._latitude = latitude;

  num? _longitude;
  num? get longitude => _$this._longitude;
  set longitude(num? longitude) => _$this._longitude = longitude;

  GetSnapshot200ResponseStationBuilder() {
    GetSnapshot200ResponseStation._defaults(this);
  }

  GetSnapshot200ResponseStationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _latitude = $v.latitude;
      _longitude = $v.longitude;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetSnapshot200ResponseStation other) {
    _$v = other as _$GetSnapshot200ResponseStation;
  }

  @override
  void update(void Function(GetSnapshot200ResponseStationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GetSnapshot200ResponseStation build() => _build();

  _$GetSnapshot200ResponseStation _build() {
    final _$result =
        _$v ??
        _$GetSnapshot200ResponseStation._(
          latitude: BuiltValueNullFieldError.checkNotNull(
            latitude,
            r'GetSnapshot200ResponseStation',
            'latitude',
          ),
          longitude: BuiltValueNullFieldError.checkNotNull(
            longitude,
            r'GetSnapshot200ResponseStation',
            'longitude',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
