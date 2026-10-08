// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_health503_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const GetHealth503ResponseStatusEnum _$getHealth503ResponseStatusEnum_error =
    const GetHealth503ResponseStatusEnum._('error');

GetHealth503ResponseStatusEnum _$getHealth503ResponseStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'error':
      return _$getHealth503ResponseStatusEnum_error;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<GetHealth503ResponseStatusEnum>
_$getHealth503ResponseStatusEnumValues =
    BuiltSet<GetHealth503ResponseStatusEnum>(
      const <GetHealth503ResponseStatusEnum>[
        _$getHealth503ResponseStatusEnum_error,
      ],
    );

const GetHealth503ResponseDatabaseEnum
_$getHealth503ResponseDatabaseEnum_error =
    const GetHealth503ResponseDatabaseEnum._('error');

GetHealth503ResponseDatabaseEnum _$getHealth503ResponseDatabaseEnumValueOf(
  String name,
) {
  switch (name) {
    case 'error':
      return _$getHealth503ResponseDatabaseEnum_error;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<GetHealth503ResponseDatabaseEnum>
_$getHealth503ResponseDatabaseEnumValues =
    BuiltSet<GetHealth503ResponseDatabaseEnum>(
      const <GetHealth503ResponseDatabaseEnum>[
        _$getHealth503ResponseDatabaseEnum_error,
      ],
    );

Serializer<GetHealth503ResponseStatusEnum>
_$getHealth503ResponseStatusEnumSerializer =
    _$GetHealth503ResponseStatusEnumSerializer();
Serializer<GetHealth503ResponseDatabaseEnum>
_$getHealth503ResponseDatabaseEnumSerializer =
    _$GetHealth503ResponseDatabaseEnumSerializer();

class _$GetHealth503ResponseStatusEnumSerializer
    implements PrimitiveSerializer<GetHealth503ResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'error': 'error',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'error': 'error',
  };

  @override
  final Iterable<Type> types = const <Type>[GetHealth503ResponseStatusEnum];
  @override
  final String wireName = 'GetHealth503ResponseStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    GetHealth503ResponseStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  GetHealth503ResponseStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => GetHealth503ResponseStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$GetHealth503ResponseDatabaseEnumSerializer
    implements PrimitiveSerializer<GetHealth503ResponseDatabaseEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'error': 'error',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'error': 'error',
  };

  @override
  final Iterable<Type> types = const <Type>[GetHealth503ResponseDatabaseEnum];
  @override
  final String wireName = 'GetHealth503ResponseDatabaseEnum';

  @override
  Object serialize(
    Serializers serializers,
    GetHealth503ResponseDatabaseEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  GetHealth503ResponseDatabaseEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => GetHealth503ResponseDatabaseEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$GetHealth503Response extends GetHealth503Response {
  @override
  final GetHealth503ResponseStatusEnum status;
  @override
  final GetHealth503ResponseDatabaseEnum database;

  factory _$GetHealth503Response([
    void Function(GetHealth503ResponseBuilder)? updates,
  ]) => (GetHealth503ResponseBuilder()..update(updates))._build();

  _$GetHealth503Response._({required this.status, required this.database})
    : super._();
  @override
  GetHealth503Response rebuild(
    void Function(GetHealth503ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetHealth503ResponseBuilder toBuilder() =>
      GetHealth503ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetHealth503Response &&
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
    return (newBuiltValueToStringHelper(r'GetHealth503Response')
          ..add('status', status)
          ..add('database', database))
        .toString();
  }
}

class GetHealth503ResponseBuilder
    implements Builder<GetHealth503Response, GetHealth503ResponseBuilder> {
  _$GetHealth503Response? _$v;

  GetHealth503ResponseStatusEnum? _status;
  GetHealth503ResponseStatusEnum? get status => _$this._status;
  set status(GetHealth503ResponseStatusEnum? status) => _$this._status = status;

  GetHealth503ResponseDatabaseEnum? _database;
  GetHealth503ResponseDatabaseEnum? get database => _$this._database;
  set database(GetHealth503ResponseDatabaseEnum? database) =>
      _$this._database = database;

  GetHealth503ResponseBuilder() {
    GetHealth503Response._defaults(this);
  }

  GetHealth503ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _database = $v.database;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetHealth503Response other) {
    _$v = other as _$GetHealth503Response;
  }

  @override
  void update(void Function(GetHealth503ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GetHealth503Response build() => _build();

  _$GetHealth503Response _build() {
    final _$result =
        _$v ??
        _$GetHealth503Response._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'GetHealth503Response',
            'status',
          ),
          database: BuiltValueNullFieldError.checkNotNull(
            database,
            r'GetHealth503Response',
            'database',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
