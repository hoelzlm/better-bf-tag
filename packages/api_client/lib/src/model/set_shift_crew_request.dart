//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bftag_api_client/src/model/set_shift_crew_request_assignments_inner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'set_shift_crew_request.g.dart';

/// SetShiftCrewRequest
///
/// Properties:
/// * [assignments] 
@BuiltValue()
abstract class SetShiftCrewRequest implements Built<SetShiftCrewRequest, SetShiftCrewRequestBuilder> {
  @BuiltValueField(wireName: r'assignments')
  BuiltList<SetShiftCrewRequestAssignmentsInner> get assignments;

  SetShiftCrewRequest._();

  factory SetShiftCrewRequest([void updates(SetShiftCrewRequestBuilder b)]) = _$SetShiftCrewRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SetShiftCrewRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SetShiftCrewRequest> get serializer => _$SetShiftCrewRequestSerializer();
}

class _$SetShiftCrewRequestSerializer implements PrimitiveSerializer<SetShiftCrewRequest> {
  @override
  final Iterable<Type> types = const [SetShiftCrewRequest, _$SetShiftCrewRequest];

  @override
  final String wireName = r'SetShiftCrewRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SetShiftCrewRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'assignments';
    yield serializers.serialize(
      object.assignments,
      specifiedType: const FullType(BuiltList, [FullType(SetShiftCrewRequestAssignmentsInner)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SetShiftCrewRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SetShiftCrewRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'assignments':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(SetShiftCrewRequestAssignmentsInner)]),
          ) as BuiltList<SetShiftCrewRequestAssignmentsInner>;
          result.assignments.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SetShiftCrewRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SetShiftCrewRequestBuilder();
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

