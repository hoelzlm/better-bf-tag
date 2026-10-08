//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_vehicle_request.g.dart';

/// CreateVehicleRequest
///
/// Properties:
/// * [callSign] 
/// * [shortName] 
/// * [type] 
@BuiltValue()
abstract class CreateVehicleRequest implements Built<CreateVehicleRequest, CreateVehicleRequestBuilder> {
  @BuiltValueField(wireName: r'call_sign')
  String get callSign;

  @BuiltValueField(wireName: r'short_name')
  String get shortName;

  @BuiltValueField(wireName: r'type')
  String get type;

  CreateVehicleRequest._();

  factory CreateVehicleRequest([void updates(CreateVehicleRequestBuilder b)]) = _$CreateVehicleRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateVehicleRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateVehicleRequest> get serializer => _$CreateVehicleRequestSerializer();
}

class _$CreateVehicleRequestSerializer implements PrimitiveSerializer<CreateVehicleRequest> {
  @override
  final Iterable<Type> types = const [CreateVehicleRequest, _$CreateVehicleRequest];

  @override
  final String wireName = r'CreateVehicleRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateVehicleRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'call_sign';
    yield serializers.serialize(
      object.callSign,
      specifiedType: const FullType(String),
    );
    yield r'short_name';
    yield serializers.serialize(
      object.shortName,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateVehicleRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateVehicleRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'call_sign':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.callSign = valueDes;
          break;
        case r'short_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.shortName = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.type = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateVehicleRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateVehicleRequestBuilder();
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

