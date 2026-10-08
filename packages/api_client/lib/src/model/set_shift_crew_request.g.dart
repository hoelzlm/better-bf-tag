// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_shift_crew_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SetShiftCrewRequest extends SetShiftCrewRequest {
  @override
  final BuiltList<SetShiftCrewRequestAssignmentsInner> assignments;

  factory _$SetShiftCrewRequest([
    void Function(SetShiftCrewRequestBuilder)? updates,
  ]) => (SetShiftCrewRequestBuilder()..update(updates))._build();

  _$SetShiftCrewRequest._({required this.assignments}) : super._();
  @override
  SetShiftCrewRequest rebuild(
    void Function(SetShiftCrewRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  SetShiftCrewRequestBuilder toBuilder() =>
      SetShiftCrewRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SetShiftCrewRequest && assignments == other.assignments;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, assignments.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'SetShiftCrewRequest',
    )..add('assignments', assignments)).toString();
  }
}

class SetShiftCrewRequestBuilder
    implements Builder<SetShiftCrewRequest, SetShiftCrewRequestBuilder> {
  _$SetShiftCrewRequest? _$v;

  ListBuilder<SetShiftCrewRequestAssignmentsInner>? _assignments;
  ListBuilder<SetShiftCrewRequestAssignmentsInner> get assignments =>
      _$this._assignments ??=
          ListBuilder<SetShiftCrewRequestAssignmentsInner>();
  set assignments(
    ListBuilder<SetShiftCrewRequestAssignmentsInner>? assignments,
  ) => _$this._assignments = assignments;

  SetShiftCrewRequestBuilder() {
    SetShiftCrewRequest._defaults(this);
  }

  SetShiftCrewRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _assignments = $v.assignments.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SetShiftCrewRequest other) {
    _$v = other as _$SetShiftCrewRequest;
  }

  @override
  void update(void Function(SetShiftCrewRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SetShiftCrewRequest build() => _build();

  _$SetShiftCrewRequest _build() {
    _$SetShiftCrewRequest _$result;
    try {
      _$result =
          _$v ?? _$SetShiftCrewRequest._(assignments: assignments.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'assignments';
        assignments.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'SetShiftCrewRequest',
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
