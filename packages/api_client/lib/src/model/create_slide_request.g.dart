// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_slide_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateSlideRequest extends CreateSlideRequest {
  @override
  final String title;
  @override
  final String? body;
  @override
  final int? durationSeconds;
  @override
  final bool? active;

  factory _$CreateSlideRequest([
    void Function(CreateSlideRequestBuilder)? updates,
  ]) => (CreateSlideRequestBuilder()..update(updates))._build();

  _$CreateSlideRequest._({
    required this.title,
    this.body,
    this.durationSeconds,
    this.active,
  }) : super._();
  @override
  CreateSlideRequest rebuild(
    void Function(CreateSlideRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateSlideRequestBuilder toBuilder() =>
      CreateSlideRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateSlideRequest &&
        title == other.title &&
        body == other.body &&
        durationSeconds == other.durationSeconds &&
        active == other.active;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, body.hashCode);
    _$hash = $jc(_$hash, durationSeconds.hashCode);
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateSlideRequest')
          ..add('title', title)
          ..add('body', body)
          ..add('durationSeconds', durationSeconds)
          ..add('active', active))
        .toString();
  }
}

class CreateSlideRequestBuilder
    implements Builder<CreateSlideRequest, CreateSlideRequestBuilder> {
  _$CreateSlideRequest? _$v;

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

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  CreateSlideRequestBuilder() {
    CreateSlideRequest._defaults(this);
  }

  CreateSlideRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _body = $v.body;
      _durationSeconds = $v.durationSeconds;
      _active = $v.active;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateSlideRequest other) {
    _$v = other as _$CreateSlideRequest;
  }

  @override
  void update(void Function(CreateSlideRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateSlideRequest build() => _build();

  _$CreateSlideRequest _build() {
    final _$result =
        _$v ??
        _$CreateSlideRequest._(
          title: BuiltValueNullFieldError.checkNotNull(
            title,
            r'CreateSlideRequest',
            'title',
          ),
          body: body,
          durationSeconds: durationSeconds,
          active: active,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
