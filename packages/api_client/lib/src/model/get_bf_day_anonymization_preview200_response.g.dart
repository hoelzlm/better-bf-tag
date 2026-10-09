// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_bf_day_anonymization_preview200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GetBfDayAnonymizationPreview200Response
    extends GetBfDayAnonymizationPreview200Response {
  @override
  final int participations;
  @override
  final int crewAssignments;
  @override
  final int alarmRecipients;
  @override
  final int statusEvents;
  @override
  final int personsDeleted;

  factory _$GetBfDayAnonymizationPreview200Response([
    void Function(GetBfDayAnonymizationPreview200ResponseBuilder)? updates,
  ]) => (GetBfDayAnonymizationPreview200ResponseBuilder()..update(updates))
      ._build();

  _$GetBfDayAnonymizationPreview200Response._({
    required this.participations,
    required this.crewAssignments,
    required this.alarmRecipients,
    required this.statusEvents,
    required this.personsDeleted,
  }) : super._();
  @override
  GetBfDayAnonymizationPreview200Response rebuild(
    void Function(GetBfDayAnonymizationPreview200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetBfDayAnonymizationPreview200ResponseBuilder toBuilder() =>
      GetBfDayAnonymizationPreview200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetBfDayAnonymizationPreview200Response &&
        participations == other.participations &&
        crewAssignments == other.crewAssignments &&
        alarmRecipients == other.alarmRecipients &&
        statusEvents == other.statusEvents &&
        personsDeleted == other.personsDeleted;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, participations.hashCode);
    _$hash = $jc(_$hash, crewAssignments.hashCode);
    _$hash = $jc(_$hash, alarmRecipients.hashCode);
    _$hash = $jc(_$hash, statusEvents.hashCode);
    _$hash = $jc(_$hash, personsDeleted.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'GetBfDayAnonymizationPreview200Response',
          )
          ..add('participations', participations)
          ..add('crewAssignments', crewAssignments)
          ..add('alarmRecipients', alarmRecipients)
          ..add('statusEvents', statusEvents)
          ..add('personsDeleted', personsDeleted))
        .toString();
  }
}

class GetBfDayAnonymizationPreview200ResponseBuilder
    implements
        Builder<
          GetBfDayAnonymizationPreview200Response,
          GetBfDayAnonymizationPreview200ResponseBuilder
        > {
  _$GetBfDayAnonymizationPreview200Response? _$v;

  int? _participations;
  int? get participations => _$this._participations;
  set participations(int? participations) =>
      _$this._participations = participations;

  int? _crewAssignments;
  int? get crewAssignments => _$this._crewAssignments;
  set crewAssignments(int? crewAssignments) =>
      _$this._crewAssignments = crewAssignments;

  int? _alarmRecipients;
  int? get alarmRecipients => _$this._alarmRecipients;
  set alarmRecipients(int? alarmRecipients) =>
      _$this._alarmRecipients = alarmRecipients;

  int? _statusEvents;
  int? get statusEvents => _$this._statusEvents;
  set statusEvents(int? statusEvents) => _$this._statusEvents = statusEvents;

  int? _personsDeleted;
  int? get personsDeleted => _$this._personsDeleted;
  set personsDeleted(int? personsDeleted) =>
      _$this._personsDeleted = personsDeleted;

  GetBfDayAnonymizationPreview200ResponseBuilder() {
    GetBfDayAnonymizationPreview200Response._defaults(this);
  }

  GetBfDayAnonymizationPreview200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _participations = $v.participations;
      _crewAssignments = $v.crewAssignments;
      _alarmRecipients = $v.alarmRecipients;
      _statusEvents = $v.statusEvents;
      _personsDeleted = $v.personsDeleted;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetBfDayAnonymizationPreview200Response other) {
    _$v = other as _$GetBfDayAnonymizationPreview200Response;
  }

  @override
  void update(
    void Function(GetBfDayAnonymizationPreview200ResponseBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  GetBfDayAnonymizationPreview200Response build() => _build();

  _$GetBfDayAnonymizationPreview200Response _build() {
    final _$result =
        _$v ??
        _$GetBfDayAnonymizationPreview200Response._(
          participations: BuiltValueNullFieldError.checkNotNull(
            participations,
            r'GetBfDayAnonymizationPreview200Response',
            'participations',
          ),
          crewAssignments: BuiltValueNullFieldError.checkNotNull(
            crewAssignments,
            r'GetBfDayAnonymizationPreview200Response',
            'crewAssignments',
          ),
          alarmRecipients: BuiltValueNullFieldError.checkNotNull(
            alarmRecipients,
            r'GetBfDayAnonymizationPreview200Response',
            'alarmRecipients',
          ),
          statusEvents: BuiltValueNullFieldError.checkNotNull(
            statusEvents,
            r'GetBfDayAnonymizationPreview200Response',
            'statusEvents',
          ),
          personsDeleted: BuiltValueNullFieldError.checkNotNull(
            personsDeleted,
            r'GetBfDayAnonymizationPreview200Response',
            'personsDeleted',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
