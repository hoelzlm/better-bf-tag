//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'list_person_devices200_response_inner.g.dart';

/// ListPersonDevices200ResponseInner
///
/// Properties:
/// * [id] 
/// * [platform] 
/// * [deviceName] 
/// * [appVersion] 
/// * [createdAt] 
/// * [lastSeenAt] 
/// * [revokedAt] 
@BuiltValue()
abstract class ListPersonDevices200ResponseInner implements Built<ListPersonDevices200ResponseInner, ListPersonDevices200ResponseInnerBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'platform')
  ListPersonDevices200ResponseInnerPlatformEnum get platform;
  // enum platformEnum {  android,  ios,  };

  @BuiltValueField(wireName: r'device_name')
  String? get deviceName;

  @BuiltValueField(wireName: r'app_version')
  String get appVersion;

  @BuiltValueField(wireName: r'created_at')
  String get createdAt;

  @BuiltValueField(wireName: r'last_seen_at')
  String get lastSeenAt;

  @BuiltValueField(wireName: r'revoked_at')
  String? get revokedAt;

  ListPersonDevices200ResponseInner._();

  factory ListPersonDevices200ResponseInner([void updates(ListPersonDevices200ResponseInnerBuilder b)]) = _$ListPersonDevices200ResponseInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ListPersonDevices200ResponseInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ListPersonDevices200ResponseInner> get serializer => _$ListPersonDevices200ResponseInnerSerializer();
}

class _$ListPersonDevices200ResponseInnerSerializer implements PrimitiveSerializer<ListPersonDevices200ResponseInner> {
  @override
  final Iterable<Type> types = const [ListPersonDevices200ResponseInner, _$ListPersonDevices200ResponseInner];

  @override
  final String wireName = r'ListPersonDevices200ResponseInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ListPersonDevices200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'platform';
    yield serializers.serialize(
      object.platform,
      specifiedType: const FullType(ListPersonDevices200ResponseInnerPlatformEnum),
    );
    yield r'device_name';
    yield object.deviceName == null ? null : serializers.serialize(
      object.deviceName,
      specifiedType: const FullType.nullable(String),
    );
    yield r'app_version';
    yield serializers.serialize(
      object.appVersion,
      specifiedType: const FullType(String),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(String),
    );
    yield r'last_seen_at';
    yield serializers.serialize(
      object.lastSeenAt,
      specifiedType: const FullType(String),
    );
    yield r'revoked_at';
    yield object.revokedAt == null ? null : serializers.serialize(
      object.revokedAt,
      specifiedType: const FullType.nullable(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ListPersonDevices200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ListPersonDevices200ResponseInnerBuilder result,
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
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ListPersonDevices200ResponseInnerPlatformEnum),
          ) as ListPersonDevices200ResponseInnerPlatformEnum;
          result.platform = valueDes;
          break;
        case r'device_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.deviceName = valueDes;
          break;
        case r'app_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.appVersion = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.createdAt = valueDes;
          break;
        case r'last_seen_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.lastSeenAt = valueDes;
          break;
        case r'revoked_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.revokedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ListPersonDevices200ResponseInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ListPersonDevices200ResponseInnerBuilder();
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

class ListPersonDevices200ResponseInnerPlatformEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'android')
  static const ListPersonDevices200ResponseInnerPlatformEnum android = _$listPersonDevices200ResponseInnerPlatformEnum_android;
  @BuiltValueEnumConst(wireName: r'ios')
  static const ListPersonDevices200ResponseInnerPlatformEnum ios = _$listPersonDevices200ResponseInnerPlatformEnum_ios;

  static Serializer<ListPersonDevices200ResponseInnerPlatformEnum> get serializer => _$listPersonDevices200ResponseInnerPlatformEnumSerializer;

  const ListPersonDevices200ResponseInnerPlatformEnum._(String name): super(name);

  static BuiltSet<ListPersonDevices200ResponseInnerPlatformEnum> get values => _$listPersonDevices200ResponseInnerPlatformEnumValues;
  static ListPersonDevices200ResponseInnerPlatformEnum valueOf(String name) => _$listPersonDevices200ResponseInnerPlatformEnumValueOf(name);
}

