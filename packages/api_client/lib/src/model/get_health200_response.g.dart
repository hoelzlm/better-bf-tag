// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_health200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const GetHealth200ResponseStatusEnum _$getHealth200ResponseStatusEnum_ok =
    const GetHealth200ResponseStatusEnum._('ok');

GetHealth200ResponseStatusEnum _$getHealth200ResponseStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'ok':
      return _$getHealth200ResponseStatusEnum_ok;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<GetHealth200ResponseStatusEnum>
_$getHealth200ResponseStatusEnumValues =
    BuiltSet<GetHealth200ResponseStatusEnum>(
      const <GetHealth200ResponseStatusEnum>[
        _$getHealth200ResponseStatusEnum_ok,
      ],
    );

const GetHealth200ResponseDatabaseEnum _$getHealth200ResponseDatabaseEnum_ok =
    const GetHealth200ResponseDatabaseEnum._('ok');

GetHealth200ResponseDatabaseEnum _$getHealth200ResponseDatabaseEnumValueOf(
  String name,
) {
  switch (name) {
    case 'ok':
      return _$getHealth200ResponseDatabaseEnum_ok;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<GetHealth200ResponseDatabaseEnum>
_$getHealth200ResponseDatabaseEnumValues =
    BuiltSet<GetHealth200ResponseDatabaseEnum>(
      const <GetHealth200ResponseDatabaseEnum>[
        _$getHealth200ResponseDatabaseEnum_ok,
      ],
    );

Serializer<GetHealth200ResponseStatusEnum>
_$getHealth200ResponseStatusEnumSerializer =
    _$GetHealth200ResponseStatusEnumSerializer();
Serializer<GetHealth200ResponseDatabaseEnum>
_$getHealth200ResponseDatabaseEnumSerializer =
    _$GetHealth200ResponseDatabaseEnumSerializer();

class _$GetHealth200ResponseStatusEnumSerializer
    implements PrimitiveSerializer<GetHealth200ResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{'ok': 'ok'};
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ok': 'ok',
  };

  @override
  final Iterable<Type> types = const <Type>[GetHealth200ResponseStatusEnum];
  @override
  final String wireName = 'GetHealth200ResponseStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    GetHealth200ResponseStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  GetHealth200ResponseStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => GetHealth200ResponseStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$GetHealth200ResponseDatabaseEnumSerializer
    implements PrimitiveSerializer<GetHealth200ResponseDatabaseEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{'ok': 'ok'};
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ok': 'ok',
  };

  @override
  final Iterable<Type> types = const <Type>[GetHealth200ResponseDatabaseEnum];
  @override
  final String wireName = 'GetHealth200ResponseDatabaseEnum';

  @override
  Object serialize(
    Serializers serializers,
    GetHealth200ResponseDatabaseEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  GetHealth200ResponseDatabaseEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => GetHealth200ResponseDatabaseEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$GetHealth200Response extends GetHealth200Response {
  @override
  final GetHealth200ResponseStatusEnum status;
  @override
  final GetHealth200ResponseDatabaseEnum database;

  factory _$GetHealth200Response([
    void Function(GetHealth200ResponseBuilder)? updates,
  ]) => (GetHealth200ResponseBuilder()..update(updates))._build();

  _$GetHealth200Response._({required this.status, required this.database})
    : super._();
  @override
  GetHealth200Response rebuild(
    void Function(GetHealth200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetHealth200ResponseBuilder toBuilder() =>
      GetHealth200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetHealth200Response &&
        status == other.status &&
        database == other.database;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, database.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GetHealth200Response')
          ..add('status', status)
          ..add('database', database))
        .toString();
  }
}

class GetHealth200ResponseBuilder
    implements Builder<GetHealth200Response, GetHealth200ResponseBuilder> {
  _$GetHealth200Response? _$v;

  GetHealth200ResponseStatusEnum? _status;
  GetHealth200ResponseStatusEnum? get status => _$this._status;
  set status(GetHealth200ResponseStatusEnum? status) => _$this._status = status;

  GetHealth200ResponseDatabaseEnum? _database;
  GetHealth200ResponseDatabaseEnum? get database => _$this._database;
  set database(GetHealth200ResponseDatabaseEnum? database) =>
      _$this._database = database;

  GetHealth200ResponseBuilder() {
    GetHealth200Response._defaults(this);
  }

  GetHealth200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _database = $v.database;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetHealth200Response other) {
    _$v = other as _$GetHealth200Response;
  }

  @override
  void update(void Function(GetHealth200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GetHealth200Response build() => _build();

  _$GetHealth200Response _build() {
    final _$result =
        _$v ??
        _$GetHealth200Response._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'GetHealth200Response',
            'status',
          ),
          database: BuiltValueNullFieldError.checkNotNull(
            database,
            r'GetHealth200Response',
            'database',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
