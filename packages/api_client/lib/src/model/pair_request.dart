//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'pair_request.g.dart';

/// PairRequest
///
/// Properties:
/// * [code] 
/// * [platform] 
/// * [appVersion] 
/// * [deviceName] 
@BuiltValue()
abstract class PairRequest implements Built<PairRequest, PairRequestBuilder> {
  @BuiltValueField(wireName: r'code')
  String get code;

  @BuiltValueField(wireName: r'platform')
  PairRequestPlatformEnum get platform;
  // enum platformEnum {  android,  ios,  };

  @BuiltValueField(wireName: r'app_version')
  String get appVersion;

  @BuiltValueField(wireName: r'device_name')
  String? get deviceName;

  PairRequest._();

  factory PairRequest([void updates(PairRequestBuilder b)]) = _$PairRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PairRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PairRequest> get serializer => _$PairRequestSerializer();
}

class _$PairRequestSerializer implements PrimitiveSerializer<PairRequest> {
  @override
  final Iterable<Type> types = const [PairRequest, _$PairRequest];

  @override
  final String wireName = r'PairRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PairRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
    yield r'platform';
    yield serializers.serialize(
      object.platform,
      specifiedType: const FullType(PairRequestPlatformEnum),
    );
    yield r'app_version';
    yield serializers.serialize(
      object.appVersion,
      specifiedType: const FullType(String),
    );
    if (object.deviceName != null) {
      yield r'device_name';
      yield serializers.serialize(
        object.deviceName,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PairRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PairRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PairRequestPlatformEnum),
          ) as PairRequestPlatformEnum;
          result.platform = valueDes;
          break;
        case r'app_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.appVersion = valueDes;
          break;
        case r'device_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deviceName = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PairRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PairRequestBuilder();
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

class PairRequestPlatformEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'android')
  static const PairRequestPlatformEnum android = _$pairRequestPlatformEnum_android;
  @BuiltValueEnumConst(wireName: r'ios')
  static const PairRequestPlatformEnum ios = _$pairRequestPlatformEnum_ios;

  static Serializer<PairRequestPlatformEnum> get serializer => _$pairRequestPlatformEnumSerializer;

  const PairRequestPlatformEnum._(String name): super(name);

  static BuiltSet<PairRequestPlatformEnum> get values => _$pairRequestPlatformEnumValues;
  static PairRequestPlatformEnum valueOf(String name) => _$pairRequestPlatformEnumValueOf(name);
}

