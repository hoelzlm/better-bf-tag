//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_person_request.g.dart';

/// CreatePersonRequest
///
/// Properties:
/// * [displayName] 
/// * [personType] 
/// * [permission] 
@BuiltValue()
abstract class CreatePersonRequest implements Built<CreatePersonRequest, CreatePersonRequestBuilder> {
  @BuiltValueField(wireName: r'display_name')
  String get displayName;

  @BuiltValueField(wireName: r'person_type')
  CreatePersonRequestPersonTypeEnum get personType;
  // enum personTypeEnum {  youth,  supervisor,  };

  @BuiltValueField(wireName: r'permission')
  CreatePersonRequestPermissionEnum get permission;
  // enum permissionEnum {  crew,  preparation,  dispatch,  admin,  };

  CreatePersonRequest._();

  factory CreatePersonRequest([void updates(CreatePersonRequestBuilder b)]) = _$CreatePersonRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreatePersonRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreatePersonRequest> get serializer => _$CreatePersonRequestSerializer();
}

class _$CreatePersonRequestSerializer implements PrimitiveSerializer<CreatePersonRequest> {
  @override
  final Iterable<Type> types = const [CreatePersonRequest, _$CreatePersonRequest];

  @override
  final String wireName = r'CreatePersonRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreatePersonRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'display_name';
    yield serializers.serialize(
      object.displayName,
      specifiedType: const FullType(String),
    );
    yield r'person_type';
    yield serializers.serialize(
      object.personType,
      specifiedType: const FullType(CreatePersonRequestPersonTypeEnum),
    );
    yield r'permission';
    yield serializers.serialize(
      object.permission,
      specifiedType: const FullType(CreatePersonRequestPermissionEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreatePersonRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreatePersonRequestBuilder result,
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
            specifiedType: const FullType(CreatePersonRequestPersonTypeEnum),
          ) as CreatePersonRequestPersonTypeEnum;
          result.personType = valueDes;
          break;
        case r'permission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CreatePersonRequestPermissionEnum),
          ) as CreatePersonRequestPermissionEnum;
          result.permission = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreatePersonRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreatePersonRequestBuilder();
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

class CreatePersonRequestPersonTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'youth')
  static const CreatePersonRequestPersonTypeEnum youth = _$createPersonRequestPersonTypeEnum_youth;
  @BuiltValueEnumConst(wireName: r'supervisor')
  static const CreatePersonRequestPersonTypeEnum supervisor = _$createPersonRequestPersonTypeEnum_supervisor;

  static Serializer<CreatePersonRequestPersonTypeEnum> get serializer => _$createPersonRequestPersonTypeEnumSerializer;

  const CreatePersonRequestPersonTypeEnum._(String name): super(name);

  static BuiltSet<CreatePersonRequestPersonTypeEnum> get values => _$createPersonRequestPersonTypeEnumValues;
  static CreatePersonRequestPersonTypeEnum valueOf(String name) => _$createPersonRequestPersonTypeEnumValueOf(name);
}

class CreatePersonRequestPermissionEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'crew')
  static const CreatePersonRequestPermissionEnum crew = _$createPersonRequestPermissionEnum_crew;
  @BuiltValueEnumConst(wireName: r'preparation')
  static const CreatePersonRequestPermissionEnum preparation = _$createPersonRequestPermissionEnum_preparation;
  @BuiltValueEnumConst(wireName: r'dispatch')
  static const CreatePersonRequestPermissionEnum dispatch = _$createPersonRequestPermissionEnum_dispatch;
  @BuiltValueEnumConst(wireName: r'admin')
  static const CreatePersonRequestPermissionEnum admin = _$createPersonRequestPermissionEnum_admin;

  static Serializer<CreatePersonRequestPermissionEnum> get serializer => _$createPersonRequestPermissionEnumSerializer;

  const CreatePersonRequestPermissionEnum._(String name): super(name);

  static BuiltSet<CreatePersonRequestPermissionEnum> get values => _$createPersonRequestPermissionEnumValues;
  static CreatePersonRequestPermissionEnum valueOf(String name) => _$createPersonRequestPermissionEnumValueOf(name);
}

