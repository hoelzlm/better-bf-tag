//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bftag_api_client/src/model/login200_response_person.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_me200_response.g.dart';

/// GetMe200Response
///
/// Properties:
/// * [person] 
@BuiltValue()
abstract class GetMe200Response implements Built<GetMe200Response, GetMe200ResponseBuilder> {
  @BuiltValueField(wireName: r'person')
  Login200ResponsePerson get person;

  GetMe200Response._();

  factory GetMe200Response([void updates(GetMe200ResponseBuilder b)]) = _$GetMe200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetMe200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetMe200Response> get serializer => _$GetMe200ResponseSerializer();
}

class _$GetMe200ResponseSerializer implements PrimitiveSerializer<GetMe200Response> {
  @override
  final Iterable<Type> types = const [GetMe200Response, _$GetMe200Response];

  @override
  final String wireName = r'GetMe200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetMe200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'person';
    yield serializers.serialize(
      object.person,
      specifiedType: const FullType(Login200ResponsePerson),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetMe200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetMe200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'person':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Login200ResponsePerson),
          ) as Login200ResponsePerson;
          result.person.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetMe200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetMe200ResponseBuilder();
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

