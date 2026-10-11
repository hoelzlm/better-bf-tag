//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_program_item_request.g.dart';

/// UpdateProgramItemRequest
///
/// Properties:
/// * [title] 
/// * [type] 
/// * [startsAt] 
/// * [endsAt] 
@BuiltValue()
abstract class UpdateProgramItemRequest implements Built<UpdateProgramItemRequest, UpdateProgramItemRequestBuilder> {
  @BuiltValueField(wireName: r'title')
  String? get title;

  @BuiltValueField(wireName: r'type')
  UpdateProgramItemRequestTypeEnum? get type;
  // enum typeEnum {  meal,  training,  maintenance,  rest,  other,  };

  @BuiltValueField(wireName: r'starts_at')
  DateTime? get startsAt;

  @BuiltValueField(wireName: r'ends_at')
  DateTime? get endsAt;

  UpdateProgramItemRequest._();

  factory UpdateProgramItemRequest([void updates(UpdateProgramItemRequestBuilder b)]) = _$UpdateProgramItemRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateProgramItemRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateProgramItemRequest> get serializer => _$UpdateProgramItemRequestSerializer();
}

class _$UpdateProgramItemRequestSerializer implements PrimitiveSerializer<UpdateProgramItemRequest> {
  @override
  final Iterable<Type> types = const [UpdateProgramItemRequest, _$UpdateProgramItemRequest];

  @override
  final String wireName = r'UpdateProgramItemRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateProgramItemRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.title != null) {
      yield r'title';
      yield serializers.serialize(
        object.title,
        specifiedType: const FullType(String),
      );
    }
    if (object.type != null) {
      yield r'type';
      yield serializers.serialize(
        object.type,
        specifiedType: const FullType(UpdateProgramItemRequestTypeEnum),
      );
    }
    if (object.startsAt != null) {
      yield r'starts_at';
      yield serializers.serialize(
        object.startsAt,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.endsAt != null) {
      yield r'ends_at';
      yield serializers.serialize(
        object.endsAt,
        specifiedType: const FullType(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateProgramItemRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateProgramItemRequestBuilder result,
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
            specifiedType: const FullType(UpdateProgramItemRequestTypeEnum),
          ) as UpdateProgramItemRequestTypeEnum;
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
  UpdateProgramItemRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateProgramItemRequestBuilder();
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

class UpdateProgramItemRequestTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'meal')
  static const UpdateProgramItemRequestTypeEnum meal = _$updateProgramItemRequestTypeEnum_meal;
  @BuiltValueEnumConst(wireName: r'training')
  static const UpdateProgramItemRequestTypeEnum training = _$updateProgramItemRequestTypeEnum_training;
  @BuiltValueEnumConst(wireName: r'maintenance')
  static const UpdateProgramItemRequestTypeEnum maintenance = _$updateProgramItemRequestTypeEnum_maintenance;
  @BuiltValueEnumConst(wireName: r'rest')
  static const UpdateProgramItemRequestTypeEnum rest = _$updateProgramItemRequestTypeEnum_rest;
  @BuiltValueEnumConst(wireName: r'other')
  static const UpdateProgramItemRequestTypeEnum other = _$updateProgramItemRequestTypeEnum_other;

  static Serializer<UpdateProgramItemRequestTypeEnum> get serializer => _$updateProgramItemRequestTypeEnumSerializer;

  const UpdateProgramItemRequestTypeEnum._(String name): super(name);

  static BuiltSet<UpdateProgramItemRequestTypeEnum> get values => _$updateProgramItemRequestTypeEnumValues;
  static UpdateProgramItemRequestTypeEnum valueOf(String name) => _$updateProgramItemRequestTypeEnumValueOf(name);
}

