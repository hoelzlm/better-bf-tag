//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_snapshot200_response_alarms_inner_recipients_inner.g.dart';

/// GetSnapshot200ResponseAlarmsInnerRecipientsInner
///
/// Properties:
/// * [personId] 
/// * [displayName] 
/// * [vehicleId] 
/// * [function_] 
/// * [hasDevice] 
/// * [acknowledgedAt] 
@BuiltValue()
abstract class GetSnapshot200ResponseAlarmsInnerRecipientsInner implements Built<GetSnapshot200ResponseAlarmsInnerRecipientsInner, GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder> {
  @BuiltValueField(wireName: r'person_id')
  String get personId;

  @BuiltValueField(wireName: r'display_name')
  String get displayName;

  @BuiltValueField(wireName: r'vehicle_id')
  String get vehicleId;

  @BuiltValueField(wireName: r'function')
  String get function_;

  @BuiltValueField(wireName: r'has_device')
  bool get hasDevice;

  @BuiltValueField(wireName: r'acknowledged_at')
  String? get acknowledgedAt;

  GetSnapshot200ResponseAlarmsInnerRecipientsInner._();

  factory GetSnapshot200ResponseAlarmsInnerRecipientsInner([void updates(GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder b)]) = _$GetSnapshot200ResponseAlarmsInnerRecipientsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetSnapshot200ResponseAlarmsInnerRecipientsInner> get serializer => _$GetSnapshot200ResponseAlarmsInnerRecipientsInnerSerializer();
}

class _$GetSnapshot200ResponseAlarmsInnerRecipientsInnerSerializer implements PrimitiveSerializer<GetSnapshot200ResponseAlarmsInnerRecipientsInner> {
  @override
  final Iterable<Type> types = const [GetSnapshot200ResponseAlarmsInnerRecipientsInner, _$GetSnapshot200ResponseAlarmsInnerRecipientsInner];

  @override
  final String wireName = r'GetSnapshot200ResponseAlarmsInnerRecipientsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetSnapshot200ResponseAlarmsInnerRecipientsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'person_id';
    yield serializers.serialize(
      object.personId,
      specifiedType: const FullType(String),
    );
    yield r'display_name';
    yield serializers.serialize(
      object.displayName,
      specifiedType: const FullType(String),
    );
    yield r'vehicle_id';
    yield serializers.serialize(
      object.vehicleId,
      specifiedType: const FullType(String),
    );
    yield r'function';
    yield serializers.serialize(
      object.function_,
      specifiedType: const FullType(String),
    );
    yield r'has_device';
    yield serializers.serialize(
      object.hasDevice,
      specifiedType: const FullType(bool),
    );
    yield r'acknowledged_at';
    yield object.acknowledgedAt == null ? null : serializers.serialize(
      object.acknowledgedAt,
      specifiedType: const FullType.nullable(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetSnapshot200ResponseAlarmsInnerRecipientsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'person_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.personId = valueDes;
          break;
        case r'display_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displayName = valueDes;
          break;
        case r'vehicle_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vehicleId = valueDes;
          break;
        case r'function':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.function_ = valueDes;
          break;
        case r'has_device':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.hasDevice = valueDes;
          break;
        case r'acknowledged_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.acknowledgedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetSnapshot200ResponseAlarmsInnerRecipientsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder();
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

