//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bftag_api_client/src/model/login200_response_person.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'pair200_response.g.dart';

/// Pair200Response
///
/// Properties:
/// * [accessToken] 
/// * [refreshToken] 
/// * [expiresIn] 
/// * [deviceId] 
/// * [person] 
@BuiltValue()
abstract class Pair200Response implements Built<Pair200Response, Pair200ResponseBuilder> {
  @BuiltValueField(wireName: r'access_token')
  String get accessToken;

  @BuiltValueField(wireName: r'refresh_token')
  String get refreshToken;

  @BuiltValueField(wireName: r'expires_in')
  num get expiresIn;

  @BuiltValueField(wireName: r'device_id')
  String get deviceId;

  @BuiltValueField(wireName: r'person')
  Login200ResponsePerson get person;

  Pair200Response._();

  factory Pair200Response([void updates(Pair200ResponseBuilder b)]) = _$Pair200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(Pair200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Pair200Response> get serializer => _$Pair200ResponseSerializer();
}

class _$Pair200ResponseSerializer implements PrimitiveSerializer<Pair200Response> {
  @override
  final Iterable<Type> types = const [Pair200Response, _$Pair200Response];

  @override
  final String wireName = r'Pair200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Pair200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'access_token';
    yield serializers.serialize(
      object.accessToken,
      specifiedType: const FullType(String),
    );
    yield r'refresh_token';
    yield serializers.serialize(
      object.refreshToken,
      specifiedType: const FullType(String),
    );
    yield r'expires_in';
    yield serializers.serialize(
      object.expiresIn,
      specifiedType: const FullType(num),
    );
    yield r'device_id';
    yield serializers.serialize(
      object.deviceId,
      specifiedType: const FullType(String),
    );
    yield r'person';
    yield serializers.serialize(
      object.person,
      specifiedType: const FullType(Login200ResponsePerson),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Pair200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required Pair200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'access_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.accessToken = valueDes;
          break;
        case r'refresh_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.refreshToken = valueDes;
          break;
        case r'expires_in':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.expiresIn = valueDes;
          break;
        case r'device_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deviceId = valueDes;
          break;
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
  Pair200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = Pair200ResponseBuilder();
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

