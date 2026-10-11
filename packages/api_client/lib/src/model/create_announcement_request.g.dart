// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_announcement_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateAnnouncementRequest extends CreateAnnouncementRequest {
  @override
  final String text;
  @override
  final String? shiftId;

  factory _$CreateAnnouncementRequest([
    void Function(CreateAnnouncementRequestBuilder)? updates,
  ]) => (CreateAnnouncementRequestBuilder()..update(updates))._build();

  _$CreateAnnouncementRequest._({required this.text, this.shiftId}) : super._();
  @override
  CreateAnnouncementRequest rebuild(
    void Function(CreateAnnouncementRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateAnnouncementRequestBuilder toBuilder() =>
      CreateAnnouncementRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateAnnouncementRequest &&
        text == other.text &&
        shiftId == other.shiftId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, text.hashCode);
    _$hash = $jc(_$hash, shiftId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateAnnouncementRequest')
          ..add('text', text)
          ..add('shiftId', shiftId))
        .toString();
  }
}

class CreateAnnouncementRequestBuilder
    implements
        Builder<CreateAnnouncementRequest, CreateAnnouncementRequestBuilder> {
  _$CreateAnnouncementRequest? _$v;

  String? _text;
  String? get text => _$this._text;
  set text(String? text) => _$this._text = text;

  String? _shiftId;
  String? get shiftId => _$this._shiftId;
  set shiftId(String? shiftId) => _$this._shiftId = shiftId;

  CreateAnnouncementRequestBuilder() {
    CreateAnnouncementRequest._defaults(this);
  }

  CreateAnnouncementRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _text = $v.text;
      _shiftId = $v.shiftId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateAnnouncementRequest other) {
    _$v = other as _$CreateAnnouncementRequest;
  }

  @override
  void update(void Function(CreateAnnouncementRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateAnnouncementRequest build() => _build();

  _$CreateAnnouncementRequest _build() {
    final _$result =
        _$v ??
        _$CreateAnnouncementRequest._(
          text: BuiltValueNullFieldError.checkNotNull(
            text,
            r'CreateAnnouncementRequest',
            'text',
          ),
          shiftId: shiftId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
