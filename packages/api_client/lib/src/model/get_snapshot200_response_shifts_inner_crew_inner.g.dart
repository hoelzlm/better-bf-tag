// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_snapshot200_response_shifts_inner_crew_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GetSnapshot200ResponseShiftsInnerCrewInner
    extends GetSnapshot200ResponseShiftsInnerCrewInner {
  @override
  final String vehicleId;
  @override
  final String personId;
  @override
  final String displayName;
  @override
  final String function_;

  factory _$GetSnapshot200ResponseShiftsInnerCrewInner([
    void Function(GetSnapshot200ResponseShiftsInnerCrewInnerBuilder)? updates,
  ]) => (GetSnapshot200ResponseShiftsInnerCrewInnerBuilder()..update(updates))
      ._build();

  _$GetSnapshot200ResponseShiftsInnerCrewInner._({
    required this.vehicleId,
    required this.personId,
    required this.displayName,
    required this.function_,
  }) : super._();
  @override
  GetSnapshot200ResponseShiftsInnerCrewInner rebuild(
    void Function(GetSnapshot200ResponseShiftsInnerCrewInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetSnapshot200ResponseShiftsInnerCrewInnerBuilder toBuilder() =>
      GetSnapshot200ResponseShiftsInnerCrewInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetSnapshot200ResponseShiftsInnerCrewInner &&
        vehicleId == other.vehicleId &&
        personId == other.personId &&
        displayName == other.displayName &&
        function_ == other.function_;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, vehicleId.hashCode);
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, function_.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'GetSnapshot200ResponseShiftsInnerCrewInner',
          )
          ..add('vehicleId', vehicleId)
          ..add('personId', personId)
          ..add('displayName', displayName)
          ..add('function_', function_))
        .toString();
  }
}

class GetSnapshot200ResponseShiftsInnerCrewInnerBuilder
    implements
        Builder<
          GetSnapshot200ResponseShiftsInnerCrewInner,
          GetSnapshot200ResponseShiftsInnerCrewInnerBuilder
        > {
  _$GetSnapshot200ResponseShiftsInnerCrewInner? _$v;

  String? _vehicleId;
  String? get vehicleId => _$this._vehicleId;
  set vehicleId(String? vehicleId) => _$this._vehicleId = vehicleId;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(String? personId) => _$this._personId = personId;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  String? _function_;
  String? get function_ => _$this._function_;
  set function_(String? function_) => _$this._function_ = function_;

  GetSnapshot200ResponseShiftsInnerCrewInnerBuilder() {
    GetSnapshot200ResponseShiftsInnerCrewInner._defaults(this);
  }

  GetSnapshot200ResponseShiftsInnerCrewInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _vehicleId = $v.vehicleId;
      _personId = $v.personId;
      _displayName = $v.displayName;
      _function_ = $v.function_;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetSnapshot200ResponseShiftsInnerCrewInner other) {
    _$v = other as _$GetSnapshot200ResponseShiftsInnerCrewInner;
  }

  @override
  void update(
    void Function(GetSnapshot200ResponseShiftsInnerCrewInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  GetSnapshot200ResponseShiftsInnerCrewInner build() => _build();

  _$GetSnapshot200ResponseShiftsInnerCrewInner _build() {
    final _$result =
        _$v ??
        _$GetSnapshot200ResponseShiftsInnerCrewInner._(
          vehicleId: BuiltValueNullFieldError.checkNotNull(
            vehicleId,
            r'GetSnapshot200ResponseShiftsInnerCrewInner',
            'vehicleId',
          ),
          personId: BuiltValueNullFieldError.checkNotNull(
            personId,
            r'GetSnapshot200ResponseShiftsInnerCrewInner',
            'personId',
          ),
          displayName: BuiltValueNullFieldError.checkNotNull(
            displayName,
            r'GetSnapshot200ResponseShiftsInnerCrewInner',
            'displayName',
          ),
          function_: BuiltValueNullFieldError.checkNotNull(
            function_,
            r'GetSnapshot200ResponseShiftsInnerCrewInner',
            'function_',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
