// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_snapshot200_response_alarms_inner_recipients_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GetSnapshot200ResponseAlarmsInnerRecipientsInner
    extends GetSnapshot200ResponseAlarmsInnerRecipientsInner {
  @override
  final String personId;
  @override
  final String displayName;
  @override
  final String vehicleId;
  @override
  final String function_;
  @override
  final bool hasDevice;
  @override
  final String? acknowledgedAt;

  factory _$GetSnapshot200ResponseAlarmsInnerRecipientsInner([
    void Function(GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder)?
    updates,
  ]) =>
      (GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder()
            ..update(updates))
          ._build();

  _$GetSnapshot200ResponseAlarmsInnerRecipientsInner._({
    required this.personId,
    required this.displayName,
    required this.vehicleId,
    required this.function_,
    required this.hasDevice,
    this.acknowledgedAt,
  }) : super._();
  @override
  GetSnapshot200ResponseAlarmsInnerRecipientsInner rebuild(
    void Function(GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder)
    updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder toBuilder() =>
      GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetSnapshot200ResponseAlarmsInnerRecipientsInner &&
        personId == other.personId &&
        displayName == other.displayName &&
        vehicleId == other.vehicleId &&
        function_ == other.function_ &&
        hasDevice == other.hasDevice &&
        acknowledgedAt == other.acknowledgedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, vehicleId.hashCode);
    _$hash = $jc(_$hash, function_.hashCode);
    _$hash = $jc(_$hash, hasDevice.hashCode);
    _$hash = $jc(_$hash, acknowledgedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'GetSnapshot200ResponseAlarmsInnerRecipientsInner',
          )
          ..add('personId', personId)
          ..add('displayName', displayName)
          ..add('vehicleId', vehicleId)
          ..add('function_', function_)
          ..add('hasDevice', hasDevice)
          ..add('acknowledgedAt', acknowledgedAt))
        .toString();
  }
}

class GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder
    implements
        Builder<
          GetSnapshot200ResponseAlarmsInnerRecipientsInner,
          GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder
        > {
  _$GetSnapshot200ResponseAlarmsInnerRecipientsInner? _$v;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(String? personId) => _$this._personId = personId;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  String? _vehicleId;
  String? get vehicleId => _$this._vehicleId;
  set vehicleId(String? vehicleId) => _$this._vehicleId = vehicleId;

  String? _function_;
  String? get function_ => _$this._function_;
  set function_(String? function_) => _$this._function_ = function_;

  bool? _hasDevice;
  bool? get hasDevice => _$this._hasDevice;
  set hasDevice(bool? hasDevice) => _$this._hasDevice = hasDevice;

  String? _acknowledgedAt;
  String? get acknowledgedAt => _$this._acknowledgedAt;
  set acknowledgedAt(String? acknowledgedAt) =>
      _$this._acknowledgedAt = acknowledgedAt;

  GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder() {
    GetSnapshot200ResponseAlarmsInnerRecipientsInner._defaults(this);
  }

  GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _personId = $v.personId;
      _displayName = $v.displayName;
      _vehicleId = $v.vehicleId;
      _function_ = $v.function_;
      _hasDevice = $v.hasDevice;
      _acknowledgedAt = $v.acknowledgedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetSnapshot200ResponseAlarmsInnerRecipientsInner other) {
    _$v = other as _$GetSnapshot200ResponseAlarmsInnerRecipientsInner;
  }

  @override
  void update(
    void Function(GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder)?
    updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  GetSnapshot200ResponseAlarmsInnerRecipientsInner build() => _build();

  _$GetSnapshot200ResponseAlarmsInnerRecipientsInner _build() {
    final _$result =
        _$v ??
        _$GetSnapshot200ResponseAlarmsInnerRecipientsInner._(
          personId: BuiltValueNullFieldError.checkNotNull(
            personId,
            r'GetSnapshot200ResponseAlarmsInnerRecipientsInner',
            'personId',
          ),
          displayName: BuiltValueNullFieldError.checkNotNull(
            displayName,
            r'GetSnapshot200ResponseAlarmsInnerRecipientsInner',
            'displayName',
          ),
          vehicleId: BuiltValueNullFieldError.checkNotNull(
            vehicleId,
            r'GetSnapshot200ResponseAlarmsInnerRecipientsInner',
            'vehicleId',
          ),
          function_: BuiltValueNullFieldError.checkNotNull(
            function_,
            r'GetSnapshot200ResponseAlarmsInnerRecipientsInner',
            'function_',
          ),
          hasDevice: BuiltValueNullFieldError.checkNotNull(
            hasDevice,
            r'GetSnapshot200ResponseAlarmsInnerRecipientsInner',
            'hasDevice',
          ),
          acknowledgedAt: acknowledgedAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
