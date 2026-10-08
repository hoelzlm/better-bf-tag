// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_bf_day_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateBfDayRequest extends UpdateBfDayRequest {
  @override
  final String? name;
  @override
  final DateTime? startsAt;
  @override
  final DateTime? endsAt;

  factory _$UpdateBfDayRequest([
    void Function(UpdateBfDayRequestBuilder)? updates,
  ]) => (UpdateBfDayRequestBuilder()..update(updates))._build();

  _$UpdateBfDayRequest._({this.name, this.startsAt, this.endsAt}) : super._();
  @override
  UpdateBfDayRequest rebuild(
    void Function(UpdateBfDayRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateBfDayRequestBuilder toBuilder() =>
      UpdateBfDayRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateBfDayRequest &&
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
    return (newBuiltValueToStringHelper(r'UpdateBfDayRequest')
          ..add('name', name)
          ..add('startsAt', startsAt)
          ..add('endsAt', endsAt))
        .toString();
  }
}

class UpdateBfDayRequestBuilder
    implements Builder<UpdateBfDayRequest, UpdateBfDayRequestBuilder> {
  _$UpdateBfDayRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  DateTime? _startsAt;
  DateTime? get startsAt => _$this._startsAt;
  set startsAt(DateTime? startsAt) => _$this._startsAt = startsAt;

  DateTime? _endsAt;
  DateTime? get endsAt => _$this._endsAt;
  set endsAt(DateTime? endsAt) => _$this._endsAt = endsAt;

  UpdateBfDayRequestBuilder() {
    UpdateBfDayRequest._defaults(this);
  }

  UpdateBfDayRequestBuilder get _$this {
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
  void replace(UpdateBfDayRequest other) {
    _$v = other as _$UpdateBfDayRequest;
  }

  @override
  void update(void Function(UpdateBfDayRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateBfDayRequest build() => _build();

  _$UpdateBfDayRequest _build() {
    final _$result =
        _$v ??
        _$UpdateBfDayRequest._(name: name, startsAt: startsAt, endsAt: endsAt);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
