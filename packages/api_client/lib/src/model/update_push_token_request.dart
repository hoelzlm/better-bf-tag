//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_push_token_request.g.dart';

/// UpdatePushTokenRequest
///
/// Properties:
/// * [token] 
@BuiltValue()
abstract class UpdatePushTokenRequest implements Built<UpdatePushTokenRequest, UpdatePushTokenRequestBuilder> {
  @BuiltValueField(wireName: r'token')
  String get token;

  UpdatePushTokenRequest._();

  factory UpdatePushTokenRequest([void updates(UpdatePushTokenRequestBuilder b)]) = _$UpdatePushTokenRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdatePushTokenRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdatePushTokenRequest> get serializer => _$UpdatePushTokenRequestSerializer();
}

class _$UpdatePushTokenRequestSerializer implements PrimitiveSerializer<UpdatePushTokenRequest> {
  @override
  final Iterable<Type> types = const [UpdatePushTokenRequest, _$UpdatePushTokenRequest];

  @override
  final String wireName = r'UpdatePushTokenRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdatePushTokenRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'token';
    yield serializers.serialize(
      object.token,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdatePushTokenRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdatePushTokenRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.token = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdatePushTokenRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdatePushTokenRequestBuilder();
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

