//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reorder_vehicles_request.g.dart';

/// ReorderVehiclesRequest
///
/// Properties:
/// * [vehicleIds] 
@BuiltValue()
abstract class ReorderVehiclesRequest implements Built<ReorderVehiclesRequest, ReorderVehiclesRequestBuilder> {
  @BuiltValueField(wireName: r'vehicle_ids')
  BuiltList<String> get vehicleIds;

  ReorderVehiclesRequest._();

  factory ReorderVehiclesRequest([void updates(ReorderVehiclesRequestBuilder b)]) = _$ReorderVehiclesRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReorderVehiclesRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReorderVehiclesRequest> get serializer => _$ReorderVehiclesRequestSerializer();
}

class _$ReorderVehiclesRequestSerializer implements PrimitiveSerializer<ReorderVehiclesRequest> {
  @override
  final Iterable<Type> types = const [ReorderVehiclesRequest, _$ReorderVehiclesRequest];

  @override
  final String wireName = r'ReorderVehiclesRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReorderVehiclesRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'vehicle_ids';
    yield serializers.serialize(
      object.vehicleIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReorderVehiclesRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReorderVehiclesRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'vehicle_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.vehicleIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReorderVehiclesRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReorderVehiclesRequestBuilder();
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

