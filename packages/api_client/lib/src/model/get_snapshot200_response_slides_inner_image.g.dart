// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_snapshot200_response_slides_inner_image.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GetSnapshot200ResponseSlidesInnerImage
    extends GetSnapshot200ResponseSlidesInnerImage {
  @override
  final String contentType;
  @override
  final int sizeBytes;
  @override
  final String version;

  factory _$GetSnapshot200ResponseSlidesInnerImage([
    void Function(GetSnapshot200ResponseSlidesInnerImageBuilder)? updates,
  ]) => (GetSnapshot200ResponseSlidesInnerImageBuilder()..update(updates))
      ._build();

  _$GetSnapshot200ResponseSlidesInnerImage._({
    required this.contentType,
    required this.sizeBytes,
    required this.version,
  }) : super._();
  @override
  GetSnapshot200ResponseSlidesInnerImage rebuild(
    void Function(GetSnapshot200ResponseSlidesInnerImageBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetSnapshot200ResponseSlidesInnerImageBuilder toBuilder() =>
      GetSnapshot200ResponseSlidesInnerImageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetSnapshot200ResponseSlidesInnerImage &&
        contentType == other.contentType &&
        sizeBytes == other.sizeBytes &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, contentType.hashCode);
    _$hash = $jc(_$hash, sizeBytes.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'GetSnapshot200ResponseSlidesInnerImage',
          )
          ..add('contentType', contentType)
          ..add('sizeBytes', sizeBytes)
          ..add('version', version))
        .toString();
  }
}

class GetSnapshot200ResponseSlidesInnerImageBuilder
    implements
        Builder<
          GetSnapshot200ResponseSlidesInnerImage,
          GetSnapshot200ResponseSlidesInnerImageBuilder
        > {
  _$GetSnapshot200ResponseSlidesInnerImage? _$v;

  String? _contentType;
  String? get contentType => _$this._contentType;
  set contentType(String? contentType) => _$this._contentType = contentType;

  int? _sizeBytes;
  int? get sizeBytes => _$this._sizeBytes;
  set sizeBytes(int? sizeBytes) => _$this._sizeBytes = sizeBytes;

  String? _version;
  String? get version => _$this._version;
  set version(String? version) => _$this._version = version;

  GetSnapshot200ResponseSlidesInnerImageBuilder() {
    GetSnapshot200ResponseSlidesInnerImage._defaults(this);
  }

  GetSnapshot200ResponseSlidesInnerImageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _contentType = $v.contentType;
      _sizeBytes = $v.sizeBytes;
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetSnapshot200ResponseSlidesInnerImage other) {
    _$v = other as _$GetSnapshot200ResponseSlidesInnerImage;
  }

  @override
  void update(
    void Function(GetSnapshot200ResponseSlidesInnerImageBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  GetSnapshot200ResponseSlidesInnerImage build() => _build();

  _$GetSnapshot200ResponseSlidesInnerImage _build() {
    final _$result =
        _$v ??
        _$GetSnapshot200ResponseSlidesInnerImage._(
          contentType: BuiltValueNullFieldError.checkNotNull(
            contentType,
            r'GetSnapshot200ResponseSlidesInnerImage',
            'contentType',
          ),
          sizeBytes: BuiltValueNullFieldError.checkNotNull(
            sizeBytes,
            r'GetSnapshot200ResponseSlidesInnerImage',
            'sizeBytes',
          ),
          version: BuiltValueNullFieldError.checkNotNull(
            version,
            r'GetSnapshot200ResponseSlidesInnerImage',
            'version',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
