//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_snapshot200_response_program_items_inner.g.dart';

/// GetSnapshot200ResponseProgramItemsInner
///
/// Properties:
/// * [id] 
/// * [bfDayId] 
/// * [title] 
/// * [type] 
/// * [startsAt] 
/// * [endsAt] 
@BuiltValue()
abstract class GetSnapshot200ResponseProgramItemsInner implements Built<GetSnapshot200ResponseProgramItemsInner, GetSnapshot200ResponseProgramItemsInnerBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'bf_day_id')
  String get bfDayId;

  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'type')
  GetSnapshot200ResponseProgramItemsInnerTypeEnum get type;
  // enum typeEnum {  meal,  training,  maintenance,  rest,  other,  };

  @BuiltValueField(wireName: r'starts_at')
  String get startsAt;

  @BuiltValueField(wireName: r'ends_at')
  String get endsAt;

  GetSnapshot200ResponseProgramItemsInner._();

  factory GetSnapshot200ResponseProgramItemsInner([void updates(GetSnapshot200ResponseProgramItemsInnerBuilder b)]) = _$GetSnapshot200ResponseProgramItemsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetSnapshot200ResponseProgramItemsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetSnapshot200ResponseProgramItemsInner> get serializer => _$GetSnapshot200ResponseProgramItemsInnerSerializer();
}

class _$GetSnapshot200ResponseProgramItemsInnerSerializer implements PrimitiveSerializer<GetSnapshot200ResponseProgramItemsInner> {
  @override
  final Iterable<Type> types = const [GetSnapshot200ResponseProgramItemsInner, _$GetSnapshot200ResponseProgramItemsInner];

  @override
  final String wireName = r'GetSnapshot200ResponseProgramItemsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetSnapshot200ResponseProgramItemsInner object, {
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
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(GetSnapshot200ResponseProgramItemsInnerTypeEnum),
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
  }

  @override
  Object serialize(
    Serializers serializers,
    GetSnapshot200ResponseProgramItemsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetSnapshot200ResponseProgramItemsInnerBuilder result,
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
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GetSnapshot200ResponseProgramItemsInnerTypeEnum),
          ) as GetSnapshot200ResponseProgramItemsInnerTypeEnum;
          result.type = valueDes;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetSnapshot200ResponseProgramItemsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetSnapshot200ResponseProgramItemsInnerBuilder();
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

class GetSnapshot200ResponseProgramItemsInnerTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'meal')
  static const GetSnapshot200ResponseProgramItemsInnerTypeEnum meal = _$getSnapshot200ResponseProgramItemsInnerTypeEnum_meal;
  @BuiltValueEnumConst(wireName: r'training')
  static const GetSnapshot200ResponseProgramItemsInnerTypeEnum training = _$getSnapshot200ResponseProgramItemsInnerTypeEnum_training;
  @BuiltValueEnumConst(wireName: r'maintenance')
  static const GetSnapshot200ResponseProgramItemsInnerTypeEnum maintenance = _$getSnapshot200ResponseProgramItemsInnerTypeEnum_maintenance;
  @BuiltValueEnumConst(wireName: r'rest')
  static const GetSnapshot200ResponseProgramItemsInnerTypeEnum rest = _$getSnapshot200ResponseProgramItemsInnerTypeEnum_rest;
  @BuiltValueEnumConst(wireName: r'other')
  static const GetSnapshot200ResponseProgramItemsInnerTypeEnum other = _$getSnapshot200ResponseProgramItemsInnerTypeEnum_other;

  static Serializer<GetSnapshot200ResponseProgramItemsInnerTypeEnum> get serializer => _$getSnapshot200ResponseProgramItemsInnerTypeEnumSerializer;

  const GetSnapshot200ResponseProgramItemsInnerTypeEnum._(String name): super(name);

  static BuiltSet<GetSnapshot200ResponseProgramItemsInnerTypeEnum> get values => _$getSnapshot200ResponseProgramItemsInnerTypeEnumValues;
  static GetSnapshot200ResponseProgramItemsInnerTypeEnum valueOf(String name) => _$getSnapshot200ResponseProgramItemsInnerTypeEnumValueOf(name);
}

