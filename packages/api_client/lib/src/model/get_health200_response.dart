//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_health200_response.g.dart';

/// GetHealth200Response
///
/// Properties:
/// * [status] 
/// * [database] 
@BuiltValue()
abstract class GetHealth200Response implements Built<GetHealth200Response, GetHealth200ResponseBuilder> {
  @BuiltValueField(wireName: r'status')
  GetHealth200ResponseStatusEnum get status;
  // enum statusEnum {  ok,  };

  @BuiltValueField(wireName: r'database')
  GetHealth200ResponseDatabaseEnum get database;
  // enum databaseEnum {  ok,  };

  GetHealth200Response._();

  factory GetHealth200Response([void updates(GetHealth200ResponseBuilder b)]) = _$GetHealth200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetHealth200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetHealth200Response> get serializer => _$GetHealth200ResponseSerializer();
}

class _$GetHealth200ResponseSerializer implements PrimitiveSerializer<GetHealth200Response> {
  @override
  final Iterable<Type> types = const [GetHealth200Response, _$GetHealth200Response];

  @override
  final String wireName = r'GetHealth200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetHealth200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(GetHealth200ResponseStatusEnum),
    );
    yield r'database';
    yield serializers.serialize(
      object.database,
      specifiedType: const FullType(GetHealth200ResponseDatabaseEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetHealth200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetHealth200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GetHealth200ResponseStatusEnum),
          ) as GetHealth200ResponseStatusEnum;
          result.status = valueDes;
          break;
        case r'database':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GetHealth200ResponseDatabaseEnum),
          ) as GetHealth200ResponseDatabaseEnum;
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
  GetHealth200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetHealth200ResponseBuilder();
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

class GetHealth200ResponseStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ok')
  static const GetHealth200ResponseStatusEnum ok = _$getHealth200ResponseStatusEnum_ok;

  static Serializer<GetHealth200ResponseStatusEnum> get serializer => _$getHealth200ResponseStatusEnumSerializer;

  const GetHealth200ResponseStatusEnum._(String name): super(name);

  static BuiltSet<GetHealth200ResponseStatusEnum> get values => _$getHealth200ResponseStatusEnumValues;
  static GetHealth200ResponseStatusEnum valueOf(String name) => _$getHealth200ResponseStatusEnumValueOf(name);
}

class GetHealth200ResponseDatabaseEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ok')
  static const GetHealth200ResponseDatabaseEnum ok = _$getHealth200ResponseDatabaseEnum_ok;

  static Serializer<GetHealth200ResponseDatabaseEnum> get serializer => _$getHealth200ResponseDatabaseEnumSerializer;

  const GetHealth200ResponseDatabaseEnum._(String name): super(name);

  static BuiltSet<GetHealth200ResponseDatabaseEnum> get values => _$getHealth200ResponseDatabaseEnumValues;
  static GetHealth200ResponseDatabaseEnum valueOf(String name) => _$getHealth200ResponseDatabaseEnumValueOf(name);
}

