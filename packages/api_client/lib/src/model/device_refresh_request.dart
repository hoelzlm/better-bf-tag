//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'device_refresh_request.g.dart';

/// DeviceRefreshRequest
///
/// Properties:
/// * [refreshToken] 
@BuiltValue()
abstract class DeviceRefreshRequest implements Built<DeviceRefreshRequest, DeviceRefreshRequestBuilder> {
  @BuiltValueField(wireName: r'refresh_token')
  String get refreshToken;

  DeviceRefreshRequest._();

  factory DeviceRefreshRequest([void updates(DeviceRefreshRequestBuilder b)]) = _$DeviceRefreshRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeviceRefreshRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeviceRefreshRequest> get serializer => _$DeviceRefreshRequestSerializer();
}

class _$DeviceRefreshRequestSerializer implements PrimitiveSerializer<DeviceRefreshRequest> {
  @override
  final Iterable<Type> types = const [DeviceRefreshRequest, _$DeviceRefreshRequest];

  @override
  final String wireName = r'DeviceRefreshRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeviceRefreshRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'refresh_token';
    yield serializers.serialize(
      object.refreshToken,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DeviceRefreshRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DeviceRefreshRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'refresh_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.refreshToken = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DeviceRefreshRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeviceRefreshRequestBuilder();
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

