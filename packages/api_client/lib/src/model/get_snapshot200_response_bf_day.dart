//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_snapshot200_response_bf_day.g.dart';

/// GetSnapshot200ResponseBfDay
///
/// Properties:
/// * [id] 
/// * [name] 
/// * [startsAt] 
/// * [endsAt] 
/// * [state] 
/// * [anonymizedAt] 
/// * [createdAt] 
@BuiltValue()
abstract class GetSnapshot200ResponseBfDay implements Built<GetSnapshot200ResponseBfDay, GetSnapshot200ResponseBfDayBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'starts_at')
  String get startsAt;

  @BuiltValueField(wireName: r'ends_at')
  String get endsAt;

  @BuiltValueField(wireName: r'state')
  GetSnapshot200ResponseBfDayStateEnum get state;
  // enum stateEnum {  planning,  running,  ended,  };

  @BuiltValueField(wireName: r'anonymized_at')
  String? get anonymizedAt;

  @BuiltValueField(wireName: r'created_at')
  String get createdAt;

  GetSnapshot200ResponseBfDay._();

  factory GetSnapshot200ResponseBfDay([void updates(GetSnapshot200ResponseBfDayBuilder b)]) = _$GetSnapshot200ResponseBfDay;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetSnapshot200ResponseBfDayBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetSnapshot200ResponseBfDay> get serializer => _$GetSnapshot200ResponseBfDaySerializer();
}

class _$GetSnapshot200ResponseBfDaySerializer implements PrimitiveSerializer<GetSnapshot200ResponseBfDay> {
  @override
  final Iterable<Type> types = const [GetSnapshot200ResponseBfDay, _$GetSnapshot200ResponseBfDay];

  @override
  final String wireName = r'GetSnapshot200ResponseBfDay';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetSnapshot200ResponseBfDay object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
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
    yield r'state';
    yield serializers.serialize(
      object.state,
      specifiedType: const FullType(GetSnapshot200ResponseBfDayStateEnum),
    );
    yield r'anonymized_at';
    yield object.anonymizedAt == null ? null : serializers.serialize(
      object.anonymizedAt,
      specifiedType: const FullType.nullable(String),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetSnapshot200ResponseBfDay object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetSnapshot200ResponseBfDayBuilder result,
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
        case r'state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GetSnapshot200ResponseBfDayStateEnum),
          ) as GetSnapshot200ResponseBfDayStateEnum;
          result.state = valueDes;
          break;
        case r'anonymized_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.anonymizedAt = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.createdAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetSnapshot200ResponseBfDay deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetSnapshot200ResponseBfDayBuilder();
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

class GetSnapshot200ResponseBfDayStateEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'planning')
  static const GetSnapshot200ResponseBfDayStateEnum planning = _$getSnapshot200ResponseBfDayStateEnum_planning;
  @BuiltValueEnumConst(wireName: r'running')
  static const GetSnapshot200ResponseBfDayStateEnum running = _$getSnapshot200ResponseBfDayStateEnum_running;
  @BuiltValueEnumConst(wireName: r'ended')
  static const GetSnapshot200ResponseBfDayStateEnum ended = _$getSnapshot200ResponseBfDayStateEnum_ended;

  static Serializer<GetSnapshot200ResponseBfDayStateEnum> get serializer => _$getSnapshot200ResponseBfDayStateEnumSerializer;

  const GetSnapshot200ResponseBfDayStateEnum._(String name): super(name);

  static BuiltSet<GetSnapshot200ResponseBfDayStateEnum> get values => _$getSnapshot200ResponseBfDayStateEnumValues;
  static GetSnapshot200ResponseBfDayStateEnum valueOf(String name) => _$getSnapshot200ResponseBfDayStateEnumValueOf(name);
}

