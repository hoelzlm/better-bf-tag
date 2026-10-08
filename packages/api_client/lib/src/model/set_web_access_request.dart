//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'set_web_access_request.g.dart';

/// SetWebAccessRequest
///
/// Properties:
/// * [username] 
/// * [password] 
@BuiltValue()
abstract class SetWebAccessRequest implements Built<SetWebAccessRequest, SetWebAccessRequestBuilder> {
  @BuiltValueField(wireName: r'username')
  String get username;

  @BuiltValueField(wireName: r'password')
  String get password;

  SetWebAccessRequest._();

  factory SetWebAccessRequest([void updates(SetWebAccessRequestBuilder b)]) = _$SetWebAccessRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SetWebAccessRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SetWebAccessRequest> get serializer => _$SetWebAccessRequestSerializer();
}

class _$SetWebAccessRequestSerializer implements PrimitiveSerializer<SetWebAccessRequest> {
  @override
  final Iterable<Type> types = const [SetWebAccessRequest, _$SetWebAccessRequest];

  @override
  final String wireName = r'SetWebAccessRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SetWebAccessRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'username';
    yield serializers.serialize(
      object.username,
      specifiedType: const FullType(String),
    );
    yield r'password';
    yield serializers.serialize(
      object.password,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SetWebAccessRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SetWebAccessRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'username':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.username = valueDes;
          break;
        case r'password':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.password = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SetWebAccessRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SetWebAccessRequestBuilder();
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

