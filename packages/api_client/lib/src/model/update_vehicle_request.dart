//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_vehicle_request.g.dart';

/// UpdateVehicleRequest
///
/// Properties:
/// * [callSign] 
/// * [shortName] 
/// * [type] 
/// * [active] 
@BuiltValue()
abstract class UpdateVehicleRequest implements Built<UpdateVehicleRequest, UpdateVehicleRequestBuilder> {
  @BuiltValueField(wireName: r'call_sign')
  String? get callSign;

  @BuiltValueField(wireName: r'short_name')
  String? get shortName;

  @BuiltValueField(wireName: r'type')
  String? get type;

  @BuiltValueField(wireName: r'active')
  bool? get active;

  UpdateVehicleRequest._();

  factory UpdateVehicleRequest([void updates(UpdateVehicleRequestBuilder b)]) = _$UpdateVehicleRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateVehicleRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateVehicleRequest> get serializer => _$UpdateVehicleRequestSerializer();
}

class _$UpdateVehicleRequestSerializer implements PrimitiveSerializer<UpdateVehicleRequest> {
  @override
  final Iterable<Type> types = const [UpdateVehicleRequest, _$UpdateVehicleRequest];

  @override
  final String wireName = r'UpdateVehicleRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateVehicleRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.callSign != null) {
      yield r'call_sign';
      yield serializers.serialize(
        object.callSign,
        specifiedType: const FullType(String),
      );
    }
    if (object.shortName != null) {
      yield r'short_name';
      yield serializers.serialize(
        object.shortName,
        specifiedType: const FullType(String),
      );
    }
    if (object.type != null) {
      yield r'type';
      yield serializers.serialize(
        object.type,
        specifiedType: const FullType(String),
      );
    }
    if (object.active != null) {
      yield r'active';
      yield serializers.serialize(
        object.active,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateVehicleRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateVehicleRequestBuilder result,
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
        case r'active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.active = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateVehicleRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateVehicleRequestBuilder();
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

