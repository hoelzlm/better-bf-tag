//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bftag_api_client/src/model/get_snapshot200_response_incidents_inner.dart';
import 'package:bftag_api_client/src/model/get_snapshot200_response_alarms_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_snapshot200_response_scheduled_alarms_inner.g.dart';

/// GetSnapshot200ResponseScheduledAlarmsInner
///
/// Properties:
/// * [incident] 
/// * [alarm] 
@BuiltValue()
abstract class GetSnapshot200ResponseScheduledAlarmsInner implements Built<GetSnapshot200ResponseScheduledAlarmsInner, GetSnapshot200ResponseScheduledAlarmsInnerBuilder> {
  @BuiltValueField(wireName: r'incident')
  GetSnapshot200ResponseIncidentsInner get incident;

  @BuiltValueField(wireName: r'alarm')
  GetSnapshot200ResponseAlarmsInner get alarm;

  GetSnapshot200ResponseScheduledAlarmsInner._();

  factory GetSnapshot200ResponseScheduledAlarmsInner([void updates(GetSnapshot200ResponseScheduledAlarmsInnerBuilder b)]) = _$GetSnapshot200ResponseScheduledAlarmsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetSnapshot200ResponseScheduledAlarmsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetSnapshot200ResponseScheduledAlarmsInner> get serializer => _$GetSnapshot200ResponseScheduledAlarmsInnerSerializer();
}

class _$GetSnapshot200ResponseScheduledAlarmsInnerSerializer implements PrimitiveSerializer<GetSnapshot200ResponseScheduledAlarmsInner> {
  @override
  final Iterable<Type> types = const [GetSnapshot200ResponseScheduledAlarmsInner, _$GetSnapshot200ResponseScheduledAlarmsInner];

  @override
  final String wireName = r'GetSnapshot200ResponseScheduledAlarmsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetSnapshot200ResponseScheduledAlarmsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'incident';
    yield serializers.serialize(
      object.incident,
      specifiedType: const FullType(GetSnapshot200ResponseIncidentsInner),
    );
    yield r'alarm';
    yield serializers.serialize(
      object.alarm,
      specifiedType: const FullType(GetSnapshot200ResponseAlarmsInner),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetSnapshot200ResponseScheduledAlarmsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetSnapshot200ResponseScheduledAlarmsInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'incident':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GetSnapshot200ResponseIncidentsInner),
          ) as GetSnapshot200ResponseIncidentsInner;
          result.incident.replace(valueDes);
          break;
        case r'alarm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GetSnapshot200ResponseAlarmsInner),
          ) as GetSnapshot200ResponseAlarmsInner;
          result.alarm.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetSnapshot200ResponseScheduledAlarmsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetSnapshot200ResponseScheduledAlarmsInnerBuilder();
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

