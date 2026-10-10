//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_alarm200_response_double_crewed_inner.g.dart';

/// CreateAlarm200ResponseDoubleCrewedInner
///
/// Properties:
/// * [personId] 
/// * [displayName] 
/// * [vehicleIds] 
@BuiltValue()
abstract class CreateAlarm200ResponseDoubleCrewedInner implements Built<CreateAlarm200ResponseDoubleCrewedInner, CreateAlarm200ResponseDoubleCrewedInnerBuilder> {
  @BuiltValueField(wireName: r'person_id')
  String get personId;

  @BuiltValueField(wireName: r'display_name')
  String get displayName;

  @BuiltValueField(wireName: r'vehicle_ids')
  BuiltList<String> get vehicleIds;

  CreateAlarm200ResponseDoubleCrewedInner._();

  factory CreateAlarm200ResponseDoubleCrewedInner([void updates(CreateAlarm200ResponseDoubleCrewedInnerBuilder b)]) = _$CreateAlarm200ResponseDoubleCrewedInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateAlarm200ResponseDoubleCrewedInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateAlarm200ResponseDoubleCrewedInner> get serializer => _$CreateAlarm200ResponseDoubleCrewedInnerSerializer();
}

class _$CreateAlarm200ResponseDoubleCrewedInnerSerializer implements PrimitiveSerializer<CreateAlarm200ResponseDoubleCrewedInner> {
  @override
  final Iterable<Type> types = const [CreateAlarm200ResponseDoubleCrewedInner, _$CreateAlarm200ResponseDoubleCrewedInner];

  @override
  final String wireName = r'CreateAlarm200ResponseDoubleCrewedInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateAlarm200ResponseDoubleCrewedInner object, {
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
    yield r'vehicle_ids';
    yield serializers.serialize(
      object.vehicleIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateAlarm200ResponseDoubleCrewedInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateAlarm200ResponseDoubleCrewedInnerBuilder result,
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
  CreateAlarm200ResponseDoubleCrewedInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateAlarm200ResponseDoubleCrewedInnerBuilder();
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

