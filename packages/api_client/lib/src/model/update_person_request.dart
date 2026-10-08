//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_person_request.g.dart';

/// UpdatePersonRequest
///
/// Properties:
/// * [displayName] 
/// * [personType] 
/// * [permission] 
/// * [active] 
@BuiltValue()
abstract class UpdatePersonRequest implements Built<UpdatePersonRequest, UpdatePersonRequestBuilder> {
  @BuiltValueField(wireName: r'display_name')
  String? get displayName;

  @BuiltValueField(wireName: r'person_type')
  UpdatePersonRequestPersonTypeEnum? get personType;
  // enum personTypeEnum {  youth,  supervisor,  };

  @BuiltValueField(wireName: r'permission')
  UpdatePersonRequestPermissionEnum? get permission;
  // enum permissionEnum {  crew,  preparation,  dispatch,  admin,  };

  @BuiltValueField(wireName: r'active')
  bool? get active;

  UpdatePersonRequest._();

  factory UpdatePersonRequest([void updates(UpdatePersonRequestBuilder b)]) = _$UpdatePersonRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdatePersonRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdatePersonRequest> get serializer => _$UpdatePersonRequestSerializer();
}

class _$UpdatePersonRequestSerializer implements PrimitiveSerializer<UpdatePersonRequest> {
  @override
  final Iterable<Type> types = const [UpdatePersonRequest, _$UpdatePersonRequest];

  @override
  final String wireName = r'UpdatePersonRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdatePersonRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.displayName != null) {
      yield r'display_name';
      yield serializers.serialize(
        object.displayName,
        specifiedType: const FullType(String),
      );
    }
    if (object.personType != null) {
      yield r'person_type';
      yield serializers.serialize(
        object.personType,
        specifiedType: const FullType(UpdatePersonRequestPersonTypeEnum),
      );
    }
    if (object.permission != null) {
      yield r'permission';
      yield serializers.serialize(
        object.permission,
        specifiedType: const FullType(UpdatePersonRequestPermissionEnum),
      );
    }
    if (object.active != null) {
      yield r'active';
      yield serializers.serialize(
        object.active,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdatePersonRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdatePersonRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'display_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displayName = valueDes;
          break;
        case r'person_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UpdatePersonRequestPersonTypeEnum),
          ) as UpdatePersonRequestPersonTypeEnum;
          result.personType = valueDes;
          break;
        case r'permission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UpdatePersonRequestPermissionEnum),
          ) as UpdatePersonRequestPermissionEnum;
          result.permission = valueDes;
          break;
        case r'active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.active = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdatePersonRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdatePersonRequestBuilder();
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

class UpdatePersonRequestPersonTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'youth')
  static const UpdatePersonRequestPersonTypeEnum youth = _$updatePersonRequestPersonTypeEnum_youth;
  @BuiltValueEnumConst(wireName: r'supervisor')
  static const UpdatePersonRequestPersonTypeEnum supervisor = _$updatePersonRequestPersonTypeEnum_supervisor;

  static Serializer<UpdatePersonRequestPersonTypeEnum> get serializer => _$updatePersonRequestPersonTypeEnumSerializer;

  const UpdatePersonRequestPersonTypeEnum._(String name): super(name);

  static BuiltSet<UpdatePersonRequestPersonTypeEnum> get values => _$updatePersonRequestPersonTypeEnumValues;
  static UpdatePersonRequestPersonTypeEnum valueOf(String name) => _$updatePersonRequestPersonTypeEnumValueOf(name);
}

class UpdatePersonRequestPermissionEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'crew')
  static const UpdatePersonRequestPermissionEnum crew = _$updatePersonRequestPermissionEnum_crew;
  @BuiltValueEnumConst(wireName: r'preparation')
  static const UpdatePersonRequestPermissionEnum preparation = _$updatePersonRequestPermissionEnum_preparation;
  @BuiltValueEnumConst(wireName: r'dispatch')
  static const UpdatePersonRequestPermissionEnum dispatch = _$updatePersonRequestPermissionEnum_dispatch;
  @BuiltValueEnumConst(wireName: r'admin')
  static const UpdatePersonRequestPermissionEnum admin = _$updatePersonRequestPermissionEnum_admin;

  static Serializer<UpdatePersonRequestPermissionEnum> get serializer => _$updatePersonRequestPermissionEnumSerializer;

  const UpdatePersonRequestPermissionEnum._(String name): super(name);

  static BuiltSet<UpdatePersonRequestPermissionEnum> get values => _$updatePersonRequestPermissionEnumValues;
  static UpdatePersonRequestPermissionEnum valueOf(String name) => _$updatePersonRequestPermissionEnumValueOf(name);
}

