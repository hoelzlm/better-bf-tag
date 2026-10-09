// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anonymize_bf_day200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AnonymizeBfDay200Response extends AnonymizeBfDay200Response {
  @override
  final ListBfDays200ResponseInner bfDay;
  @override
  final GetBfDayAnonymizationPreview200Response summary;

  factory _$AnonymizeBfDay200Response([
    void Function(AnonymizeBfDay200ResponseBuilder)? updates,
  ]) => (AnonymizeBfDay200ResponseBuilder()..update(updates))._build();

  _$AnonymizeBfDay200Response._({required this.bfDay, required this.summary})
    : super._();
  @override
  AnonymizeBfDay200Response rebuild(
    void Function(AnonymizeBfDay200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AnonymizeBfDay200ResponseBuilder toBuilder() =>
      AnonymizeBfDay200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AnonymizeBfDay200Response &&
        bfDay == other.bfDay &&
        summary == other.summary;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, bfDay.hashCode);
    _$hash = $jc(_$hash, summary.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AnonymizeBfDay200Response')
          ..add('bfDay', bfDay)
          ..add('summary', summary))
        .toString();
  }
}

class AnonymizeBfDay200ResponseBuilder
    implements
        Builder<AnonymizeBfDay200Response, AnonymizeBfDay200ResponseBuilder> {
  _$AnonymizeBfDay200Response? _$v;

  ListBfDays200ResponseInnerBuilder? _bfDay;
  ListBfDays200ResponseInnerBuilder get bfDay =>
      _$this._bfDay ??= ListBfDays200ResponseInnerBuilder();
  set bfDay(ListBfDays200ResponseInnerBuilder? bfDay) => _$this._bfDay = bfDay;

  GetBfDayAnonymizationPreview200ResponseBuilder? _summary;
  GetBfDayAnonymizationPreview200ResponseBuilder get summary =>
      _$this._summary ??= GetBfDayAnonymizationPreview200ResponseBuilder();
  set summary(GetBfDayAnonymizationPreview200ResponseBuilder? summary) =>
      _$this._summary = summary;

  AnonymizeBfDay200ResponseBuilder() {
    AnonymizeBfDay200Response._defaults(this);
  }

  AnonymizeBfDay200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _bfDay = $v.bfDay.toBuilder();
      _summary = $v.summary.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AnonymizeBfDay200Response other) {
    _$v = other as _$AnonymizeBfDay200Response;
  }

  @override
  void update(void Function(AnonymizeBfDay200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AnonymizeBfDay200Response build() => _build();

  _$AnonymizeBfDay200Response _build() {
    _$AnonymizeBfDay200Response _$result;
    try {
      _$result =
          _$v ??
          _$AnonymizeBfDay200Response._(
            bfDay: bfDay.build(),
            summary: summary.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'bfDay';
        bfDay.build();
        _$failedField = 'summary';
        summary.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'AnonymizeBfDay200Response',
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
