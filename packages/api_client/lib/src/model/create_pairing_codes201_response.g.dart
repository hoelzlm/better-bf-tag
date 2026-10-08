// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_pairing_codes201_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreatePairingCodes201Response extends CreatePairingCodes201Response {
  @override
  final BuiltList<CreatePairingCode201Response> items;

  factory _$CreatePairingCodes201Response([
    void Function(CreatePairingCodes201ResponseBuilder)? updates,
  ]) => (CreatePairingCodes201ResponseBuilder()..update(updates))._build();

  _$CreatePairingCodes201Response._({required this.items}) : super._();
  @override
  CreatePairingCodes201Response rebuild(
    void Function(CreatePairingCodes201ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreatePairingCodes201ResponseBuilder toBuilder() =>
      CreatePairingCodes201ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreatePairingCodes201Response && items == other.items;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'CreatePairingCodes201Response',
    )..add('items', items)).toString();
  }
}

class CreatePairingCodes201ResponseBuilder
    implements
        Builder<
          CreatePairingCodes201Response,
          CreatePairingCodes201ResponseBuilder
        > {
  _$CreatePairingCodes201Response? _$v;

  ListBuilder<CreatePairingCode201Response>? _items;
  ListBuilder<CreatePairingCode201Response> get items =>
      _$this._items ??= ListBuilder<CreatePairingCode201Response>();
  set items(ListBuilder<CreatePairingCode201Response>? items) =>
      _$this._items = items;

  CreatePairingCodes201ResponseBuilder() {
    CreatePairingCodes201Response._defaults(this);
  }

  CreatePairingCodes201ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreatePairingCodes201Response other) {
    _$v = other as _$CreatePairingCodes201Response;
  }

  @override
  void update(void Function(CreatePairingCodes201ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreatePairingCodes201Response build() => _build();

  _$CreatePairingCodes201Response _build() {
    _$CreatePairingCodes201Response _$result;
    try {
      _$result = _$v ?? _$CreatePairingCodes201Response._(items: items.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'CreatePairingCodes201Response',
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
