//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'login401_response_error.g.dart';

/// Login401ResponseError
///
/// Properties:
/// * [code] 
/// * [message] 
@BuiltValue()
abstract class Login401ResponseError implements Built<Login401ResponseError, Login401ResponseErrorBuilder> {
  @BuiltValueField(wireName: r'code')
  String get code;

  @BuiltValueField(wireName: r'message')
  String get message;

  Login401ResponseError._();

  factory Login401ResponseError([void updates(Login401ResponseErrorBuilder b)]) = _$Login401ResponseError;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(Login401ResponseErrorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Login401ResponseError> get serializer => _$Login401ResponseErrorSerializer();
}

class _$Login401ResponseErrorSerializer implements PrimitiveSerializer<Login401ResponseError> {
  @override
  final Iterable<Type> types = const [Login401ResponseError, _$Login401ResponseError];

  @override
  final String wireName = r'Login401ResponseError';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Login401ResponseError object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Login401ResponseError object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required Login401ResponseErrorBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Login401ResponseError deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = Login401ResponseErrorBuilder();
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

