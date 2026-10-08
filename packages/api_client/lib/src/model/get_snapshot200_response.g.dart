// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_snapshot200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GetSnapshot200Response extends GetSnapshot200Response {
  @override
  final int seq;
  @override
  final BuiltList<ListVehicles200ResponseInner> vehicles;
  @override
  final BuiltList<GetSnapshot200ResponseSlidesInner> slides;

  factory _$GetSnapshot200Response([
    void Function(GetSnapshot200ResponseBuilder)? updates,
  ]) => (GetSnapshot200ResponseBuilder()..update(updates))._build();

  _$GetSnapshot200Response._({
    required this.seq,
    required this.vehicles,
    required this.slides,
  }) : super._();
  @override
  GetSnapshot200Response rebuild(
    void Function(GetSnapshot200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetSnapshot200ResponseBuilder toBuilder() =>
      GetSnapshot200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetSnapshot200Response &&
        seq == other.seq &&
        vehicles == other.vehicles &&
        slides == other.slides;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, seq.hashCode);
    _$hash = $jc(_$hash, vehicles.hashCode);
    _$hash = $jc(_$hash, slides.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GetSnapshot200Response')
          ..add('seq', seq)
          ..add('vehicles', vehicles)
          ..add('slides', slides))
        .toString();
  }
}

class GetSnapshot200ResponseBuilder
    implements Builder<GetSnapshot200Response, GetSnapshot200ResponseBuilder> {
  _$GetSnapshot200Response? _$v;

  int? _seq;
  int? get seq => _$this._seq;
  set seq(int? seq) => _$this._seq = seq;

  ListBuilder<ListVehicles200ResponseInner>? _vehicles;
  ListBuilder<ListVehicles200ResponseInner> get vehicles =>
      _$this._vehicles ??= ListBuilder<ListVehicles200ResponseInner>();
  set vehicles(ListBuilder<ListVehicles200ResponseInner>? vehicles) =>
      _$this._vehicles = vehicles;

  ListBuilder<GetSnapshot200ResponseSlidesInner>? _slides;
  ListBuilder<GetSnapshot200ResponseSlidesInner> get slides =>
      _$this._slides ??= ListBuilder<GetSnapshot200ResponseSlidesInner>();
  set slides(ListBuilder<GetSnapshot200ResponseSlidesInner>? slides) =>
      _$this._slides = slides;

  GetSnapshot200ResponseBuilder() {
    GetSnapshot200Response._defaults(this);
  }

  GetSnapshot200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _seq = $v.seq;
      _vehicles = $v.vehicles.toBuilder();
      _slides = $v.slides.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetSnapshot200Response other) {
    _$v = other as _$GetSnapshot200Response;
  }

  @override
  void update(void Function(GetSnapshot200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GetSnapshot200Response build() => _build();

  _$GetSnapshot200Response _build() {
    _$GetSnapshot200Response _$result;
    try {
      _$result =
          _$v ??
          _$GetSnapshot200Response._(
            seq: BuiltValueNullFieldError.checkNotNull(
              seq,
              r'GetSnapshot200Response',
              'seq',
            ),
            vehicles: vehicles.build(),
            slides: slides.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'vehicles';
        vehicles.build();
        _$failedField = 'slides';
        slides.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'GetSnapshot200Response',
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
