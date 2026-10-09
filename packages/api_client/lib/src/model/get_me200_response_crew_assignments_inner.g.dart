// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_me200_response_crew_assignments_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GetMe200ResponseCrewAssignmentsInner
    extends GetMe200ResponseCrewAssignmentsInner {
  @override
  final String shiftId;
  @override
  final String vehicleId;
  @override
  final String function_;

  factory _$GetMe200ResponseCrewAssignmentsInner([
    void Function(GetMe200ResponseCrewAssignmentsInnerBuilder)? updates,
  ]) =>
      (GetMe200ResponseCrewAssignmentsInnerBuilder()..update(updates))._build();

  _$GetMe200ResponseCrewAssignmentsInner._({
    required this.shiftId,
    required this.vehicleId,
    required this.function_,
  }) : super._();
  @override
  GetMe200ResponseCrewAssignmentsInner rebuild(
    void Function(GetMe200ResponseCrewAssignmentsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetMe200ResponseCrewAssignmentsInnerBuilder toBuilder() =>
      GetMe200ResponseCrewAssignmentsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetMe200ResponseCrewAssignmentsInner &&
        shiftId == other.shiftId &&
        vehicleId == other.vehicleId &&
        function_ == other.function_;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, shiftId.hashCode);
    _$hash = $jc(_$hash, vehicleId.hashCode);
    _$hash = $jc(_$hash, function_.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GetMe200ResponseCrewAssignmentsInner')
          ..add('shiftId', shiftId)
          ..add('vehicleId', vehicleId)
          ..add('function_', function_))
        .toString();
  }
}

class GetMe200ResponseCrewAssignmentsInnerBuilder
    implements
        Builder<
          GetMe200ResponseCrewAssignmentsInner,
          GetMe200ResponseCrewAssignmentsInnerBuilder
        > {
  _$GetMe200ResponseCrewAssignmentsInner? _$v;

  String? _shiftId;
  String? get shiftId => _$this._shiftId;
  set shiftId(String? shiftId) => _$this._shiftId = shiftId;

  String? _vehicleId;
  String? get vehicleId => _$this._vehicleId;
  set vehicleId(String? vehicleId) => _$this._vehicleId = vehicleId;

  String? _function_;
  String? get function_ => _$this._function_;
  set function_(String? function_) => _$this._function_ = function_;

  GetMe200ResponseCrewAssignmentsInnerBuilder() {
    GetMe200ResponseCrewAssignmentsInner._defaults(this);
  }

  GetMe200ResponseCrewAssignmentsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _shiftId = $v.shiftId;
      _vehicleId = $v.vehicleId;
      _function_ = $v.function_;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetMe200ResponseCrewAssignmentsInner other) {
    _$v = other as _$GetMe200ResponseCrewAssignmentsInner;
  }

  @override
  void update(
    void Function(GetMe200ResponseCrewAssignmentsInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  GetMe200ResponseCrewAssignmentsInner build() => _build();

  _$GetMe200ResponseCrewAssignmentsInner _build() {
    final _$result =
        _$v ??
        _$GetMe200ResponseCrewAssignmentsInner._(
          shiftId: BuiltValueNullFieldError.checkNotNull(
            shiftId,
            r'GetMe200ResponseCrewAssignmentsInner',
            'shiftId',
          ),
          vehicleId: BuiltValueNullFieldError.checkNotNull(
            vehicleId,
            r'GetMe200ResponseCrewAssignmentsInner',
            'vehicleId',
          ),
          function_: BuiltValueNullFieldError.checkNotNull(
            function_,
            r'GetMe200ResponseCrewAssignmentsInner',
            'function_',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
