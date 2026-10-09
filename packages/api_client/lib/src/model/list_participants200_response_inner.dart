//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'list_participants200_response_inner.g.dart';

/// ListParticipants200ResponseInner
///
/// Properties:
/// * [personId] 
/// * [displayName] 
/// * [personType] 
/// * [permission] 
/// * [fireDepartmentId] 
@BuiltValue()
abstract class ListParticipants200ResponseInner implements Built<ListParticipants200ResponseInner, ListParticipants200ResponseInnerBuilder> {
  @BuiltValueField(wireName: r'person_id')
  String get personId;

  @BuiltValueField(wireName: r'display_name')
  String get displayName;

  @BuiltValueField(wireName: r'person_type')
  ListParticipants200ResponseInnerPersonTypeEnum get personType;
  // enum personTypeEnum {  youth,  supervisor,  };

  @BuiltValueField(wireName: r'permission')
  ListParticipants200ResponseInnerPermissionEnum get permission;
  // enum permissionEnum {  crew,  preparation,  dispatch,  admin,  };

  @BuiltValueField(wireName: r'fire_department_id')
  String get fireDepartmentId;

  ListParticipants200ResponseInner._();

  factory ListParticipants200ResponseInner([void updates(ListParticipants200ResponseInnerBuilder b)]) = _$ListParticipants200ResponseInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ListParticipants200ResponseInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ListParticipants200ResponseInner> get serializer => _$ListParticipants200ResponseInnerSerializer();
}

class _$ListParticipants200ResponseInnerSerializer implements PrimitiveSerializer<ListParticipants200ResponseInner> {
  @override
  final Iterable<Type> types = const [ListParticipants200ResponseInner, _$ListParticipants200ResponseInner];

  @override
  final String wireName = r'ListParticipants200ResponseInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ListParticipants200ResponseInner object, {
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
    yield r'person_type';
    yield serializers.serialize(
      object.personType,
      specifiedType: const FullType(ListParticipants200ResponseInnerPersonTypeEnum),
    );
    yield r'permission';
    yield serializers.serialize(
      object.permission,
      specifiedType: const FullType(ListParticipants200ResponseInnerPermissionEnum),
    );
    yield r'fire_department_id';
    yield serializers.serialize(
      object.fireDepartmentId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ListParticipants200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ListParticipants200ResponseInnerBuilder result,
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
        case r'person_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ListParticipants200ResponseInnerPersonTypeEnum),
          ) as ListParticipants200ResponseInnerPersonTypeEnum;
          result.personType = valueDes;
          break;
        case r'permission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ListParticipants200ResponseInnerPermissionEnum),
          ) as ListParticipants200ResponseInnerPermissionEnum;
          result.permission = valueDes;
          break;
        case r'fire_department_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.fireDepartmentId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ListParticipants200ResponseInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ListParticipants200ResponseInnerBuilder();
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

class ListParticipants200ResponseInnerPersonTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'youth')
  static const ListParticipants200ResponseInnerPersonTypeEnum youth = _$listParticipants200ResponseInnerPersonTypeEnum_youth;
  @BuiltValueEnumConst(wireName: r'supervisor')
  static const ListParticipants200ResponseInnerPersonTypeEnum supervisor = _$listParticipants200ResponseInnerPersonTypeEnum_supervisor;

  static Serializer<ListParticipants200ResponseInnerPersonTypeEnum> get serializer => _$listParticipants200ResponseInnerPersonTypeEnumSerializer;

  const ListParticipants200ResponseInnerPersonTypeEnum._(String name): super(name);

  static BuiltSet<ListParticipants200ResponseInnerPersonTypeEnum> get values => _$listParticipants200ResponseInnerPersonTypeEnumValues;
  static ListParticipants200ResponseInnerPersonTypeEnum valueOf(String name) => _$listParticipants200ResponseInnerPersonTypeEnumValueOf(name);
}

class ListParticipants200ResponseInnerPermissionEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'crew')
  static const ListParticipants200ResponseInnerPermissionEnum crew = _$listParticipants200ResponseInnerPermissionEnum_crew;
  @BuiltValueEnumConst(wireName: r'preparation')
  static const ListParticipants200ResponseInnerPermissionEnum preparation = _$listParticipants200ResponseInnerPermissionEnum_preparation;
  @BuiltValueEnumConst(wireName: r'dispatch')
  static const ListParticipants200ResponseInnerPermissionEnum dispatch = _$listParticipants200ResponseInnerPermissionEnum_dispatch;
  @BuiltValueEnumConst(wireName: r'admin')
  static const ListParticipants200ResponseInnerPermissionEnum admin = _$listParticipants200ResponseInnerPermissionEnum_admin;

  static Serializer<ListParticipants200ResponseInnerPermissionEnum> get serializer => _$listParticipants200ResponseInnerPermissionEnumSerializer;

  const ListParticipants200ResponseInnerPermissionEnum._(String name): super(name);

  static BuiltSet<ListParticipants200ResponseInnerPermissionEnum> get values => _$listParticipants200ResponseInnerPermissionEnumValues;
  static ListParticipants200ResponseInnerPermissionEnum valueOf(String name) => _$listParticipants200ResponseInnerPermissionEnumValueOf(name);
}

