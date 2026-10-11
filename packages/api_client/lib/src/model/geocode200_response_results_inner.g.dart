// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geocode200_response_results_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Geocode200ResponseResultsInner extends Geocode200ResponseResultsInner {
  @override
  final String label;
  @override
  final num latitude;
  @override
  final num longitude;

  factory _$Geocode200ResponseResultsInner([
    void Function(Geocode200ResponseResultsInnerBuilder)? updates,
  ]) => (Geocode200ResponseResultsInnerBuilder()..update(updates))._build();

  _$Geocode200ResponseResultsInner._({
    required this.label,
    required this.latitude,
    required this.longitude,
  }) : super._();
  @override
  Geocode200ResponseResultsInner rebuild(
    void Function(Geocode200ResponseResultsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  Geocode200ResponseResultsInnerBuilder toBuilder() =>
      Geocode200ResponseResultsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Geocode200ResponseResultsInner &&
        label == other.label &&
        latitude == other.latitude &&
        longitude == other.longitude;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, label.hashCode);
    _$hash = $jc(_$hash, latitude.hashCode);
    _$hash = $jc(_$hash, longitude.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Geocode200ResponseResultsInner')
          ..add('label', label)
          ..add('latitude', latitude)
          ..add('longitude', longitude))
        .toString();
  }
}

class Geocode200ResponseResultsInnerBuilder
    implements
        Builder<
          Geocode200ResponseResultsInner,
          Geocode200ResponseResultsInnerBuilder
        > {
  _$Geocode200ResponseResultsInner? _$v;

  String? _label;
  String? get label => _$this._label;
  set label(String? label) => _$this._label = label;

  num? _latitude;
  num? get latitude => _$this._latitude;
  set latitude(num? latitude) => _$this._latitude = latitude;

  num? _longitude;
  num? get longitude => _$this._longitude;
  set longitude(num? longitude) => _$this._longitude = longitude;

  Geocode200ResponseResultsInnerBuilder() {
    Geocode200ResponseResultsInner._defaults(this);
  }

  Geocode200ResponseResultsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _label = $v.label;
      _latitude = $v.latitude;
      _longitude = $v.longitude;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Geocode200ResponseResultsInner other) {
    _$v = other as _$Geocode200ResponseResultsInner;
  }

  @override
  void update(void Function(Geocode200ResponseResultsInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Geocode200ResponseResultsInner build() => _build();

  _$Geocode200ResponseResultsInner _build() {
    final _$result =
        _$v ??
        _$Geocode200ResponseResultsInner._(
          label: BuiltValueNullFieldError.checkNotNull(
            label,
            r'Geocode200ResponseResultsInner',
            'label',
          ),
          latitude: BuiltValueNullFieldError.checkNotNull(
            latitude,
            r'Geocode200ResponseResultsInner',
            'latitude',
          ),
          longitude: BuiltValueNullFieldError.checkNotNull(
            longitude,
            r'Geocode200ResponseResultsInner',
            'longitude',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
