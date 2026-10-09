//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_snapshot200_response_shifts_inner_crew_inner.g.dart';

/// GetSnapshot200ResponseShiftsInnerCrewInner
///
/// Properties:
/// * [vehicleId] 
/// * [personId] 
/// * [displayName] 
/// * [function_] 
@BuiltValue()
abstract class GetSnapshot200ResponseShiftsInnerCrewInner implements Built<GetSnapshot200ResponseShiftsInnerCrewInner, GetSnapshot200ResponseShiftsInnerCrewInnerBuilder> {
  @BuiltValueField(wireName: r'vehicle_id')
  String get vehicleId;

  @BuiltValueField(wireName: r'person_id')
  String get personId;

  @BuiltValueField(wireName: r'display_name')
  String get displayName;

  @BuiltValueField(wireName: r'function')
  String get function_;

  GetSnapshot200ResponseShiftsInnerCrewInner._();

  factory GetSnapshot200ResponseShiftsInnerCrewInner([void updates(GetSnapshot200ResponseShiftsInnerCrewInnerBuilder b)]) = _$GetSnapshot200ResponseShiftsInnerCrewInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetSnapshot200ResponseShiftsInnerCrewInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetSnapshot200ResponseShiftsInnerCrewInner> get serializer => _$GetSnapshot200ResponseShiftsInnerCrewInnerSerializer();
}

class _$GetSnapshot200ResponseShiftsInnerCrewInnerSerializer implements PrimitiveSerializer<GetSnapshot200ResponseShiftsInnerCrewInner> {
  @override
  final Iterable<Type> types = const [GetSnapshot200ResponseShiftsInnerCrewInner, _$GetSnapshot200ResponseShiftsInnerCrewInner];

  @override
  final String wireName = r'GetSnapshot200ResponseShiftsInnerCrewInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetSnapshot200ResponseShiftsInnerCrewInner object, {
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
    yield r'display_name';
    yield serializers.serialize(
      object.displayName,
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
    GetSnapshot200ResponseShiftsInnerCrewInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetSnapshot200ResponseShiftsInnerCrewInnerBuilder result,
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
        case r'display_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displayName = valueDes;
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
  GetSnapshot200ResponseShiftsInnerCrewInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetSnapshot200ResponseShiftsInnerCrewInnerBuilder();
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

