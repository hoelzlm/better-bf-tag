//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:bftag_api_client/src/model/get_snapshot200_response_alarms_inner_recipients_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_snapshot200_response_alarms_inner.g.dart';

/// GetSnapshot200ResponseAlarmsInner
///
/// Properties:
/// * [id] 
/// * [incidentId] 
/// * [state] 
/// * [scheduledAt] 
/// * [triggeredAt] 
/// * [vehicleIds] 
/// * [recipients] 
/// * [pushDelivered] 
/// * [pushRejected] 
/// * [relativeToAlarmId] 
/// * [offsetMinutes] 
@BuiltValue()
abstract class GetSnapshot200ResponseAlarmsInner implements Built<GetSnapshot200ResponseAlarmsInner, GetSnapshot200ResponseAlarmsInnerBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'incident_id')
  String get incidentId;

  @BuiltValueField(wireName: r'state')
  GetSnapshot200ResponseAlarmsInnerStateEnum get state;
  // enum stateEnum {  planned,  triggered,  missed,  discarded,  };

  @BuiltValueField(wireName: r'scheduled_at')
  String? get scheduledAt;

  @BuiltValueField(wireName: r'triggered_at')
  String? get triggeredAt;

  @BuiltValueField(wireName: r'vehicle_ids')
  BuiltList<String> get vehicleIds;

  @BuiltValueField(wireName: r'recipients')
  BuiltList<GetSnapshot200ResponseAlarmsInnerRecipientsInner> get recipients;

  @BuiltValueField(wireName: r'push_delivered')
  int get pushDelivered;

  @BuiltValueField(wireName: r'push_rejected')
  int get pushRejected;

  @BuiltValueField(wireName: r'relative_to_alarm_id')
  String? get relativeToAlarmId;

  @BuiltValueField(wireName: r'offset_minutes')
  int? get offsetMinutes;

  GetSnapshot200ResponseAlarmsInner._();

  factory GetSnapshot200ResponseAlarmsInner([void updates(GetSnapshot200ResponseAlarmsInnerBuilder b)]) = _$GetSnapshot200ResponseAlarmsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetSnapshot200ResponseAlarmsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetSnapshot200ResponseAlarmsInner> get serializer => _$GetSnapshot200ResponseAlarmsInnerSerializer();
}

class _$GetSnapshot200ResponseAlarmsInnerSerializer implements PrimitiveSerializer<GetSnapshot200ResponseAlarmsInner> {
  @override
  final Iterable<Type> types = const [GetSnapshot200ResponseAlarmsInner, _$GetSnapshot200ResponseAlarmsInner];

  @override
  final String wireName = r'GetSnapshot200ResponseAlarmsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetSnapshot200ResponseAlarmsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'incident_id';
    yield serializers.serialize(
      object.incidentId,
      specifiedType: const FullType(String),
    );
    yield r'state';
    yield serializers.serialize(
      object.state,
      specifiedType: const FullType(GetSnapshot200ResponseAlarmsInnerStateEnum),
    );
    yield r'scheduled_at';
    yield object.scheduledAt == null ? null : serializers.serialize(
      object.scheduledAt,
      specifiedType: const FullType.nullable(String),
    );
    yield r'triggered_at';
    yield object.triggeredAt == null ? null : serializers.serialize(
      object.triggeredAt,
      specifiedType: const FullType.nullable(String),
    );
    yield r'vehicle_ids';
    yield serializers.serialize(
      object.vehicleIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'recipients';
    yield serializers.serialize(
      object.recipients,
      specifiedType: const FullType(BuiltList, [FullType(GetSnapshot200ResponseAlarmsInnerRecipientsInner)]),
    );
    yield r'push_delivered';
    yield serializers.serialize(
      object.pushDelivered,
      specifiedType: const FullType(int),
    );
    yield r'push_rejected';
    yield serializers.serialize(
      object.pushRejected,
      specifiedType: const FullType(int),
    );
    yield r'relative_to_alarm_id';
    yield object.relativeToAlarmId == null ? null : serializers.serialize(
      object.relativeToAlarmId,
      specifiedType: const FullType.nullable(String),
    );
    yield r'offset_minutes';
    yield object.offsetMinutes == null ? null : serializers.serialize(
      object.offsetMinutes,
      specifiedType: const FullType.nullable(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetSnapshot200ResponseAlarmsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetSnapshot200ResponseAlarmsInnerBuilder result,
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
        case r'incident_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.incidentId = valueDes;
          break;
        case r'state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GetSnapshot200ResponseAlarmsInnerStateEnum),
          ) as GetSnapshot200ResponseAlarmsInnerStateEnum;
          result.state = valueDes;
          break;
        case r'scheduled_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.scheduledAt = valueDes;
          break;
        case r'triggered_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.triggeredAt = valueDes;
          break;
        case r'vehicle_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.vehicleIds.replace(valueDes);
          break;
        case r'recipients':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(GetSnapshot200ResponseAlarmsInnerRecipientsInner)]),
          ) as BuiltList<GetSnapshot200ResponseAlarmsInnerRecipientsInner>;
          result.recipients.replace(valueDes);
          break;
        case r'push_delivered':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.pushDelivered = valueDes;
          break;
        case r'push_rejected':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.pushRejected = valueDes;
          break;
        case r'relative_to_alarm_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.relativeToAlarmId = valueDes;
          break;
        case r'offset_minutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.offsetMinutes = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetSnapshot200ResponseAlarmsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetSnapshot200ResponseAlarmsInnerBuilder();
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

class GetSnapshot200ResponseAlarmsInnerStateEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'planned')
  static const GetSnapshot200ResponseAlarmsInnerStateEnum planned = _$getSnapshot200ResponseAlarmsInnerStateEnum_planned;
  @BuiltValueEnumConst(wireName: r'triggered')
  static const GetSnapshot200ResponseAlarmsInnerStateEnum triggered = _$getSnapshot200ResponseAlarmsInnerStateEnum_triggered;
  @BuiltValueEnumConst(wireName: r'missed')
  static const GetSnapshot200ResponseAlarmsInnerStateEnum missed = _$getSnapshot200ResponseAlarmsInnerStateEnum_missed;
  @BuiltValueEnumConst(wireName: r'discarded')
  static const GetSnapshot200ResponseAlarmsInnerStateEnum discarded = _$getSnapshot200ResponseAlarmsInnerStateEnum_discarded;

  static Serializer<GetSnapshot200ResponseAlarmsInnerStateEnum> get serializer => _$getSnapshot200ResponseAlarmsInnerStateEnumSerializer;

  const GetSnapshot200ResponseAlarmsInnerStateEnum._(String name): super(name);

  static BuiltSet<GetSnapshot200ResponseAlarmsInnerStateEnum> get values => _$getSnapshot200ResponseAlarmsInnerStateEnumValues;
  static GetSnapshot200ResponseAlarmsInnerStateEnum valueOf(String name) => _$getSnapshot200ResponseAlarmsInnerStateEnumValueOf(name);
}

