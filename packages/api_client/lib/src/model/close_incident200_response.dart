//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bftag_api_client/src/model/get_snapshot200_response_incidents_inner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'close_incident200_response.g.dart';

/// CloseIncident200Response
///
/// Properties:
/// * [incident] 
/// * [discardedAlarmIds] 
@BuiltValue()
abstract class CloseIncident200Response implements Built<CloseIncident200Response, CloseIncident200ResponseBuilder> {
  @BuiltValueField(wireName: r'incident')
  GetSnapshot200ResponseIncidentsInner get incident;

  @BuiltValueField(wireName: r'discarded_alarm_ids')
  BuiltList<String> get discardedAlarmIds;

  CloseIncident200Response._();

  factory CloseIncident200Response([void updates(CloseIncident200ResponseBuilder b)]) = _$CloseIncident200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CloseIncident200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CloseIncident200Response> get serializer => _$CloseIncident200ResponseSerializer();
}

class _$CloseIncident200ResponseSerializer implements PrimitiveSerializer<CloseIncident200Response> {
  @override
  final Iterable<Type> types = const [CloseIncident200Response, _$CloseIncident200Response];

  @override
  final String wireName = r'CloseIncident200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CloseIncident200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'incident';
    yield serializers.serialize(
      object.incident,
      specifiedType: const FullType(GetSnapshot200ResponseIncidentsInner),
    );
    yield r'discarded_alarm_ids';
    yield serializers.serialize(
      object.discardedAlarmIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CloseIncident200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CloseIncident200ResponseBuilder result,
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
        case r'discarded_alarm_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.discardedAlarmIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CloseIncident200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CloseIncident200ResponseBuilder();
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

