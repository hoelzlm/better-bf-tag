// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_slide_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateSlideRequest extends UpdateSlideRequest {
  @override
  final String? title;
  @override
  final String? body;
  @override
  final int? durationSeconds;
  @override
  final bool? active;

  factory _$UpdateSlideRequest([
    void Function(UpdateSlideRequestBuilder)? updates,
  ]) => (UpdateSlideRequestBuilder()..update(updates))._build();

  _$UpdateSlideRequest._({
    this.title,
    this.body,
    this.durationSeconds,
    this.active,
  }) : super._();
  @override
  UpdateSlideRequest rebuild(
    void Function(UpdateSlideRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateSlideRequestBuilder toBuilder() =>
      UpdateSlideRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateSlideRequest &&
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
    return (newBuiltValueToStringHelper(r'UpdateSlideRequest')
          ..add('title', title)
          ..add('body', body)
          ..add('durationSeconds', durationSeconds)
          ..add('active', active))
        .toString();
  }
}

class UpdateSlideRequestBuilder
    implements Builder<UpdateSlideRequest, UpdateSlideRequestBuilder> {
  _$UpdateSlideRequest? _$v;

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

  UpdateSlideRequestBuilder() {
    UpdateSlideRequest._defaults(this);
  }

  UpdateSlideRequestBuilder get _$this {
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
  void replace(UpdateSlideRequest other) {
    _$v = other as _$UpdateSlideRequest;
  }

  @override
  void update(void Function(UpdateSlideRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateSlideRequest build() => _build();

  _$UpdateSlideRequest _build() {
    final _$result =
        _$v ??
        _$UpdateSlideRequest._(
          title: title,
          body: body,
          durationSeconds: durationSeconds,
          active: active,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
