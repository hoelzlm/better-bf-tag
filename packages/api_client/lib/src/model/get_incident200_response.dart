//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:bftag_api_client/src/model/get_snapshot200_response_alarms_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_incident200_response.g.dart';

/// GetIncident200Response
///
/// Properties:
/// * [id] 
/// * [bfDayId] 
/// * [number] 
/// * [keyword] 
/// * [address] 
/// * [report] 
/// * [state] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [closedAt] 
/// * [script] 
/// * [alarms] 
@BuiltValue()
abstract class GetIncident200Response implements Built<GetIncident200Response, GetIncident200ResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'bf_day_id')
  String get bfDayId;

  @BuiltValueField(wireName: r'number')
  int get number;

  @BuiltValueField(wireName: r'keyword')
  String get keyword;

  @BuiltValueField(wireName: r'address')
  String get address;

  @BuiltValueField(wireName: r'report')
  String get report;

  @BuiltValueField(wireName: r'state')
  GetIncident200ResponseStateEnum get state;
  // enum stateEnum {  draft,  running,  closed,  discarded,  };

  @BuiltValueField(wireName: r'created_at')
  String get createdAt;

  @BuiltValueField(wireName: r'updated_at')
  String get updatedAt;

  @BuiltValueField(wireName: r'closed_at')
  String? get closedAt;

  @BuiltValueField(wireName: r'script')
  String? get script;

  @BuiltValueField(wireName: r'alarms')
  BuiltList<GetSnapshot200ResponseAlarmsInner> get alarms;

  GetIncident200Response._();

  factory GetIncident200Response([void updates(GetIncident200ResponseBuilder b)]) = _$GetIncident200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetIncident200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetIncident200Response> get serializer => _$GetIncident200ResponseSerializer();
}

class _$GetIncident200ResponseSerializer implements PrimitiveSerializer<GetIncident200Response> {
  @override
  final Iterable<Type> types = const [GetIncident200Response, _$GetIncident200Response];

  @override
  final String wireName = r'GetIncident200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetIncident200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'bf_day_id';
    yield serializers.serialize(
      object.bfDayId,
      specifiedType: const FullType(String),
    );
    yield r'number';
    yield serializers.serialize(
      object.number,
      specifiedType: const FullType(int),
    );
    yield r'keyword';
    yield serializers.serialize(
      object.keyword,
      specifiedType: const FullType(String),
    );
    yield r'address';
    yield serializers.serialize(
      object.address,
      specifiedType: const FullType(String),
    );
    yield r'report';
    yield serializers.serialize(
      object.report,
      specifiedType: const FullType(String),
    );
    yield r'state';
    yield serializers.serialize(
      object.state,
      specifiedType: const FullType(GetIncident200ResponseStateEnum),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(String),
    );
    yield r'updated_at';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(String),
    );
    yield r'closed_at';
    yield object.closedAt == null ? null : serializers.serialize(
      object.closedAt,
      specifiedType: const FullType.nullable(String),
    );
    if (object.script != null) {
      yield r'script';
      yield serializers.serialize(
        object.script,
        specifiedType: const FullType(String),
      );
    }
    yield r'alarms';
    yield serializers.serialize(
      object.alarms,
      specifiedType: const FullType(BuiltList, [FullType(GetSnapshot200ResponseAlarmsInner)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetIncident200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetIncident200ResponseBuilder result,
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
        case r'bf_day_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.bfDayId = valueDes;
          break;
        case r'number':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.number = valueDes;
          break;
        case r'keyword':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.keyword = valueDes;
          break;
        case r'address':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.address = valueDes;
          break;
        case r'report':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.report = valueDes;
          break;
        case r'state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GetIncident200ResponseStateEnum),
          ) as GetIncident200ResponseStateEnum;
          result.state = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.createdAt = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.updatedAt = valueDes;
          break;
        case r'closed_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.closedAt = valueDes;
          break;
        case r'script':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.script = valueDes;
          break;
        case r'alarms':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(GetSnapshot200ResponseAlarmsInner)]),
          ) as BuiltList<GetSnapshot200ResponseAlarmsInner>;
          result.alarms.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetIncident200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetIncident200ResponseBuilder();
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

class GetIncident200ResponseStateEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'draft')
  static const GetIncident200ResponseStateEnum draft = _$getIncident200ResponseStateEnum_draft;
  @BuiltValueEnumConst(wireName: r'running')
  static const GetIncident200ResponseStateEnum running = _$getIncident200ResponseStateEnum_running;
  @BuiltValueEnumConst(wireName: r'closed')
  static const GetIncident200ResponseStateEnum closed = _$getIncident200ResponseStateEnum_closed;
  @BuiltValueEnumConst(wireName: r'discarded')
  static const GetIncident200ResponseStateEnum discarded = _$getIncident200ResponseStateEnum_discarded;

  static Serializer<GetIncident200ResponseStateEnum> get serializer => _$getIncident200ResponseStateEnumSerializer;

  const GetIncident200ResponseStateEnum._(String name): super(name);

  static BuiltSet<GetIncident200ResponseStateEnum> get values => _$getIncident200ResponseStateEnumValues;
  static GetIncident200ResponseStateEnum valueOf(String name) => _$getIncident200ResponseStateEnumValueOf(name);
}

