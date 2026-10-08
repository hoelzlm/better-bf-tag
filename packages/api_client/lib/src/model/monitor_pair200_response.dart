//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bftag_api_client/src/model/monitor_pair200_response_monitor.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'monitor_pair200_response.g.dart';

/// MonitorPair200Response
///
/// Properties:
/// * [accessToken] 
/// * [refreshToken] 
/// * [expiresIn] 
/// * [monitor] 
@BuiltValue()
abstract class MonitorPair200Response implements Built<MonitorPair200Response, MonitorPair200ResponseBuilder> {
  @BuiltValueField(wireName: r'access_token')
  String get accessToken;

  @BuiltValueField(wireName: r'refresh_token')
  String get refreshToken;

  @BuiltValueField(wireName: r'expires_in')
  num get expiresIn;

  @BuiltValueField(wireName: r'monitor')
  MonitorPair200ResponseMonitor get monitor;

  MonitorPair200Response._();

  factory MonitorPair200Response([void updates(MonitorPair200ResponseBuilder b)]) = _$MonitorPair200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MonitorPair200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MonitorPair200Response> get serializer => _$MonitorPair200ResponseSerializer();
}

class _$MonitorPair200ResponseSerializer implements PrimitiveSerializer<MonitorPair200Response> {
  @override
  final Iterable<Type> types = const [MonitorPair200Response, _$MonitorPair200Response];

  @override
  final String wireName = r'MonitorPair200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MonitorPair200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'access_token';
    yield serializers.serialize(
      object.accessToken,
      specifiedType: const FullType(String),
    );
    yield r'refresh_token';
    yield serializers.serialize(
      object.refreshToken,
      specifiedType: const FullType(String),
    );
    yield r'expires_in';
    yield serializers.serialize(
      object.expiresIn,
      specifiedType: const FullType(num),
    );
    yield r'monitor';
    yield serializers.serialize(
      object.monitor,
      specifiedType: const FullType(MonitorPair200ResponseMonitor),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MonitorPair200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MonitorPair200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'access_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.accessToken = valueDes;
          break;
        case r'refresh_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.refreshToken = valueDes;
          break;
        case r'expires_in':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.expiresIn = valueDes;
          break;
        case r'monitor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MonitorPair200ResponseMonitor),
          ) as MonitorPair200ResponseMonitor;
          result.monitor.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MonitorPair200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MonitorPair200ResponseBuilder();
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

