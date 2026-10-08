// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_vehicles200_response_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ListVehicles200ResponseInner extends ListVehicles200ResponseInner {
  @override
  final String id;
  @override
  final String callSign;
  @override
  final String shortName;
  @override
  final String type;
  @override
  final int status;
  @override
  final String? statusChangedAt;
  @override
  final int sortOrder;
  @override
  final bool active;

  factory _$ListVehicles200ResponseInner([
    void Function(ListVehicles200ResponseInnerBuilder)? updates,
  ]) => (ListVehicles200ResponseInnerBuilder()..update(updates))._build();

  _$ListVehicles200ResponseInner._({
    required this.id,
    required this.callSign,
    required this.shortName,
    required this.type,
    required this.status,
    this.statusChangedAt,
    required this.sortOrder,
    required this.active,
  }) : super._();
  @override
  ListVehicles200ResponseInner rebuild(
    void Function(ListVehicles200ResponseInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ListVehicles200ResponseInnerBuilder toBuilder() =>
      ListVehicles200ResponseInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ListVehicles200ResponseInner &&
        id == other.id &&
        callSign == other.callSign &&
        shortName == other.shortName &&
        type == other.type &&
        status == other.status &&
        statusChangedAt == other.statusChangedAt &&
        sortOrder == other.sortOrder &&
        active == other.active;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, callSign.hashCode);
    _$hash = $jc(_$hash, shortName.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, statusChangedAt.hashCode);
    _$hash = $jc(_$hash, sortOrder.hashCode);
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ListVehicles200ResponseInner')
          ..add('id', id)
          ..add('callSign', callSign)
          ..add('shortName', shortName)
          ..add('type', type)
          ..add('status', status)
          ..add('statusChangedAt', statusChangedAt)
          ..add('sortOrder', sortOrder)
          ..add('active', active))
        .toString();
  }
}

class ListVehicles200ResponseInnerBuilder
    implements
        Builder<
          ListVehicles200ResponseInner,
          ListVehicles200ResponseInnerBuilder
        > {
  _$ListVehicles200ResponseInner? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _callSign;
  String? get callSign => _$this._callSign;
  set callSign(String? callSign) => _$this._callSign = callSign;

  String? _shortName;
  String? get shortName => _$this._shortName;
  set shortName(String? shortName) => _$this._shortName = shortName;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  int? _status;
  int? get status => _$this._status;
  set status(int? status) => _$this._status = status;

  String? _statusChangedAt;
  String? get statusChangedAt => _$this._statusChangedAt;
  set statusChangedAt(String? statusChangedAt) =>
      _$this._statusChangedAt = statusChangedAt;

  int? _sortOrder;
  int? get sortOrder => _$this._sortOrder;
  set sortOrder(int? sortOrder) => _$this._sortOrder = sortOrder;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  ListVehicles200ResponseInnerBuilder() {
    ListVehicles200ResponseInner._defaults(this);
  }

  ListVehicles200ResponseInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _callSign = $v.callSign;
      _shortName = $v.shortName;
      _type = $v.type;
      _status = $v.status;
      _statusChangedAt = $v.statusChangedAt;
      _sortOrder = $v.sortOrder;
      _active = $v.active;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ListVehicles200ResponseInner other) {
    _$v = other as _$ListVehicles200ResponseInner;
  }

  @override
  void update(void Function(ListVehicles200ResponseInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ListVehicles200ResponseInner build() => _build();

  _$ListVehicles200ResponseInner _build() {
    final _$result =
        _$v ??
        _$ListVehicles200ResponseInner._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'ListVehicles200ResponseInner',
            'id',
          ),
          callSign: BuiltValueNullFieldError.checkNotNull(
            callSign,
            r'ListVehicles200ResponseInner',
            'callSign',
          ),
          shortName: BuiltValueNullFieldError.checkNotNull(
            shortName,
            r'ListVehicles200ResponseInner',
            'shortName',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'ListVehicles200ResponseInner',
            'type',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'ListVehicles200ResponseInner',
            'status',
          ),
          statusChangedAt: statusChangedAt,
          sortOrder: BuiltValueNullFieldError.checkNotNull(
            sortOrder,
            r'ListVehicles200ResponseInner',
            'sortOrder',
          ),
          active: BuiltValueNullFieldError.checkNotNull(
            active,
            r'ListVehicles200ResponseInner',
            'active',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
