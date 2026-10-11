// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geocode200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Geocode200Response extends Geocode200Response {
  @override
  final BuiltList<Geocode200ResponseResultsInner> results;

  factory _$Geocode200Response([
    void Function(Geocode200ResponseBuilder)? updates,
  ]) => (Geocode200ResponseBuilder()..update(updates))._build();

  _$Geocode200Response._({required this.results}) : super._();
  @override
  Geocode200Response rebuild(
    void Function(Geocode200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  Geocode200ResponseBuilder toBuilder() =>
      Geocode200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Geocode200Response && results == other.results;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, results.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'Geocode200Response',
    )..add('results', results)).toString();
  }
}

class Geocode200ResponseBuilder
    implements Builder<Geocode200Response, Geocode200ResponseBuilder> {
  _$Geocode200Response? _$v;

  ListBuilder<Geocode200ResponseResultsInner>? _results;
  ListBuilder<Geocode200ResponseResultsInner> get results =>
      _$this._results ??= ListBuilder<Geocode200ResponseResultsInner>();
  set results(ListBuilder<Geocode200ResponseResultsInner>? results) =>
      _$this._results = results;

  Geocode200ResponseBuilder() {
    Geocode200Response._defaults(this);
  }

  Geocode200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _results = $v.results.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Geocode200Response other) {
    _$v = other as _$Geocode200Response;
  }

  @override
  void update(void Function(Geocode200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Geocode200Response build() => _build();

  _$Geocode200Response _build() {
    _$Geocode200Response _$result;
    try {
      _$result = _$v ?? _$Geocode200Response._(results: results.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'results';
        results.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'Geocode200Response',
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
