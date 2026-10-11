//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_program_item_request.g.dart';

/// CreateProgramItemRequest
///
/// Properties:
/// * [title] 
/// * [type] 
/// * [startsAt] 
/// * [endsAt] 
@BuiltValue()
abstract class CreateProgramItemRequest implements Built<CreateProgramItemRequest, CreateProgramItemRequestBuilder> {
  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'type')
  CreateProgramItemRequestTypeEnum get type;
  // enum typeEnum {  meal,  training,  maintenance,  rest,  other,  };

  @BuiltValueField(wireName: r'starts_at')
  DateTime get startsAt;

  @BuiltValueField(wireName: r'ends_at')
  DateTime get endsAt;

  CreateProgramItemRequest._();

  factory CreateProgramItemRequest([void updates(CreateProgramItemRequestBuilder b)]) = _$CreateProgramItemRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateProgramItemRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateProgramItemRequest> get serializer => _$CreateProgramItemRequestSerializer();
}

class _$CreateProgramItemRequestSerializer implements PrimitiveSerializer<CreateProgramItemRequest> {
  @override
  final Iterable<Type> types = const [CreateProgramItemRequest, _$CreateProgramItemRequest];

  @override
  final String wireName = r'CreateProgramItemRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateProgramItemRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(CreateProgramItemRequestTypeEnum),
    );
    yield r'starts_at';
    yield serializers.serialize(
      object.startsAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'ends_at';
    yield serializers.serialize(
      object.endsAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateProgramItemRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateProgramItemRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
            specifiedType: const FullType(CreateProgramItemRequestTypeEnum),
          ) as CreateProgramItemRequestTypeEnum;
          result.type = valueDes;
          break;
        case r'starts_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.startsAt = valueDes;
          break;
        case r'ends_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
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
  CreateProgramItemRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateProgramItemRequestBuilder();
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

class CreateProgramItemRequestTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'meal')
  static const CreateProgramItemRequestTypeEnum meal = _$createProgramItemRequestTypeEnum_meal;
  @BuiltValueEnumConst(wireName: r'training')
  static const CreateProgramItemRequestTypeEnum training = _$createProgramItemRequestTypeEnum_training;
  @BuiltValueEnumConst(wireName: r'maintenance')
  static const CreateProgramItemRequestTypeEnum maintenance = _$createProgramItemRequestTypeEnum_maintenance;
  @BuiltValueEnumConst(wireName: r'rest')
  static const CreateProgramItemRequestTypeEnum rest = _$createProgramItemRequestTypeEnum_rest;
  @BuiltValueEnumConst(wireName: r'other')
  static const CreateProgramItemRequestTypeEnum other = _$createProgramItemRequestTypeEnum_other;

  static Serializer<CreateProgramItemRequestTypeEnum> get serializer => _$createProgramItemRequestTypeEnumSerializer;

  const CreateProgramItemRequestTypeEnum._(String name): super(name);

  static BuiltSet<CreateProgramItemRequestTypeEnum> get values => _$createProgramItemRequestTypeEnumValues;
  static CreateProgramItemRequestTypeEnum valueOf(String name) => _$createProgramItemRequestTypeEnumValueOf(name);
}

