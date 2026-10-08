// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_shift_crew_request_assignments_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SetShiftCrewRequestAssignmentsInner
    extends SetShiftCrewRequestAssignmentsInner {
  @override
  final String vehicleId;
  @override
  final String personId;
  @override
  final String function_;

  factory _$SetShiftCrewRequestAssignmentsInner([
    void Function(SetShiftCrewRequestAssignmentsInnerBuilder)? updates,
  ]) =>
      (SetShiftCrewRequestAssignmentsInnerBuilder()..update(updates))._build();

  _$SetShiftCrewRequestAssignmentsInner._({
    required this.vehicleId,
    required this.personId,
    required this.function_,
  }) : super._();
  @override
  SetShiftCrewRequestAssignmentsInner rebuild(
    void Function(SetShiftCrewRequestAssignmentsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  SetShiftCrewRequestAssignmentsInnerBuilder toBuilder() =>
      SetShiftCrewRequestAssignmentsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SetShiftCrewRequestAssignmentsInner &&
        vehicleId == other.vehicleId &&
        personId == other.personId &&
        function_ == other.function_;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, vehicleId.hashCode);
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, function_.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SetShiftCrewRequestAssignmentsInner')
          ..add('vehicleId', vehicleId)
          ..add('personId', personId)
          ..add('function_', function_))
        .toString();
  }
}

class SetShiftCrewRequestAssignmentsInnerBuilder
    implements
        Builder<
          SetShiftCrewRequestAssignmentsInner,
          SetShiftCrewRequestAssignmentsInnerBuilder
        > {
  _$SetShiftCrewRequestAssignmentsInner? _$v;

  String? _vehicleId;
  String? get vehicleId => _$this._vehicleId;
  set vehicleId(String? vehicleId) => _$this._vehicleId = vehicleId;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(String? personId) => _$this._personId = personId;

  String? _function_;
  String? get function_ => _$this._function_;
  set function_(String? function_) => _$this._function_ = function_;

  SetShiftCrewRequestAssignmentsInnerBuilder() {
    SetShiftCrewRequestAssignmentsInner._defaults(this);
  }

  SetShiftCrewRequestAssignmentsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _vehicleId = $v.vehicleId;
      _personId = $v.personId;
      _function_ = $v.function_;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SetShiftCrewRequestAssignmentsInner other) {
    _$v = other as _$SetShiftCrewRequestAssignmentsInner;
  }

  @override
  void update(
    void Function(SetShiftCrewRequestAssignmentsInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  SetShiftCrewRequestAssignmentsInner build() => _build();

  _$SetShiftCrewRequestAssignmentsInner _build() {
    final _$result =
        _$v ??
        _$SetShiftCrewRequestAssignmentsInner._(
          vehicleId: BuiltValueNullFieldError.checkNotNull(
            vehicleId,
            r'SetShiftCrewRequestAssignmentsInner',
            'vehicleId',
          ),
          personId: BuiltValueNullFieldError.checkNotNull(
            personId,
            r'SetShiftCrewRequestAssignmentsInner',
            'personId',
          ),
          function_: BuiltValueNullFieldError.checkNotNull(
            function_,
            r'SetShiftCrewRequestAssignmentsInner',
            'function_',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
