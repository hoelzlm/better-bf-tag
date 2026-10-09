//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'trigger_test_alarm202_response.g.dart';

/// TriggerTestAlarm202Response
///
/// Properties:
/// * [scheduled] 
@BuiltValue()
abstract class TriggerTestAlarm202Response implements Built<TriggerTestAlarm202Response, TriggerTestAlarm202ResponseBuilder> {
  @BuiltValueField(wireName: r'scheduled')
  bool get scheduled;

  TriggerTestAlarm202Response._();

  factory TriggerTestAlarm202Response([void updates(TriggerTestAlarm202ResponseBuilder b)]) = _$TriggerTestAlarm202Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TriggerTestAlarm202ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TriggerTestAlarm202Response> get serializer => _$TriggerTestAlarm202ResponseSerializer();
}

class _$TriggerTestAlarm202ResponseSerializer implements PrimitiveSerializer<TriggerTestAlarm202Response> {
  @override
  final Iterable<Type> types = const [TriggerTestAlarm202Response, _$TriggerTestAlarm202Response];

  @override
  final String wireName = r'TriggerTestAlarm202Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TriggerTestAlarm202Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'scheduled';
    yield serializers.serialize(
      object.scheduled,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TriggerTestAlarm202Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TriggerTestAlarm202ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'scheduled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.scheduled = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TriggerTestAlarm202Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TriggerTestAlarm202ResponseBuilder();
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

