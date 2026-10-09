//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'trigger_alarm_request.g.dart';

/// TriggerAlarmRequest
///
/// Properties:
/// * [id] 
/// * [vehicleIds] 
@BuiltValue()
abstract class TriggerAlarmRequest implements Built<TriggerAlarmRequest, TriggerAlarmRequestBuilder> {
  @BuiltValueField(wireName: r'id')
  String? get id;

  @BuiltValueField(wireName: r'vehicle_ids')
  BuiltList<String> get vehicleIds;

  TriggerAlarmRequest._();

  factory TriggerAlarmRequest([void updates(TriggerAlarmRequestBuilder b)]) = _$TriggerAlarmRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TriggerAlarmRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TriggerAlarmRequest> get serializer => _$TriggerAlarmRequestSerializer();
}

class _$TriggerAlarmRequestSerializer implements PrimitiveSerializer<TriggerAlarmRequest> {
  @override
  final Iterable<Type> types = const [TriggerAlarmRequest, _$TriggerAlarmRequest];

  @override
  final String wireName = r'TriggerAlarmRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TriggerAlarmRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.id != null) {
      yield r'id';
      yield serializers.serialize(
        object.id,
        specifiedType: const FullType(String),
      );
    }
    yield r'vehicle_ids';
    yield serializers.serialize(
      object.vehicleIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TriggerAlarmRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TriggerAlarmRequestBuilder result,
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
        case r'vehicle_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.vehicleIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TriggerAlarmRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TriggerAlarmRequestBuilder();
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

