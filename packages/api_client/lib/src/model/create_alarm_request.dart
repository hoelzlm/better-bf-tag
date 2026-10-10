//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_alarm_request.g.dart';

/// CreateAlarmRequest
///
/// Properties:
/// * [id] 
/// * [vehicleIds] 
/// * [scheduledAt] 
/// * [offsetMinutes] 
@BuiltValue()
abstract class CreateAlarmRequest implements Built<CreateAlarmRequest, CreateAlarmRequestBuilder> {
  @BuiltValueField(wireName: r'id')
  String? get id;

  @BuiltValueField(wireName: r'vehicle_ids')
  BuiltList<String> get vehicleIds;

  @BuiltValueField(wireName: r'scheduled_at')
  DateTime? get scheduledAt;

  @BuiltValueField(wireName: r'offset_minutes')
  int? get offsetMinutes;

  CreateAlarmRequest._();

  factory CreateAlarmRequest([void updates(CreateAlarmRequestBuilder b)]) = _$CreateAlarmRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateAlarmRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateAlarmRequest> get serializer => _$CreateAlarmRequestSerializer();
}

class _$CreateAlarmRequestSerializer implements PrimitiveSerializer<CreateAlarmRequest> {
  @override
  final Iterable<Type> types = const [CreateAlarmRequest, _$CreateAlarmRequest];

  @override
  final String wireName = r'CreateAlarmRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateAlarmRequest object, {
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
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateAlarmRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateAlarmRequestBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateAlarmRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateAlarmRequestBuilder();
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

