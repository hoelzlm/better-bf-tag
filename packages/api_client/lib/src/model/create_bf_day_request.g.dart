// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_bf_day_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateBfDayRequest extends CreateBfDayRequest {
  @override
  final String name;
  @override
  final DateTime startsAt;
  @override
  final DateTime endsAt;

  factory _$CreateBfDayRequest([
    void Function(CreateBfDayRequestBuilder)? updates,
  ]) => (CreateBfDayRequestBuilder()..update(updates))._build();

  _$CreateBfDayRequest._({
    required this.name,
    required this.startsAt,
    required this.endsAt,
  }) : super._();
  @override
  CreateBfDayRequest rebuild(
    void Function(CreateBfDayRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateBfDayRequestBuilder toBuilder() =>
      CreateBfDayRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateBfDayRequest &&
        name == other.name &&
        startsAt == other.startsAt &&
        endsAt == other.endsAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, startsAt.hashCode);
    _$hash = $jc(_$hash, endsAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateBfDayRequest')
          ..add('name', name)
          ..add('startsAt', startsAt)
          ..add('endsAt', endsAt))
        .toString();
  }
}

class CreateBfDayRequestBuilder
    implements Builder<CreateBfDayRequest, CreateBfDayRequestBuilder> {
  _$CreateBfDayRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  DateTime? _startsAt;
  DateTime? get startsAt => _$this._startsAt;
  set startsAt(DateTime? startsAt) => _$this._startsAt = startsAt;

  DateTime? _endsAt;
  DateTime? get endsAt => _$this._endsAt;
  set endsAt(DateTime? endsAt) => _$this._endsAt = endsAt;

  CreateBfDayRequestBuilder() {
    CreateBfDayRequest._defaults(this);
  }

  CreateBfDayRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _startsAt = $v.startsAt;
      _endsAt = $v.endsAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateBfDayRequest other) {
    _$v = other as _$CreateBfDayRequest;
  }

  @override
  void update(void Function(CreateBfDayRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateBfDayRequest build() => _build();

  _$CreateBfDayRequest _build() {
    final _$result =
        _$v ??
        _$CreateBfDayRequest._(
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'CreateBfDayRequest',
            'name',
          ),
          startsAt: BuiltValueNullFieldError.checkNotNull(
            startsAt,
            r'CreateBfDayRequest',
            'startsAt',
          ),
          endsAt: BuiltValueNullFieldError.checkNotNull(
            endsAt,
            r'CreateBfDayRequest',
            'endsAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
