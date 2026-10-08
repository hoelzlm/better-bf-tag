// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_pairing_codes_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreatePairingCodesRequest extends CreatePairingCodesRequest {
  @override
  final BuiltList<String>? personIds;

  factory _$CreatePairingCodesRequest([
    void Function(CreatePairingCodesRequestBuilder)? updates,
  ]) => (CreatePairingCodesRequestBuilder()..update(updates))._build();

  _$CreatePairingCodesRequest._({this.personIds}) : super._();
  @override
  CreatePairingCodesRequest rebuild(
    void Function(CreatePairingCodesRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreatePairingCodesRequestBuilder toBuilder() =>
      CreatePairingCodesRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreatePairingCodesRequest && personIds == other.personIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, personIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'CreatePairingCodesRequest',
    )..add('personIds', personIds)).toString();
  }
}

class CreatePairingCodesRequestBuilder
    implements
        Builder<CreatePairingCodesRequest, CreatePairingCodesRequestBuilder> {
  _$CreatePairingCodesRequest? _$v;

  ListBuilder<String>? _personIds;
  ListBuilder<String> get personIds =>
      _$this._personIds ??= ListBuilder<String>();
  set personIds(ListBuilder<String>? personIds) =>
      _$this._personIds = personIds;

  CreatePairingCodesRequestBuilder() {
    CreatePairingCodesRequest._defaults(this);
  }

  CreatePairingCodesRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _personIds = $v.personIds?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreatePairingCodesRequest other) {
    _$v = other as _$CreatePairingCodesRequest;
  }

  @override
  void update(void Function(CreatePairingCodesRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreatePairingCodesRequest build() => _build();

  _$CreatePairingCodesRequest _build() {
    _$CreatePairingCodesRequest _$result;
    try {
      _$result =
          _$v ?? _$CreatePairingCodesRequest._(personIds: _personIds?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'personIds';
        _personIds?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'CreatePairingCodesRequest',
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
