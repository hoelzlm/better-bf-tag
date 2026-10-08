//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_monitor_pairing_code201_response.g.dart';

/// CreateMonitorPairingCode201Response
///
/// Properties:
/// * [monitorId] 
/// * [name] 
/// * [code] 
/// * [expiresAt] 
@BuiltValue()
abstract class CreateMonitorPairingCode201Response implements Built<CreateMonitorPairingCode201Response, CreateMonitorPairingCode201ResponseBuilder> {
  @BuiltValueField(wireName: r'monitor_id')
  String get monitorId;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'code')
  String get code;

  @BuiltValueField(wireName: r'expires_at')
  String get expiresAt;

  CreateMonitorPairingCode201Response._();

  factory CreateMonitorPairingCode201Response([void updates(CreateMonitorPairingCode201ResponseBuilder b)]) = _$CreateMonitorPairingCode201Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateMonitorPairingCode201ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateMonitorPairingCode201Response> get serializer => _$CreateMonitorPairingCode201ResponseSerializer();
}

class _$CreateMonitorPairingCode201ResponseSerializer implements PrimitiveSerializer<CreateMonitorPairingCode201Response> {
  @override
  final Iterable<Type> types = const [CreateMonitorPairingCode201Response, _$CreateMonitorPairingCode201Response];

  @override
  final String wireName = r'CreateMonitorPairingCode201Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateMonitorPairingCode201Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'monitor_id';
    yield serializers.serialize(
      object.monitorId,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
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
    CreateMonitorPairingCode201Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateMonitorPairingCode201ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'monitor_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.monitorId = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
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
  CreateMonitorPairingCode201Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateMonitorPairingCode201ResponseBuilder();
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

