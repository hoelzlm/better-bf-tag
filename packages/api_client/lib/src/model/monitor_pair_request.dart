//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'monitor_pair_request.g.dart';

/// MonitorPairRequest
///
/// Properties:
/// * [code] 
@BuiltValue()
abstract class MonitorPairRequest implements Built<MonitorPairRequest, MonitorPairRequestBuilder> {
  @BuiltValueField(wireName: r'code')
  String get code;

  MonitorPairRequest._();

  factory MonitorPairRequest([void updates(MonitorPairRequestBuilder b)]) = _$MonitorPairRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MonitorPairRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MonitorPairRequest> get serializer => _$MonitorPairRequestSerializer();
}

class _$MonitorPairRequestSerializer implements PrimitiveSerializer<MonitorPairRequest> {
  @override
  final Iterable<Type> types = const [MonitorPairRequest, _$MonitorPairRequest];

  @override
  final String wireName = r'MonitorPairRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MonitorPairRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MonitorPairRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MonitorPairRequestBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MonitorPairRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MonitorPairRequestBuilder();
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

