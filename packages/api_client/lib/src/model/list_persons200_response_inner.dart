//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'list_persons200_response_inner.g.dart';

/// ListPersons200ResponseInner
///
/// Properties:
/// * [id] 
/// * [displayName] 
/// * [personType] 
/// * [permission] 
/// * [active] 
/// * [hasWebAccess] 
/// * [username] 
@BuiltValue()
abstract class ListPersons200ResponseInner implements Built<ListPersons200ResponseInner, ListPersons200ResponseInnerBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'display_name')
  String get displayName;

  @BuiltValueField(wireName: r'person_type')
  ListPersons200ResponseInnerPersonTypeEnum get personType;
  // enum personTypeEnum {  youth,  supervisor,  };

  @BuiltValueField(wireName: r'permission')
  ListPersons200ResponseInnerPermissionEnum get permission;
  // enum permissionEnum {  crew,  preparation,  dispatch,  admin,  };

  @BuiltValueField(wireName: r'active')
  bool get active;

  @BuiltValueField(wireName: r'has_web_access')
  bool get hasWebAccess;

  @BuiltValueField(wireName: r'username')
  String? get username;

  ListPersons200ResponseInner._();

  factory ListPersons200ResponseInner([void updates(ListPersons200ResponseInnerBuilder b)]) = _$ListPersons200ResponseInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ListPersons200ResponseInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ListPersons200ResponseInner> get serializer => _$ListPersons200ResponseInnerSerializer();
}

class _$ListPersons200ResponseInnerSerializer implements PrimitiveSerializer<ListPersons200ResponseInner> {
  @override
  final Iterable<Type> types = const [ListPersons200ResponseInner, _$ListPersons200ResponseInner];

  @override
  final String wireName = r'ListPersons200ResponseInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ListPersons200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
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
      specifiedType: const FullType(ListPersons200ResponseInnerPersonTypeEnum),
    );
    yield r'permission';
    yield serializers.serialize(
      object.permission,
      specifiedType: const FullType(ListPersons200ResponseInnerPermissionEnum),
    );
    yield r'active';
    yield serializers.serialize(
      object.active,
      specifiedType: const FullType(bool),
    );
    yield r'has_web_access';
    yield serializers.serialize(
      object.hasWebAccess,
      specifiedType: const FullType(bool),
    );
    yield r'username';
    yield object.username == null ? null : serializers.serialize(
      object.username,
      specifiedType: const FullType.nullable(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ListPersons200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ListPersons200ResponseInnerBuilder result,
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
            specifiedType: const FullType(ListPersons200ResponseInnerPersonTypeEnum),
          ) as ListPersons200ResponseInnerPersonTypeEnum;
          result.personType = valueDes;
          break;
        case r'permission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ListPersons200ResponseInnerPermissionEnum),
          ) as ListPersons200ResponseInnerPermissionEnum;
          result.permission = valueDes;
          break;
        case r'active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.active = valueDes;
          break;
        case r'has_web_access':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.hasWebAccess = valueDes;
          break;
        case r'username':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.username = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ListPersons200ResponseInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ListPersons200ResponseInnerBuilder();
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

class ListPersons200ResponseInnerPersonTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'youth')
  static const ListPersons200ResponseInnerPersonTypeEnum youth = _$listPersons200ResponseInnerPersonTypeEnum_youth;
  @BuiltValueEnumConst(wireName: r'supervisor')
  static const ListPersons200ResponseInnerPersonTypeEnum supervisor = _$listPersons200ResponseInnerPersonTypeEnum_supervisor;

  static Serializer<ListPersons200ResponseInnerPersonTypeEnum> get serializer => _$listPersons200ResponseInnerPersonTypeEnumSerializer;

  const ListPersons200ResponseInnerPersonTypeEnum._(String name): super(name);

  static BuiltSet<ListPersons200ResponseInnerPersonTypeEnum> get values => _$listPersons200ResponseInnerPersonTypeEnumValues;
  static ListPersons200ResponseInnerPersonTypeEnum valueOf(String name) => _$listPersons200ResponseInnerPersonTypeEnumValueOf(name);
}

class ListPersons200ResponseInnerPermissionEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'crew')
  static const ListPersons200ResponseInnerPermissionEnum crew = _$listPersons200ResponseInnerPermissionEnum_crew;
  @BuiltValueEnumConst(wireName: r'preparation')
  static const ListPersons200ResponseInnerPermissionEnum preparation = _$listPersons200ResponseInnerPermissionEnum_preparation;
  @BuiltValueEnumConst(wireName: r'dispatch')
  static const ListPersons200ResponseInnerPermissionEnum dispatch = _$listPersons200ResponseInnerPermissionEnum_dispatch;
  @BuiltValueEnumConst(wireName: r'admin')
  static const ListPersons200ResponseInnerPermissionEnum admin = _$listPersons200ResponseInnerPermissionEnum_admin;

  static Serializer<ListPersons200ResponseInnerPermissionEnum> get serializer => _$listPersons200ResponseInnerPermissionEnumSerializer;

  const ListPersons200ResponseInnerPermissionEnum._(String name): super(name);

  static BuiltSet<ListPersons200ResponseInnerPermissionEnum> get values => _$listPersons200ResponseInnerPermissionEnumValues;
  static ListPersons200ResponseInnerPermissionEnum valueOf(String name) => _$listPersons200ResponseInnerPermissionEnumValueOf(name);
}

