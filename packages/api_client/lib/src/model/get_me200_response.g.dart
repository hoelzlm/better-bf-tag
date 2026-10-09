// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_me200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GetMe200Response extends GetMe200Response {
  @override
  final Login200ResponsePerson person;
  @override
  final BuiltList<GetMe200ResponseCrewAssignmentsInner> crewAssignments;

  factory _$GetMe200Response([
    void Function(GetMe200ResponseBuilder)? updates,
  ]) => (GetMe200ResponseBuilder()..update(updates))._build();

  _$GetMe200Response._({required this.person, required this.crewAssignments})
    : super._();
  @override
  GetMe200Response rebuild(void Function(GetMe200ResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GetMe200ResponseBuilder toBuilder() =>
      GetMe200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetMe200Response &&
        person == other.person &&
        crewAssignments == other.crewAssignments;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, person.hashCode);
    _$hash = $jc(_$hash, crewAssignments.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GetMe200Response')
          ..add('person', person)
          ..add('crewAssignments', crewAssignments))
        .toString();
  }
}

class GetMe200ResponseBuilder
    implements Builder<GetMe200Response, GetMe200ResponseBuilder> {
  _$GetMe200Response? _$v;

  Login200ResponsePersonBuilder? _person;
  Login200ResponsePersonBuilder get person =>
      _$this._person ??= Login200ResponsePersonBuilder();
  set person(Login200ResponsePersonBuilder? person) => _$this._person = person;

  ListBuilder<GetMe200ResponseCrewAssignmentsInner>? _crewAssignments;
  ListBuilder<GetMe200ResponseCrewAssignmentsInner> get crewAssignments =>
      _$this._crewAssignments ??=
          ListBuilder<GetMe200ResponseCrewAssignmentsInner>();
  set crewAssignments(
    ListBuilder<GetMe200ResponseCrewAssignmentsInner>? crewAssignments,
  ) => _$this._crewAssignments = crewAssignments;

  GetMe200ResponseBuilder() {
    GetMe200Response._defaults(this);
  }

  GetMe200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _person = $v.person.toBuilder();
      _crewAssignments = $v.crewAssignments.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetMe200Response other) {
    _$v = other as _$GetMe200Response;
  }

  @override
  void update(void Function(GetMe200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GetMe200Response build() => _build();

  _$GetMe200Response _build() {
    _$GetMe200Response _$result;
    try {
      _$result =
          _$v ??
          _$GetMe200Response._(
            person: person.build(),
            crewAssignments: crewAssignments.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'person';
        person.build();
        _$failedField = 'crewAssignments';
        crewAssignments.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'GetMe200Response',
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
