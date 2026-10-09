//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:bftag_api_client/src/model/get_snapshot200_response_alarms_inner.dart';
import 'package:bftag_api_client/src/model/trigger_alarm200_response_double_crewed_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'trigger_alarm200_response.g.dart';

/// TriggerAlarm200Response
///
/// Properties:
/// * [alarm] 
/// * [doubleCrewed] 
@BuiltValue()
abstract class TriggerAlarm200Response implements Built<TriggerAlarm200Response, TriggerAlarm200ResponseBuilder> {
  @BuiltValueField(wireName: r'alarm')
  GetSnapshot200ResponseAlarmsInner get alarm;

  @BuiltValueField(wireName: r'double_crewed')
  BuiltList<TriggerAlarm200ResponseDoubleCrewedInner> get doubleCrewed;

  TriggerAlarm200Response._();

  factory TriggerAlarm200Response([void updates(TriggerAlarm200ResponseBuilder b)]) = _$TriggerAlarm200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TriggerAlarm200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TriggerAlarm200Response> get serializer => _$TriggerAlarm200ResponseSerializer();
}

class _$TriggerAlarm200ResponseSerializer implements PrimitiveSerializer<TriggerAlarm200Response> {
  @override
  final Iterable<Type> types = const [TriggerAlarm200Response, _$TriggerAlarm200Response];

  @override
  final String wireName = r'TriggerAlarm200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TriggerAlarm200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'alarm';
    yield serializers.serialize(
      object.alarm,
      specifiedType: const FullType(GetSnapshot200ResponseAlarmsInner),
    );
    yield r'double_crewed';
    yield serializers.serialize(
      object.doubleCrewed,
      specifiedType: const FullType(BuiltList, [FullType(TriggerAlarm200ResponseDoubleCrewedInner)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TriggerAlarm200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TriggerAlarm200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'alarm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GetSnapshot200ResponseAlarmsInner),
          ) as GetSnapshot200ResponseAlarmsInner;
          result.alarm.replace(valueDes);
          break;
        case r'double_crewed':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(TriggerAlarm200ResponseDoubleCrewedInner)]),
          ) as BuiltList<TriggerAlarm200ResponseDoubleCrewedInner>;
          result.doubleCrewed.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TriggerAlarm200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TriggerAlarm200ResponseBuilder();
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

