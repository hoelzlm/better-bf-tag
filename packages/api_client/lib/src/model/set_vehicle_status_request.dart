//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'set_vehicle_status_request.g.dart';

/// SetVehicleStatusRequest
///
/// Properties:
/// * [status] 
@BuiltValue()
abstract class SetVehicleStatusRequest implements Built<SetVehicleStatusRequest, SetVehicleStatusRequestBuilder> {
  @BuiltValueField(wireName: r'status')
  int get status;

  SetVehicleStatusRequest._();

  factory SetVehicleStatusRequest([void updates(SetVehicleStatusRequestBuilder b)]) = _$SetVehicleStatusRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SetVehicleStatusRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SetVehicleStatusRequest> get serializer => _$SetVehicleStatusRequestSerializer();
}

class _$SetVehicleStatusRequestSerializer implements PrimitiveSerializer<SetVehicleStatusRequest> {
  @override
  final Iterable<Type> types = const [SetVehicleStatusRequest, _$SetVehicleStatusRequest];

  @override
  final String wireName = r'SetVehicleStatusRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SetVehicleStatusRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SetVehicleStatusRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SetVehicleStatusRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SetVehicleStatusRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SetVehicleStatusRequestBuilder();
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

