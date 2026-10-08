//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_health503_response.g.dart';

/// GetHealth503Response
///
/// Properties:
/// * [status] 
/// * [database] 
@BuiltValue()
abstract class GetHealth503Response implements Built<GetHealth503Response, GetHealth503ResponseBuilder> {
  @BuiltValueField(wireName: r'status')
  GetHealth503ResponseStatusEnum get status;
  // enum statusEnum {  error,  };

  @BuiltValueField(wireName: r'database')
  GetHealth503ResponseDatabaseEnum get database;
  // enum databaseEnum {  error,  };

  GetHealth503Response._();

  factory GetHealth503Response([void updates(GetHealth503ResponseBuilder b)]) = _$GetHealth503Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetHealth503ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetHealth503Response> get serializer => _$GetHealth503ResponseSerializer();
}

class _$GetHealth503ResponseSerializer implements PrimitiveSerializer<GetHealth503Response> {
  @override
  final Iterable<Type> types = const [GetHealth503Response, _$GetHealth503Response];

  @override
  final String wireName = r'GetHealth503Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetHealth503Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(GetHealth503ResponseStatusEnum),
    );
    yield r'database';
    yield serializers.serialize(
      object.database,
      specifiedType: const FullType(GetHealth503ResponseDatabaseEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetHealth503Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetHealth503ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GetHealth503ResponseStatusEnum),
          ) as GetHealth503ResponseStatusEnum;
          result.status = valueDes;
          break;
        case r'database':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GetHealth503ResponseDatabaseEnum),
          ) as GetHealth503ResponseDatabaseEnum;
          result.database = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetHealth503Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetHealth503ResponseBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

class GetHealth503ResponseStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'error')
  static const GetHealth503ResponseStatusEnum error = _$getHealth503ResponseStatusEnum_error;

  static Serializer<GetHealth503ResponseStatusEnum> get serializer => _$getHealth503ResponseStatusEnumSerializer;

  const GetHealth503ResponseStatusEnum._(String name): super(name);

  static BuiltSet<GetHealth503ResponseStatusEnum> get values => _$getHealth503ResponseStatusEnumValues;
  static GetHealth503ResponseStatusEnum valueOf(String name) => _$getHealth503ResponseStatusEnumValueOf(name);
}

class GetHealth503ResponseDatabaseEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'error')
  static const GetHealth503ResponseDatabaseEnum error = _$getHealth503ResponseDatabaseEnum_error;

  static Serializer<GetHealth503ResponseDatabaseEnum> get serializer => _$getHealth503ResponseDatabaseEnumSerializer;

  const GetHealth503ResponseDatabaseEnum._(String name): super(name);

  static BuiltSet<GetHealth503ResponseDatabaseEnum> get values => _$getHealth503ResponseDatabaseEnumValues;
  static GetHealth503ResponseDatabaseEnum valueOf(String name) => _$getHealth503ResponseDatabaseEnumValueOf(name);
}

