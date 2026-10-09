// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'close_incident200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CloseIncident200Response extends CloseIncident200Response {
  @override
  final GetSnapshot200ResponseIncidentsInner incident;
  @override
  final BuiltList<String> discardedAlarmIds;

  factory _$CloseIncident200Response([
    void Function(CloseIncident200ResponseBuilder)? updates,
  ]) => (CloseIncident200ResponseBuilder()..update(updates))._build();

  _$CloseIncident200Response._({
    required this.incident,
    required this.discardedAlarmIds,
  }) : super._();
  @override
  CloseIncident200Response rebuild(
    void Function(CloseIncident200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CloseIncident200ResponseBuilder toBuilder() =>
      CloseIncident200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CloseIncident200Response &&
        incident == other.incident &&
        discardedAlarmIds == other.discardedAlarmIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, incident.hashCode);
    _$hash = $jc(_$hash, discardedAlarmIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CloseIncident200Response')
          ..add('incident', incident)
          ..add('discardedAlarmIds', discardedAlarmIds))
        .toString();
  }
}

class CloseIncident200ResponseBuilder
    implements
        Builder<CloseIncident200Response, CloseIncident200ResponseBuilder> {
  _$CloseIncident200Response? _$v;

  GetSnapshot200ResponseIncidentsInnerBuilder? _incident;
  GetSnapshot200ResponseIncidentsInnerBuilder get incident =>
      _$this._incident ??= GetSnapshot200ResponseIncidentsInnerBuilder();
  set incident(GetSnapshot200ResponseIncidentsInnerBuilder? incident) =>
      _$this._incident = incident;

  ListBuilder<String>? _discardedAlarmIds;
  ListBuilder<String> get discardedAlarmIds =>
      _$this._discardedAlarmIds ??= ListBuilder<String>();
  set discardedAlarmIds(ListBuilder<String>? discardedAlarmIds) =>
      _$this._discardedAlarmIds = discardedAlarmIds;

  CloseIncident200ResponseBuilder() {
    CloseIncident200Response._defaults(this);
  }

  CloseIncident200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _incident = $v.incident.toBuilder();
      _discardedAlarmIds = $v.discardedAlarmIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CloseIncident200Response other) {
    _$v = other as _$CloseIncident200Response;
  }

  @override
  void update(void Function(CloseIncident200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CloseIncident200Response build() => _build();

  _$CloseIncident200Response _build() {
    _$CloseIncident200Response _$result;
    try {
      _$result =
          _$v ??
          _$CloseIncident200Response._(
            incident: incident.build(),
            discardedAlarmIds: discardedAlarmIds.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'incident';
        incident.build();
        _$failedField = 'discardedAlarmIds';
        discardedAlarmIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'CloseIncident200Response',
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
