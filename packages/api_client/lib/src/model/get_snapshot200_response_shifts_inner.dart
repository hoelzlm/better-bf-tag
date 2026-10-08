//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bftag_api_client/src/model/get_snapshot200_response_shifts_inner_crew_inner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_snapshot200_response_shifts_inner.g.dart';

/// GetSnapshot200ResponseShiftsInner
///
/// Properties:
/// * [id] 
/// * [bfDayId] 
/// * [name] 
/// * [startsAt] 
/// * [endsAt] 
/// * [crew] 
@BuiltValue()
abstract class GetSnapshot200ResponseShiftsInner implements Built<GetSnapshot200ResponseShiftsInner, GetSnapshot200ResponseShiftsInnerBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'bf_day_id')
  String get bfDayId;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'starts_at')
  String get startsAt;

  @BuiltValueField(wireName: r'ends_at')
  String get endsAt;

  @BuiltValueField(wireName: r'crew')
  BuiltList<GetSnapshot200ResponseShiftsInnerCrewInner> get crew;

  GetSnapshot200ResponseShiftsInner._();

  factory GetSnapshot200ResponseShiftsInner([void updates(GetSnapshot200ResponseShiftsInnerBuilder b)]) = _$GetSnapshot200ResponseShiftsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetSnapshot200ResponseShiftsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetSnapshot200ResponseShiftsInner> get serializer => _$GetSnapshot200ResponseShiftsInnerSerializer();
}

class _$GetSnapshot200ResponseShiftsInnerSerializer implements PrimitiveSerializer<GetSnapshot200ResponseShiftsInner> {
  @override
  final Iterable<Type> types = const [GetSnapshot200ResponseShiftsInner, _$GetSnapshot200ResponseShiftsInner];

  @override
  final String wireName = r'GetSnapshot200ResponseShiftsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetSnapshot200ResponseShiftsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'bf_day_id';
    yield serializers.serialize(
      object.bfDayId,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'starts_at';
    yield serializers.serialize(
      object.startsAt,
      specifiedType: const FullType(String),
    );
    yield r'ends_at';
    yield serializers.serialize(
      object.endsAt,
      specifiedType: const FullType(String),
    );
    yield r'crew';
    yield serializers.serialize(
      object.crew,
      specifiedType: const FullType(BuiltList, [FullType(GetSnapshot200ResponseShiftsInnerCrewInner)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetSnapshot200ResponseShiftsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetSnapshot200ResponseShiftsInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'bf_day_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.bfDayId = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'starts_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.startsAt = valueDes;
          break;
        case r'ends_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.endsAt = valueDes;
          break;
        case r'crew':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(GetSnapshot200ResponseShiftsInnerCrewInner)]),
          ) as BuiltList<GetSnapshot200ResponseShiftsInnerCrewInner>;
          result.crew.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetSnapshot200ResponseShiftsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetSnapshot200ResponseShiftsInnerBuilder();
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

