//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_snapshot200_response_incidents_inner.g.dart';

/// GetSnapshot200ResponseIncidentsInner
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
@BuiltValue()
abstract class GetSnapshot200ResponseIncidentsInner implements Built<GetSnapshot200ResponseIncidentsInner, GetSnapshot200ResponseIncidentsInnerBuilder> {
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
  GetSnapshot200ResponseIncidentsInnerStateEnum get state;
  // enum stateEnum {  draft,  running,  closed,  discarded,  };

  @BuiltValueField(wireName: r'created_at')
  String get createdAt;

  @BuiltValueField(wireName: r'updated_at')
  String get updatedAt;

  @BuiltValueField(wireName: r'closed_at')
  String? get closedAt;

  @BuiltValueField(wireName: r'script')
  String? get script;

  GetSnapshot200ResponseIncidentsInner._();

  factory GetSnapshot200ResponseIncidentsInner([void updates(GetSnapshot200ResponseIncidentsInnerBuilder b)]) = _$GetSnapshot200ResponseIncidentsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetSnapshot200ResponseIncidentsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetSnapshot200ResponseIncidentsInner> get serializer => _$GetSnapshot200ResponseIncidentsInnerSerializer();
}

class _$GetSnapshot200ResponseIncidentsInnerSerializer implements PrimitiveSerializer<GetSnapshot200ResponseIncidentsInner> {
  @override
  final Iterable<Type> types = const [GetSnapshot200ResponseIncidentsInner, _$GetSnapshot200ResponseIncidentsInner];

  @override
  final String wireName = r'GetSnapshot200ResponseIncidentsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetSnapshot200ResponseIncidentsInner object, {
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
      specifiedType: const FullType(GetSnapshot200ResponseIncidentsInnerStateEnum),
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
  }

  @override
  Object serialize(
    Serializers serializers,
    GetSnapshot200ResponseIncidentsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetSnapshot200ResponseIncidentsInnerBuilder result,
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
            specifiedType: const FullType(GetSnapshot200ResponseIncidentsInnerStateEnum),
          ) as GetSnapshot200ResponseIncidentsInnerStateEnum;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetSnapshot200ResponseIncidentsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetSnapshot200ResponseIncidentsInnerBuilder();
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

class GetSnapshot200ResponseIncidentsInnerStateEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'draft')
  static const GetSnapshot200ResponseIncidentsInnerStateEnum draft = _$getSnapshot200ResponseIncidentsInnerStateEnum_draft;
  @BuiltValueEnumConst(wireName: r'running')
  static const GetSnapshot200ResponseIncidentsInnerStateEnum running = _$getSnapshot200ResponseIncidentsInnerStateEnum_running;
  @BuiltValueEnumConst(wireName: r'closed')
  static const GetSnapshot200ResponseIncidentsInnerStateEnum closed = _$getSnapshot200ResponseIncidentsInnerStateEnum_closed;
  @BuiltValueEnumConst(wireName: r'discarded')
  static const GetSnapshot200ResponseIncidentsInnerStateEnum discarded = _$getSnapshot200ResponseIncidentsInnerStateEnum_discarded;

  static Serializer<GetSnapshot200ResponseIncidentsInnerStateEnum> get serializer => _$getSnapshot200ResponseIncidentsInnerStateEnumSerializer;

  const GetSnapshot200ResponseIncidentsInnerStateEnum._(String name): super(name);

  static BuiltSet<GetSnapshot200ResponseIncidentsInnerStateEnum> get values => _$getSnapshot200ResponseIncidentsInnerStateEnumValues;
  static GetSnapshot200ResponseIncidentsInnerStateEnum valueOf(String name) => _$getSnapshot200ResponseIncidentsInnerStateEnumValueOf(name);
}

