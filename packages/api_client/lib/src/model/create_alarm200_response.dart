//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bftag_api_client/src/model/create_alarm200_response_double_crewed_inner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:bftag_api_client/src/model/get_snapshot200_response_alarms_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_alarm200_response.g.dart';

/// CreateAlarm200Response
///
/// Properties:
/// * [alarm] 
/// * [doubleCrewed] 
@BuiltValue()
abstract class CreateAlarm200Response implements Built<CreateAlarm200Response, CreateAlarm200ResponseBuilder> {
  @BuiltValueField(wireName: r'alarm')
  GetSnapshot200ResponseAlarmsInner get alarm;

  @BuiltValueField(wireName: r'double_crewed')
  BuiltList<CreateAlarm200ResponseDoubleCrewedInner> get doubleCrewed;

  CreateAlarm200Response._();

  factory CreateAlarm200Response([void updates(CreateAlarm200ResponseBuilder b)]) = _$CreateAlarm200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateAlarm200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateAlarm200Response> get serializer => _$CreateAlarm200ResponseSerializer();
}

class _$CreateAlarm200ResponseSerializer implements PrimitiveSerializer<CreateAlarm200Response> {
  @override
  final Iterable<Type> types = const [CreateAlarm200Response, _$CreateAlarm200Response];

  @override
  final String wireName = r'CreateAlarm200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateAlarm200Response object, {
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
      specifiedType: const FullType(BuiltList, [FullType(CreateAlarm200ResponseDoubleCrewedInner)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateAlarm200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateAlarm200ResponseBuilder result,
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
            specifiedType: const FullType(BuiltList, [FullType(CreateAlarm200ResponseDoubleCrewedInner)]),
          ) as BuiltList<CreateAlarm200ResponseDoubleCrewedInner>;
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
  CreateAlarm200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateAlarm200ResponseBuilder();
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

