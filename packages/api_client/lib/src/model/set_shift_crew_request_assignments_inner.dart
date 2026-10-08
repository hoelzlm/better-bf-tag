//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'set_shift_crew_request_assignments_inner.g.dart';

/// SetShiftCrewRequestAssignmentsInner
///
/// Properties:
/// * [vehicleId] 
/// * [personId] 
/// * [function_] 
@BuiltValue()
abstract class SetShiftCrewRequestAssignmentsInner implements Built<SetShiftCrewRequestAssignmentsInner, SetShiftCrewRequestAssignmentsInnerBuilder> {
  @BuiltValueField(wireName: r'vehicle_id')
  String get vehicleId;

  @BuiltValueField(wireName: r'person_id')
  String get personId;

  @BuiltValueField(wireName: r'function')
  String get function_;

  SetShiftCrewRequestAssignmentsInner._();

  factory SetShiftCrewRequestAssignmentsInner([void updates(SetShiftCrewRequestAssignmentsInnerBuilder b)]) = _$SetShiftCrewRequestAssignmentsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SetShiftCrewRequestAssignmentsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SetShiftCrewRequestAssignmentsInner> get serializer => _$SetShiftCrewRequestAssignmentsInnerSerializer();
}

class _$SetShiftCrewRequestAssignmentsInnerSerializer implements PrimitiveSerializer<SetShiftCrewRequestAssignmentsInner> {
  @override
  final Iterable<Type> types = const [SetShiftCrewRequestAssignmentsInner, _$SetShiftCrewRequestAssignmentsInner];

  @override
  final String wireName = r'SetShiftCrewRequestAssignmentsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SetShiftCrewRequestAssignmentsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'vehicle_id';
    yield serializers.serialize(
      object.vehicleId,
      specifiedType: const FullType(String),
    );
    yield r'person_id';
    yield serializers.serialize(
      object.personId,
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
    SetShiftCrewRequestAssignmentsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SetShiftCrewRequestAssignmentsInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'vehicle_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vehicleId = valueDes;
          break;
        case r'person_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.personId = valueDes;
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
  SetShiftCrewRequestAssignmentsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SetShiftCrewRequestAssignmentsInnerBuilder();
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

