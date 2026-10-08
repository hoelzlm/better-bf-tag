//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'login200_response_person.g.dart';

/// Login200ResponsePerson
///
/// Properties:
/// * [id] 
/// * [displayName] 
/// * [personType] 
/// * [permission] 
@BuiltValue()
abstract class Login200ResponsePerson implements Built<Login200ResponsePerson, Login200ResponsePersonBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'display_name')
  String get displayName;

  @BuiltValueField(wireName: r'person_type')
  Login200ResponsePersonPersonTypeEnum get personType;
  // enum personTypeEnum {  youth,  supervisor,  };

  @BuiltValueField(wireName: r'permission')
  Login200ResponsePersonPermissionEnum get permission;
  // enum permissionEnum {  crew,  preparation,  dispatch,  admin,  };

  Login200ResponsePerson._();

  factory Login200ResponsePerson([void updates(Login200ResponsePersonBuilder b)]) = _$Login200ResponsePerson;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(Login200ResponsePersonBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Login200ResponsePerson> get serializer => _$Login200ResponsePersonSerializer();
}

class _$Login200ResponsePersonSerializer implements PrimitiveSerializer<Login200ResponsePerson> {
  @override
  final Iterable<Type> types = const [Login200ResponsePerson, _$Login200ResponsePerson];

  @override
  final String wireName = r'Login200ResponsePerson';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Login200ResponsePerson object, {
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
      specifiedType: const FullType(Login200ResponsePersonPersonTypeEnum),
    );
    yield r'permission';
    yield serializers.serialize(
      object.permission,
      specifiedType: const FullType(Login200ResponsePersonPermissionEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Login200ResponsePerson object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required Login200ResponsePersonBuilder result,
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
            specifiedType: const FullType(Login200ResponsePersonPersonTypeEnum),
          ) as Login200ResponsePersonPersonTypeEnum;
          result.personType = valueDes;
          break;
        case r'permission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Login200ResponsePersonPermissionEnum),
          ) as Login200ResponsePersonPermissionEnum;
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
  Login200ResponsePerson deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = Login200ResponsePersonBuilder();
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

class Login200ResponsePersonPersonTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'youth')
  static const Login200ResponsePersonPersonTypeEnum youth = _$login200ResponsePersonPersonTypeEnum_youth;
  @BuiltValueEnumConst(wireName: r'supervisor')
  static const Login200ResponsePersonPersonTypeEnum supervisor = _$login200ResponsePersonPersonTypeEnum_supervisor;

  static Serializer<Login200ResponsePersonPersonTypeEnum> get serializer => _$login200ResponsePersonPersonTypeEnumSerializer;

  const Login200ResponsePersonPersonTypeEnum._(String name): super(name);

  static BuiltSet<Login200ResponsePersonPersonTypeEnum> get values => _$login200ResponsePersonPersonTypeEnumValues;
  static Login200ResponsePersonPersonTypeEnum valueOf(String name) => _$login200ResponsePersonPersonTypeEnumValueOf(name);
}

class Login200ResponsePersonPermissionEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'crew')
  static const Login200ResponsePersonPermissionEnum crew = _$login200ResponsePersonPermissionEnum_crew;
  @BuiltValueEnumConst(wireName: r'preparation')
  static const Login200ResponsePersonPermissionEnum preparation = _$login200ResponsePersonPermissionEnum_preparation;
  @BuiltValueEnumConst(wireName: r'dispatch')
  static const Login200ResponsePersonPermissionEnum dispatch = _$login200ResponsePersonPermissionEnum_dispatch;
  @BuiltValueEnumConst(wireName: r'admin')
  static const Login200ResponsePersonPermissionEnum admin = _$login200ResponsePersonPermissionEnum_admin;

  static Serializer<Login200ResponsePersonPermissionEnum> get serializer => _$login200ResponsePersonPermissionEnumSerializer;

  const Login200ResponsePersonPermissionEnum._(String name): super(name);

  static BuiltSet<Login200ResponsePersonPermissionEnum> get values => _$login200ResponsePersonPermissionEnumValues;
  static Login200ResponsePersonPermissionEnum valueOf(String name) => _$login200ResponsePersonPermissionEnumValueOf(name);
}

