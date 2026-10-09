//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'trigger_test_alarm_request.g.dart';

/// TriggerTestAlarmRequest
///
/// Properties:
/// * [delaySeconds] 
@BuiltValue()
abstract class TriggerTestAlarmRequest implements Built<TriggerTestAlarmRequest, TriggerTestAlarmRequestBuilder> {
  @BuiltValueField(wireName: r'delay_seconds')
  int? get delaySeconds;

  TriggerTestAlarmRequest._();

  factory TriggerTestAlarmRequest([void updates(TriggerTestAlarmRequestBuilder b)]) = _$TriggerTestAlarmRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TriggerTestAlarmRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TriggerTestAlarmRequest> get serializer => _$TriggerTestAlarmRequestSerializer();
}

class _$TriggerTestAlarmRequestSerializer implements PrimitiveSerializer<TriggerTestAlarmRequest> {
  @override
  final Iterable<Type> types = const [TriggerTestAlarmRequest, _$TriggerTestAlarmRequest];

  @override
  final String wireName = r'TriggerTestAlarmRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TriggerTestAlarmRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.delaySeconds != null) {
      yield r'delay_seconds';
      yield serializers.serialize(
        object.delaySeconds,
        specifiedType: const FullType(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    TriggerTestAlarmRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TriggerTestAlarmRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'delay_seconds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.delaySeconds = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TriggerTestAlarmRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TriggerTestAlarmRequestBuilder();
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

