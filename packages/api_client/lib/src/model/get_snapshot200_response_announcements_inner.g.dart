// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_snapshot200_response_announcements_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GetSnapshot200ResponseAnnouncementsInner
    extends GetSnapshot200ResponseAnnouncementsInner {
  @override
  final String id;
  @override
  final String bfDayId;
  @override
  final String? shiftId;
  @override
  final String text;
  @override
  final String createdBy;
  @override
  final String createdAt;

  factory _$GetSnapshot200ResponseAnnouncementsInner([
    void Function(GetSnapshot200ResponseAnnouncementsInnerBuilder)? updates,
  ]) => (GetSnapshot200ResponseAnnouncementsInnerBuilder()..update(updates))
      ._build();

  _$GetSnapshot200ResponseAnnouncementsInner._({
    required this.id,
    required this.bfDayId,
    this.shiftId,
    required this.text,
    required this.createdBy,
    required this.createdAt,
  }) : super._();
  @override
  GetSnapshot200ResponseAnnouncementsInner rebuild(
    void Function(GetSnapshot200ResponseAnnouncementsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetSnapshot200ResponseAnnouncementsInnerBuilder toBuilder() =>
      GetSnapshot200ResponseAnnouncementsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetSnapshot200ResponseAnnouncementsInner &&
        id == other.id &&
        bfDayId == other.bfDayId &&
        shiftId == other.shiftId &&
        text == other.text &&
        createdBy == other.createdBy &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, bfDayId.hashCode);
    _$hash = $jc(_$hash, shiftId.hashCode);
    _$hash = $jc(_$hash, text.hashCode);
    _$hash = $jc(_$hash, createdBy.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'GetSnapshot200ResponseAnnouncementsInner',
          )
          ..add('id', id)
          ..add('bfDayId', bfDayId)
          ..add('shiftId', shiftId)
          ..add('text', text)
          ..add('createdBy', createdBy)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class GetSnapshot200ResponseAnnouncementsInnerBuilder
    implements
        Builder<
          GetSnapshot200ResponseAnnouncementsInner,
          GetSnapshot200ResponseAnnouncementsInnerBuilder
        > {
  _$GetSnapshot200ResponseAnnouncementsInner? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _bfDayId;
  String? get bfDayId => _$this._bfDayId;
  set bfDayId(String? bfDayId) => _$this._bfDayId = bfDayId;

  String? _shiftId;
  String? get shiftId => _$this._shiftId;
  set shiftId(String? shiftId) => _$this._shiftId = shiftId;

  String? _text;
  String? get text => _$this._text;
  set text(String? text) => _$this._text = text;

  String? _createdBy;
  String? get createdBy => _$this._createdBy;
  set createdBy(String? createdBy) => _$this._createdBy = createdBy;

  String? _createdAt;
  String? get createdAt => _$this._createdAt;
  set createdAt(String? createdAt) => _$this._createdAt = createdAt;

  GetSnapshot200ResponseAnnouncementsInnerBuilder() {
    GetSnapshot200ResponseAnnouncementsInner._defaults(this);
  }

  GetSnapshot200ResponseAnnouncementsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _bfDayId = $v.bfDayId;
      _shiftId = $v.shiftId;
      _text = $v.text;
      _createdBy = $v.createdBy;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetSnapshot200ResponseAnnouncementsInner other) {
    _$v = other as _$GetSnapshot200ResponseAnnouncementsInner;
  }

  @override
  void update(
    void Function(GetSnapshot200ResponseAnnouncementsInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  GetSnapshot200ResponseAnnouncementsInner build() => _build();

  _$GetSnapshot200ResponseAnnouncementsInner _build() {
    final _$result =
        _$v ??
        _$GetSnapshot200ResponseAnnouncementsInner._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'GetSnapshot200ResponseAnnouncementsInner',
            'id',
          ),
          bfDayId: BuiltValueNullFieldError.checkNotNull(
            bfDayId,
            r'GetSnapshot200ResponseAnnouncementsInner',
            'bfDayId',
          ),
          shiftId: shiftId,
          text: BuiltValueNullFieldError.checkNotNull(
            text,
            r'GetSnapshot200ResponseAnnouncementsInner',
            'text',
          ),
          createdBy: BuiltValueNullFieldError.checkNotNull(
            createdBy,
            r'GetSnapshot200ResponseAnnouncementsInner',
            'createdBy',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'GetSnapshot200ResponseAnnouncementsInner',
            'createdAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
