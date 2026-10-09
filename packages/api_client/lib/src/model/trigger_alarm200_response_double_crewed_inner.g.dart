// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trigger_alarm200_response_double_crewed_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TriggerAlarm200ResponseDoubleCrewedInner
    extends TriggerAlarm200ResponseDoubleCrewedInner {
  @override
  final String personId;
  @override
  final String displayName;
  @override
  final BuiltList<String> vehicleIds;

  factory _$TriggerAlarm200ResponseDoubleCrewedInner([
    void Function(TriggerAlarm200ResponseDoubleCrewedInnerBuilder)? updates,
  ]) => (TriggerAlarm200ResponseDoubleCrewedInnerBuilder()..update(updates))
      ._build();

  _$TriggerAlarm200ResponseDoubleCrewedInner._({
    required this.personId,
    required this.displayName,
    required this.vehicleIds,
  }) : super._();
  @override
  TriggerAlarm200ResponseDoubleCrewedInner rebuild(
    void Function(TriggerAlarm200ResponseDoubleCrewedInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  TriggerAlarm200ResponseDoubleCrewedInnerBuilder toBuilder() =>
      TriggerAlarm200ResponseDoubleCrewedInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TriggerAlarm200ResponseDoubleCrewedInner &&
        personId == other.personId &&
        displayName == other.displayName &&
        vehicleIds == other.vehicleIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, vehicleIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'TriggerAlarm200ResponseDoubleCrewedInner',
          )
          ..add('personId', personId)
          ..add('displayName', displayName)
          ..add('vehicleIds', vehicleIds))
        .toString();
  }
}

class TriggerAlarm200ResponseDoubleCrewedInnerBuilder
    implements
        Builder<
          TriggerAlarm200ResponseDoubleCrewedInner,
          TriggerAlarm200ResponseDoubleCrewedInnerBuilder
        > {
  _$TriggerAlarm200ResponseDoubleCrewedInner? _$v;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(String? personId) => _$this._personId = personId;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  ListBuilder<String>? _vehicleIds;
  ListBuilder<String> get vehicleIds =>
      _$this._vehicleIds ??= ListBuilder<String>();
  set vehicleIds(ListBuilder<String>? vehicleIds) =>
      _$this._vehicleIds = vehicleIds;

  TriggerAlarm200ResponseDoubleCrewedInnerBuilder() {
    TriggerAlarm200ResponseDoubleCrewedInner._defaults(this);
  }

  TriggerAlarm200ResponseDoubleCrewedInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _personId = $v.personId;
      _displayName = $v.displayName;
      _vehicleIds = $v.vehicleIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TriggerAlarm200ResponseDoubleCrewedInner other) {
    _$v = other as _$TriggerAlarm200ResponseDoubleCrewedInner;
  }

  @override
  void update(
    void Function(TriggerAlarm200ResponseDoubleCrewedInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  TriggerAlarm200ResponseDoubleCrewedInner build() => _build();

  _$TriggerAlarm200ResponseDoubleCrewedInner _build() {
    _$TriggerAlarm200ResponseDoubleCrewedInner _$result;
    try {
      _$result =
          _$v ??
          _$TriggerAlarm200ResponseDoubleCrewedInner._(
            personId: BuiltValueNullFieldError.checkNotNull(
              personId,
              r'TriggerAlarm200ResponseDoubleCrewedInner',
              'personId',
            ),
            displayName: BuiltValueNullFieldError.checkNotNull(
              displayName,
              r'TriggerAlarm200ResponseDoubleCrewedInner',
              'displayName',
            ),
            vehicleIds: vehicleIds.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'vehicleIds';
        vehicleIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'TriggerAlarm200ResponseDoubleCrewedInner',
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
