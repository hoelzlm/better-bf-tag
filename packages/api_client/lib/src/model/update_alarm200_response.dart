//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bftag_api_client/src/model/get_snapshot200_response_alarms_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_alarm200_response.g.dart';

/// UpdateAlarm200Response
///
/// Properties:
/// * [alarm] 
@BuiltValue()
abstract class UpdateAlarm200Response implements Built<UpdateAlarm200Response, UpdateAlarm200ResponseBuilder> {
  @BuiltValueField(wireName: r'alarm')
  GetSnapshot200ResponseAlarmsInner get alarm;

  UpdateAlarm200Response._();

  factory UpdateAlarm200Response([void updates(UpdateAlarm200ResponseBuilder b)]) = _$UpdateAlarm200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateAlarm200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateAlarm200Response> get serializer => _$UpdateAlarm200ResponseSerializer();
}

class _$UpdateAlarm200ResponseSerializer implements PrimitiveSerializer<UpdateAlarm200Response> {
  @override
  final Iterable<Type> types = const [UpdateAlarm200Response, _$UpdateAlarm200Response];

  @override
  final String wireName = r'UpdateAlarm200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateAlarm200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'alarm';
    yield serializers.serialize(
      object.alarm,
      specifiedType: const FullType(GetSnapshot200ResponseAlarmsInner),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateAlarm200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateAlarm200ResponseBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateAlarm200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateAlarm200ResponseBuilder();
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

