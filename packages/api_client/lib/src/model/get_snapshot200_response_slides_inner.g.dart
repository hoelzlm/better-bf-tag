// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_snapshot200_response_slides_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GetSnapshot200ResponseSlidesInner
    extends GetSnapshot200ResponseSlidesInner {
  @override
  final String id;
  @override
  final String title;
  @override
  final String body;
  @override
  final int durationSeconds;
  @override
  final int sortOrder;
  @override
  final bool active;
  @override
  final GetSnapshot200ResponseSlidesInnerImage? image;
  @override
  final String createdAt;
  @override
  final String updatedAt;

  factory _$GetSnapshot200ResponseSlidesInner([
    void Function(GetSnapshot200ResponseSlidesInnerBuilder)? updates,
  ]) => (GetSnapshot200ResponseSlidesInnerBuilder()..update(updates))._build();

  _$GetSnapshot200ResponseSlidesInner._({
    required this.id,
    required this.title,
    required this.body,
    required this.durationSeconds,
    required this.sortOrder,
    required this.active,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();
  @override
  GetSnapshot200ResponseSlidesInner rebuild(
    void Function(GetSnapshot200ResponseSlidesInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetSnapshot200ResponseSlidesInnerBuilder toBuilder() =>
      GetSnapshot200ResponseSlidesInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetSnapshot200ResponseSlidesInner &&
        id == other.id &&
        title == other.title &&
        body == other.body &&
        durationSeconds == other.durationSeconds &&
        sortOrder == other.sortOrder &&
        active == other.active &&
        image == other.image &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, body.hashCode);
    _$hash = $jc(_$hash, durationSeconds.hashCode);
    _$hash = $jc(_$hash, sortOrder.hashCode);
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jc(_$hash, image.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GetSnapshot200ResponseSlidesInner')
          ..add('id', id)
          ..add('title', title)
          ..add('body', body)
          ..add('durationSeconds', durationSeconds)
          ..add('sortOrder', sortOrder)
          ..add('active', active)
          ..add('image', image)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class GetSnapshot200ResponseSlidesInnerBuilder
    implements
        Builder<
          GetSnapshot200ResponseSlidesInner,
          GetSnapshot200ResponseSlidesInnerBuilder
        > {
  _$GetSnapshot200ResponseSlidesInner? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _body;
  String? get body => _$this._body;
  set body(String? body) => _$this._body = body;

  int? _durationSeconds;
  int? get durationSeconds => _$this._durationSeconds;
  set durationSeconds(int? durationSeconds) =>
      _$this._durationSeconds = durationSeconds;

  int? _sortOrder;
  int? get sortOrder => _$this._sortOrder;
  set sortOrder(int? sortOrder) => _$this._sortOrder = sortOrder;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  GetSnapshot200ResponseSlidesInnerImageBuilder? _image;
  GetSnapshot200ResponseSlidesInnerImageBuilder get image =>
      _$this._image ??= GetSnapshot200ResponseSlidesInnerImageBuilder();
  set image(GetSnapshot200ResponseSlidesInnerImageBuilder? image) =>
      _$this._image = image;

  String? _createdAt;
  String? get createdAt => _$this._createdAt;
  set createdAt(String? createdAt) => _$this._createdAt = createdAt;

  String? _updatedAt;
  String? get updatedAt => _$this._updatedAt;
  set updatedAt(String? updatedAt) => _$this._updatedAt = updatedAt;

  GetSnapshot200ResponseSlidesInnerBuilder() {
    GetSnapshot200ResponseSlidesInner._defaults(this);
  }

  GetSnapshot200ResponseSlidesInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _title = $v.title;
      _body = $v.body;
      _durationSeconds = $v.durationSeconds;
      _sortOrder = $v.sortOrder;
      _active = $v.active;
      _image = $v.image?.toBuilder();
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetSnapshot200ResponseSlidesInner other) {
    _$v = other as _$GetSnapshot200ResponseSlidesInner;
  }

  @override
  void update(
    void Function(GetSnapshot200ResponseSlidesInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  GetSnapshot200ResponseSlidesInner build() => _build();

  _$GetSnapshot200ResponseSlidesInner _build() {
    _$GetSnapshot200ResponseSlidesInner _$result;
    try {
      _$result =
          _$v ??
          _$GetSnapshot200ResponseSlidesInner._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'GetSnapshot200ResponseSlidesInner',
              'id',
            ),
            title: BuiltValueNullFieldError.checkNotNull(
              title,
              r'GetSnapshot200ResponseSlidesInner',
              'title',
            ),
            body: BuiltValueNullFieldError.checkNotNull(
              body,
              r'GetSnapshot200ResponseSlidesInner',
              'body',
            ),
            durationSeconds: BuiltValueNullFieldError.checkNotNull(
              durationSeconds,
              r'GetSnapshot200ResponseSlidesInner',
              'durationSeconds',
            ),
            sortOrder: BuiltValueNullFieldError.checkNotNull(
              sortOrder,
              r'GetSnapshot200ResponseSlidesInner',
              'sortOrder',
            ),
            active: BuiltValueNullFieldError.checkNotNull(
              active,
              r'GetSnapshot200ResponseSlidesInner',
              'active',
            ),
            image: _image?.build(),
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'GetSnapshot200ResponseSlidesInner',
              'createdAt',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'GetSnapshot200ResponseSlidesInner',
              'updatedAt',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'image';
        _image?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'GetSnapshot200ResponseSlidesInner',
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
