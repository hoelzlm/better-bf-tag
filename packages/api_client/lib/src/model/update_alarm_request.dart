//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_alarm_request.g.dart';

/// UpdateAlarmRequest
///
/// Properties:
/// * [scheduledAt] 
/// * [offsetMinutes] 
/// * [vehicleIds] 
@BuiltValue()
abstract class UpdateAlarmRequest implements Built<UpdateAlarmRequest, UpdateAlarmRequestBuilder> {
  @BuiltValueField(wireName: r'scheduled_at')
  DateTime? get scheduledAt;

  @BuiltValueField(wireName: r'offset_minutes')
  int? get offsetMinutes;

  @BuiltValueField(wireName: r'vehicle_ids')
  BuiltList<String>? get vehicleIds;

  UpdateAlarmRequest._();

  factory UpdateAlarmRequest([void updates(UpdateAlarmRequestBuilder b)]) = _$UpdateAlarmRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateAlarmRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateAlarmRequest> get serializer => _$UpdateAlarmRequestSerializer();
}

class _$UpdateAlarmRequestSerializer implements PrimitiveSerializer<UpdateAlarmRequest> {
  @override
  final Iterable<Type> types = const [UpdateAlarmRequest, _$UpdateAlarmRequest];

  @override
  final String wireName = r'UpdateAlarmRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateAlarmRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.scheduledAt != null) {
      yield r'scheduled_at';
      yield serializers.serialize(
        object.scheduledAt,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.offsetMinutes != null) {
      yield r'offset_minutes';
      yield serializers.serialize(
        object.offsetMinutes,
        specifiedType: const FullType(int),
      );
    }
    if (object.vehicleIds != null) {
      yield r'vehicle_ids';
      yield serializers.serialize(
        object.vehicleIds,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateAlarmRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateAlarmRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'scheduled_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.scheduledAt = valueDes;
          break;
        case r'offset_minutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.offsetMinutes = valueDes;
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
  UpdateAlarmRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateAlarmRequestBuilder();
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

