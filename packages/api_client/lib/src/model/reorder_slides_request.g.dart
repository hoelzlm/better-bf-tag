// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reorder_slides_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReorderSlidesRequest extends ReorderSlidesRequest {
  @override
  final BuiltList<String> slideIds;

  factory _$ReorderSlidesRequest([
    void Function(ReorderSlidesRequestBuilder)? updates,
  ]) => (ReorderSlidesRequestBuilder()..update(updates))._build();

  _$ReorderSlidesRequest._({required this.slideIds}) : super._();
  @override
  ReorderSlidesRequest rebuild(
    void Function(ReorderSlidesRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ReorderSlidesRequestBuilder toBuilder() =>
      ReorderSlidesRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReorderSlidesRequest && slideIds == other.slideIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, slideIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ReorderSlidesRequest',
    )..add('slideIds', slideIds)).toString();
  }
}

class ReorderSlidesRequestBuilder
    implements Builder<ReorderSlidesRequest, ReorderSlidesRequestBuilder> {
  _$ReorderSlidesRequest? _$v;

  ListBuilder<String>? _slideIds;
  ListBuilder<String> get slideIds =>
      _$this._slideIds ??= ListBuilder<String>();
  set slideIds(ListBuilder<String>? slideIds) => _$this._slideIds = slideIds;

  ReorderSlidesRequestBuilder() {
    ReorderSlidesRequest._defaults(this);
  }

  ReorderSlidesRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _slideIds = $v.slideIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReorderSlidesRequest other) {
    _$v = other as _$ReorderSlidesRequest;
  }

  @override
  void update(void Function(ReorderSlidesRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReorderSlidesRequest build() => _build();

  _$ReorderSlidesRequest _build() {
    _$ReorderSlidesRequest _$result;
    try {
      _$result = _$v ?? _$ReorderSlidesRequest._(slideIds: slideIds.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'slideIds';
        slideIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ReorderSlidesRequest',
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
