//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_pairing_code201_response.g.dart';

/// CreatePairingCode201Response
///
/// Properties:
/// * [personId] 
/// * [displayName] 
/// * [code] 
/// * [expiresAt] 
@BuiltValue()
abstract class CreatePairingCode201Response implements Built<CreatePairingCode201Response, CreatePairingCode201ResponseBuilder> {
  @BuiltValueField(wireName: r'person_id')
  String get personId;

  @BuiltValueField(wireName: r'display_name')
  String get displayName;

  @BuiltValueField(wireName: r'code')
  String get code;

  @BuiltValueField(wireName: r'expires_at')
  String get expiresAt;

  CreatePairingCode201Response._();

  factory CreatePairingCode201Response([void updates(CreatePairingCode201ResponseBuilder b)]) = _$CreatePairingCode201Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreatePairingCode201ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreatePairingCode201Response> get serializer => _$CreatePairingCode201ResponseSerializer();
}

class _$CreatePairingCode201ResponseSerializer implements PrimitiveSerializer<CreatePairingCode201Response> {
  @override
  final Iterable<Type> types = const [CreatePairingCode201Response, _$CreatePairingCode201Response];

  @override
  final String wireName = r'CreatePairingCode201Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreatePairingCode201Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'person_id';
    yield serializers.serialize(
      object.personId,
      specifiedType: const FullType(String),
    );
    yield r'display_name';
    yield serializers.serialize(
      object.displayName,
      specifiedType: const FullType(String),
    );
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
    yield r'expires_at';
    yield serializers.serialize(
      object.expiresAt,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreatePairingCode201Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreatePairingCode201ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'person_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.personId = valueDes;
          break;
        case r'display_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displayName = valueDes;
          break;
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
        case r'expires_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.expiresAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreatePairingCode201Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreatePairingCode201ResponseBuilder();
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

