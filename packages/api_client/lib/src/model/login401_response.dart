//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bftag_api_client/src/model/login401_response_error.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'login401_response.g.dart';

/// Login401Response
///
/// Properties:
/// * [error] 
@BuiltValue()
abstract class Login401Response implements Built<Login401Response, Login401ResponseBuilder> {
  @BuiltValueField(wireName: r'error')
  Login401ResponseError get error;

  Login401Response._();

  factory Login401Response([void updates(Login401ResponseBuilder b)]) = _$Login401Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(Login401ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Login401Response> get serializer => _$Login401ResponseSerializer();
}

class _$Login401ResponseSerializer implements PrimitiveSerializer<Login401Response> {
  @override
  final Iterable<Type> types = const [Login401Response, _$Login401Response];

  @override
  final String wireName = r'Login401Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Login401Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'error';
    yield serializers.serialize(
      object.error,
      specifiedType: const FullType(Login401ResponseError),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Login401Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required Login401ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'error':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Login401ResponseError),
          ) as Login401ResponseError;
          result.error.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Login401Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = Login401ResponseBuilder();
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

