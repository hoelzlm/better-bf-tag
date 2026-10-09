// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_snapshot200_response_shifts_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GetSnapshot200ResponseShiftsInner
    extends GetSnapshot200ResponseShiftsInner {
  @override
  final String id;
  @override
  final String bfDayId;
  @override
  final String name;
  @override
  final String startsAt;
  @override
  final String endsAt;
  @override
  final BuiltList<GetSnapshot200ResponseShiftsInnerCrewInner> crew;

  factory _$GetSnapshot200ResponseShiftsInner([
    void Function(GetSnapshot200ResponseShiftsInnerBuilder)? updates,
  ]) => (GetSnapshot200ResponseShiftsInnerBuilder()..update(updates))._build();

  _$GetSnapshot200ResponseShiftsInner._({
    required this.id,
    required this.bfDayId,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.crew,
  }) : super._();
  @override
  GetSnapshot200ResponseShiftsInner rebuild(
    void Function(GetSnapshot200ResponseShiftsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetSnapshot200ResponseShiftsInnerBuilder toBuilder() =>
      GetSnapshot200ResponseShiftsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetSnapshot200ResponseShiftsInner &&
        id == other.id &&
        bfDayId == other.bfDayId &&
        name == other.name &&
        startsAt == other.startsAt &&
        endsAt == other.endsAt &&
        crew == other.crew;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, bfDayId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, startsAt.hashCode);
    _$hash = $jc(_$hash, endsAt.hashCode);
    _$hash = $jc(_$hash, crew.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GetSnapshot200ResponseShiftsInner')
          ..add('id', id)
          ..add('bfDayId', bfDayId)
          ..add('name', name)
          ..add('startsAt', startsAt)
          ..add('endsAt', endsAt)
          ..add('crew', crew))
        .toString();
  }
}

class GetSnapshot200ResponseShiftsInnerBuilder
    implements
        Builder<
          GetSnapshot200ResponseShiftsInner,
          GetSnapshot200ResponseShiftsInnerBuilder
        > {
  _$GetSnapshot200ResponseShiftsInner? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _bfDayId;
  String? get bfDayId => _$this._bfDayId;
  set bfDayId(String? bfDayId) => _$this._bfDayId = bfDayId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _startsAt;
  String? get startsAt => _$this._startsAt;
  set startsAt(String? startsAt) => _$this._startsAt = startsAt;

  String? _endsAt;
  String? get endsAt => _$this._endsAt;
  set endsAt(String? endsAt) => _$this._endsAt = endsAt;

  ListBuilder<GetSnapshot200ResponseShiftsInnerCrewInner>? _crew;
  ListBuilder<GetSnapshot200ResponseShiftsInnerCrewInner> get crew =>
      _$this._crew ??=
          ListBuilder<GetSnapshot200ResponseShiftsInnerCrewInner>();
  set crew(ListBuilder<GetSnapshot200ResponseShiftsInnerCrewInner>? crew) =>
      _$this._crew = crew;

  GetSnapshot200ResponseShiftsInnerBuilder() {
    GetSnapshot200ResponseShiftsInner._defaults(this);
  }

  GetSnapshot200ResponseShiftsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _bfDayId = $v.bfDayId;
      _name = $v.name;
      _startsAt = $v.startsAt;
      _endsAt = $v.endsAt;
      _crew = $v.crew.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetSnapshot200ResponseShiftsInner other) {
    _$v = other as _$GetSnapshot200ResponseShiftsInner;
  }

  @override
  void update(
    void Function(GetSnapshot200ResponseShiftsInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  GetSnapshot200ResponseShiftsInner build() => _build();

  _$GetSnapshot200ResponseShiftsInner _build() {
    _$GetSnapshot200ResponseShiftsInner _$result;
    try {
      _$result =
          _$v ??
          _$GetSnapshot200ResponseShiftsInner._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'GetSnapshot200ResponseShiftsInner',
              'id',
            ),
            bfDayId: BuiltValueNullFieldError.checkNotNull(
              bfDayId,
              r'GetSnapshot200ResponseShiftsInner',
              'bfDayId',
            ),
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'GetSnapshot200ResponseShiftsInner',
              'name',
            ),
            startsAt: BuiltValueNullFieldError.checkNotNull(
              startsAt,
              r'GetSnapshot200ResponseShiftsInner',
              'startsAt',
            ),
            endsAt: BuiltValueNullFieldError.checkNotNull(
              endsAt,
              r'GetSnapshot200ResponseShiftsInner',
              'endsAt',
            ),
            crew: crew.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'crew';
        crew.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'GetSnapshot200ResponseShiftsInner',
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
