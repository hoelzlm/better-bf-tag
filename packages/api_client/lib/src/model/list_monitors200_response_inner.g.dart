// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_monitors200_response_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ListMonitors200ResponseInner extends ListMonitors200ResponseInner {
  @override
  final String id;
  @override
  final String name;
  @override
  final bool paired;
  @override
  final String? pairedAt;
  @override
  final String? lastSeenAt;
  @override
  final String? revokedAt;
  @override
  final String createdAt;

  factory _$ListMonitors200ResponseInner([
    void Function(ListMonitors200ResponseInnerBuilder)? updates,
  ]) => (ListMonitors200ResponseInnerBuilder()..update(updates))._build();

  _$ListMonitors200ResponseInner._({
    required this.id,
    required this.name,
    required this.paired,
    this.pairedAt,
    this.lastSeenAt,
    this.revokedAt,
    required this.createdAt,
  }) : super._();
  @override
  ListMonitors200ResponseInner rebuild(
    void Function(ListMonitors200ResponseInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ListMonitors200ResponseInnerBuilder toBuilder() =>
      ListMonitors200ResponseInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ListMonitors200ResponseInner &&
        id == other.id &&
        name == other.name &&
        paired == other.paired &&
        pairedAt == other.pairedAt &&
        lastSeenAt == other.lastSeenAt &&
        revokedAt == other.revokedAt &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, paired.hashCode);
    _$hash = $jc(_$hash, pairedAt.hashCode);
    _$hash = $jc(_$hash, lastSeenAt.hashCode);
    _$hash = $jc(_$hash, revokedAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ListMonitors200ResponseInner')
          ..add('id', id)
          ..add('name', name)
          ..add('paired', paired)
          ..add('pairedAt', pairedAt)
          ..add('lastSeenAt', lastSeenAt)
          ..add('revokedAt', revokedAt)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class ListMonitors200ResponseInnerBuilder
    implements
        Builder<
          ListMonitors200ResponseInner,
          ListMonitors200ResponseInnerBuilder
        > {
  _$ListMonitors200ResponseInner? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  bool? _paired;
  bool? get paired => _$this._paired;
  set paired(bool? paired) => _$this._paired = paired;

  String? _pairedAt;
  String? get pairedAt => _$this._pairedAt;
  set pairedAt(String? pairedAt) => _$this._pairedAt = pairedAt;

  String? _lastSeenAt;
  String? get lastSeenAt => _$this._lastSeenAt;
  set lastSeenAt(String? lastSeenAt) => _$this._lastSeenAt = lastSeenAt;

  String? _revokedAt;
  String? get revokedAt => _$this._revokedAt;
  set revokedAt(String? revokedAt) => _$this._revokedAt = revokedAt;

  String? _createdAt;
  String? get createdAt => _$this._createdAt;
  set createdAt(String? createdAt) => _$this._createdAt = createdAt;

  ListMonitors200ResponseInnerBuilder() {
    ListMonitors200ResponseInner._defaults(this);
  }

  ListMonitors200ResponseInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _paired = $v.paired;
      _pairedAt = $v.pairedAt;
      _lastSeenAt = $v.lastSeenAt;
      _revokedAt = $v.revokedAt;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ListMonitors200ResponseInner other) {
    _$v = other as _$ListMonitors200ResponseInner;
  }

  @override
  void update(void Function(ListMonitors200ResponseInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ListMonitors200ResponseInner build() => _build();

  _$ListMonitors200ResponseInner _build() {
    final _$result =
        _$v ??
        _$ListMonitors200ResponseInner._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'ListMonitors200ResponseInner',
            'id',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'ListMonitors200ResponseInner',
            'name',
          ),
          paired: BuiltValueNullFieldError.checkNotNull(
            paired,
            r'ListMonitors200ResponseInner',
            'paired',
          ),
          pairedAt: pairedAt,
          lastSeenAt: lastSeenAt,
          revokedAt: revokedAt,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'ListMonitors200ResponseInner',
            'createdAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
