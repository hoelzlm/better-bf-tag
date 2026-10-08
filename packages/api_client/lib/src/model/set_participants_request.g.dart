// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_participants_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SetParticipantsRequest extends SetParticipantsRequest {
  @override
  final BuiltList<String> personIds;

  factory _$SetParticipantsRequest([
    void Function(SetParticipantsRequestBuilder)? updates,
  ]) => (SetParticipantsRequestBuilder()..update(updates))._build();

  _$SetParticipantsRequest._({required this.personIds}) : super._();
  @override
  SetParticipantsRequest rebuild(
    void Function(SetParticipantsRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  SetParticipantsRequestBuilder toBuilder() =>
      SetParticipantsRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SetParticipantsRequest && personIds == other.personIds;
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
      r'SetParticipantsRequest',
    )..add('personIds', personIds)).toString();
  }
}

class SetParticipantsRequestBuilder
    implements Builder<SetParticipantsRequest, SetParticipantsRequestBuilder> {
  _$SetParticipantsRequest? _$v;

  ListBuilder<String>? _personIds;
  ListBuilder<String> get personIds =>
      _$this._personIds ??= ListBuilder<String>();
  set personIds(ListBuilder<String>? personIds) =>
      _$this._personIds = personIds;

  SetParticipantsRequestBuilder() {
    SetParticipantsRequest._defaults(this);
  }

  SetParticipantsRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _personIds = $v.personIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SetParticipantsRequest other) {
    _$v = other as _$SetParticipantsRequest;
  }

  @override
  void update(void Function(SetParticipantsRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SetParticipantsRequest build() => _build();

  _$SetParticipantsRequest _build() {
    _$SetParticipantsRequest _$result;
    try {
      _$result =
          _$v ?? _$SetParticipantsRequest._(personIds: personIds.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'personIds';
        personIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'SetParticipantsRequest',
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
