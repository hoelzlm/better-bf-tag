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
  @override
  final GetSnapshot200ResponseBfDay? bfDay;
  @override
  final BuiltList<GetSnapshot200ResponseShiftsInner> shifts;
  @override
  final String? currentShiftId;
  @override
  final BuiltList<GetSnapshot200ResponseIncidentsInner> incidents;

  factory _$GetSnapshot200Response([
    void Function(GetSnapshot200ResponseBuilder)? updates,
  ]) => (GetSnapshot200ResponseBuilder()..update(updates))._build();

  _$GetSnapshot200Response._({
    required this.seq,
    required this.vehicles,
    required this.slides,
    this.bfDay,
    required this.shifts,
    this.currentShiftId,
    required this.incidents,
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
        slides == other.slides &&
        bfDay == other.bfDay &&
        shifts == other.shifts &&
        currentShiftId == other.currentShiftId &&
        incidents == other.incidents;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, seq.hashCode);
    _$hash = $jc(_$hash, vehicles.hashCode);
    _$hash = $jc(_$hash, slides.hashCode);
    _$hash = $jc(_$hash, bfDay.hashCode);
    _$hash = $jc(_$hash, shifts.hashCode);
    _$hash = $jc(_$hash, currentShiftId.hashCode);
    _$hash = $jc(_$hash, incidents.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GetSnapshot200Response')
          ..add('seq', seq)
          ..add('vehicles', vehicles)
          ..add('slides', slides)
          ..add('bfDay', bfDay)
          ..add('shifts', shifts)
          ..add('currentShiftId', currentShiftId)
          ..add('incidents', incidents))
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

  GetSnapshot200ResponseBfDayBuilder? _bfDay;
  GetSnapshot200ResponseBfDayBuilder get bfDay =>
      _$this._bfDay ??= GetSnapshot200ResponseBfDayBuilder();
  set bfDay(GetSnapshot200ResponseBfDayBuilder? bfDay) => _$this._bfDay = bfDay;

  ListBuilder<GetSnapshot200ResponseShiftsInner>? _shifts;
  ListBuilder<GetSnapshot200ResponseShiftsInner> get shifts =>
      _$this._shifts ??= ListBuilder<GetSnapshot200ResponseShiftsInner>();
  set shifts(ListBuilder<GetSnapshot200ResponseShiftsInner>? shifts) =>
      _$this._shifts = shifts;

  String? _currentShiftId;
  String? get currentShiftId => _$this._currentShiftId;
  set currentShiftId(String? currentShiftId) =>
      _$this._currentShiftId = currentShiftId;

  ListBuilder<GetSnapshot200ResponseIncidentsInner>? _incidents;
  ListBuilder<GetSnapshot200ResponseIncidentsInner> get incidents =>
      _$this._incidents ??= ListBuilder<GetSnapshot200ResponseIncidentsInner>();
  set incidents(ListBuilder<GetSnapshot200ResponseIncidentsInner>? incidents) =>
      _$this._incidents = incidents;

  GetSnapshot200ResponseBuilder() {
    GetSnapshot200Response._defaults(this);
  }

  GetSnapshot200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _seq = $v.seq;
      _vehicles = $v.vehicles.toBuilder();
      _slides = $v.slides.toBuilder();
      _bfDay = $v.bfDay?.toBuilder();
      _shifts = $v.shifts.toBuilder();
      _currentShiftId = $v.currentShiftId;
      _incidents = $v.incidents.toBuilder();
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
            bfDay: _bfDay?.build(),
            shifts: shifts.build(),
            currentShiftId: currentShiftId,
            incidents: incidents.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'vehicles';
        vehicles.build();
        _$failedField = 'slides';
        slides.build();
        _$failedField = 'bfDay';
        _bfDay?.build();
        _$failedField = 'shifts';
        shifts.build();

        _$failedField = 'incidents';
        incidents.build();
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
