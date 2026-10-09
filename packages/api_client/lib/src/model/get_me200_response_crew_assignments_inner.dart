//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_me200_response_crew_assignments_inner.g.dart';

/// GetMe200ResponseCrewAssignmentsInner
///
/// Properties:
/// * [shiftId] 
/// * [vehicleId] 
/// * [function_] 
@BuiltValue()
abstract class GetMe200ResponseCrewAssignmentsInner implements Built<GetMe200ResponseCrewAssignmentsInner, GetMe200ResponseCrewAssignmentsInnerBuilder> {
  @BuiltValueField(wireName: r'shift_id')
  String get shiftId;

  @BuiltValueField(wireName: r'vehicle_id')
  String get vehicleId;

  @BuiltValueField(wireName: r'function')
  String get function_;

  GetMe200ResponseCrewAssignmentsInner._();

  factory GetMe200ResponseCrewAssignmentsInner([void updates(GetMe200ResponseCrewAssignmentsInnerBuilder b)]) = _$GetMe200ResponseCrewAssignmentsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetMe200ResponseCrewAssignmentsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetMe200ResponseCrewAssignmentsInner> get serializer => _$GetMe200ResponseCrewAssignmentsInnerSerializer();
}

class _$GetMe200ResponseCrewAssignmentsInnerSerializer implements PrimitiveSerializer<GetMe200ResponseCrewAssignmentsInner> {
  @override
  final Iterable<Type> types = const [GetMe200ResponseCrewAssignmentsInner, _$GetMe200ResponseCrewAssignmentsInner];

  @override
  final String wireName = r'GetMe200ResponseCrewAssignmentsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetMe200ResponseCrewAssignmentsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'shift_id';
    yield serializers.serialize(
      object.shiftId,
      specifiedType: const FullType(String),
    );
    yield r'vehicle_id';
    yield serializers.serialize(
      object.vehicleId,
      specifiedType: const FullType(String),
    );
    yield r'function';
    yield serializers.serialize(
      object.function_,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetMe200ResponseCrewAssignmentsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetMe200ResponseCrewAssignmentsInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'shift_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.shiftId = valueDes;
          break;
        case r'vehicle_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vehicleId = valueDes;
          break;
        case r'function':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.function_ = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetMe200ResponseCrewAssignmentsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetMe200ResponseCrewAssignmentsInnerBuilder();
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

