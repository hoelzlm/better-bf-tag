//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_bf_day_anonymization_preview200_response.g.dart';

/// GetBfDayAnonymizationPreview200Response
///
/// Properties:
/// * [participations] 
/// * [crewAssignments] 
/// * [alarmRecipients] 
/// * [statusEvents] 
/// * [personsDeleted] 
@BuiltValue()
abstract class GetBfDayAnonymizationPreview200Response implements Built<GetBfDayAnonymizationPreview200Response, GetBfDayAnonymizationPreview200ResponseBuilder> {
  @BuiltValueField(wireName: r'participations')
  int get participations;

  @BuiltValueField(wireName: r'crew_assignments')
  int get crewAssignments;

  @BuiltValueField(wireName: r'alarm_recipients')
  int get alarmRecipients;

  @BuiltValueField(wireName: r'status_events')
  int get statusEvents;

  @BuiltValueField(wireName: r'persons_deleted')
  int get personsDeleted;

  GetBfDayAnonymizationPreview200Response._();

  factory GetBfDayAnonymizationPreview200Response([void updates(GetBfDayAnonymizationPreview200ResponseBuilder b)]) = _$GetBfDayAnonymizationPreview200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetBfDayAnonymizationPreview200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetBfDayAnonymizationPreview200Response> get serializer => _$GetBfDayAnonymizationPreview200ResponseSerializer();
}

class _$GetBfDayAnonymizationPreview200ResponseSerializer implements PrimitiveSerializer<GetBfDayAnonymizationPreview200Response> {
  @override
  final Iterable<Type> types = const [GetBfDayAnonymizationPreview200Response, _$GetBfDayAnonymizationPreview200Response];

  @override
  final String wireName = r'GetBfDayAnonymizationPreview200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetBfDayAnonymizationPreview200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'participations';
    yield serializers.serialize(
      object.participations,
      specifiedType: const FullType(int),
    );
    yield r'crew_assignments';
    yield serializers.serialize(
      object.crewAssignments,
      specifiedType: const FullType(int),
    );
    yield r'alarm_recipients';
    yield serializers.serialize(
      object.alarmRecipients,
      specifiedType: const FullType(int),
    );
    yield r'status_events';
    yield serializers.serialize(
      object.statusEvents,
      specifiedType: const FullType(int),
    );
    yield r'persons_deleted';
    yield serializers.serialize(
      object.personsDeleted,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetBfDayAnonymizationPreview200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetBfDayAnonymizationPreview200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'participations':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.participations = valueDes;
          break;
        case r'crew_assignments':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.crewAssignments = valueDes;
          break;
        case r'alarm_recipients':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.alarmRecipients = valueDes;
          break;
        case r'status_events':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.statusEvents = valueDes;
          break;
        case r'persons_deleted':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.personsDeleted = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetBfDayAnonymizationPreview200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetBfDayAnonymizationPreview200ResponseBuilder();
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

