//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bftag_api_client/src/model/get_snapshot200_response_alarms_inner_recipients_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'acknowledge_alarm200_response.g.dart';

/// AcknowledgeAlarm200Response
///
/// Properties:
/// * [recipient] 
@BuiltValue()
abstract class AcknowledgeAlarm200Response implements Built<AcknowledgeAlarm200Response, AcknowledgeAlarm200ResponseBuilder> {
  @BuiltValueField(wireName: r'recipient')
  GetSnapshot200ResponseAlarmsInnerRecipientsInner get recipient;

  AcknowledgeAlarm200Response._();

  factory AcknowledgeAlarm200Response([void updates(AcknowledgeAlarm200ResponseBuilder b)]) = _$AcknowledgeAlarm200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AcknowledgeAlarm200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AcknowledgeAlarm200Response> get serializer => _$AcknowledgeAlarm200ResponseSerializer();
}

class _$AcknowledgeAlarm200ResponseSerializer implements PrimitiveSerializer<AcknowledgeAlarm200Response> {
  @override
  final Iterable<Type> types = const [AcknowledgeAlarm200Response, _$AcknowledgeAlarm200Response];

  @override
  final String wireName = r'AcknowledgeAlarm200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AcknowledgeAlarm200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'recipient';
    yield serializers.serialize(
      object.recipient,
      specifiedType: const FullType(GetSnapshot200ResponseAlarmsInnerRecipientsInner),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AcknowledgeAlarm200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AcknowledgeAlarm200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'recipient':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GetSnapshot200ResponseAlarmsInnerRecipientsInner),
          ) as GetSnapshot200ResponseAlarmsInnerRecipientsInner;
          result.recipient.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AcknowledgeAlarm200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AcknowledgeAlarm200ResponseBuilder();
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

