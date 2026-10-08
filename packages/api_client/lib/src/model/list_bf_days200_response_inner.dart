//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'list_bf_days200_response_inner.g.dart';

/// ListBfDays200ResponseInner
///
/// Properties:
/// * [id] 
/// * [name] 
/// * [startsAt] 
/// * [endsAt] 
/// * [state] 
/// * [anonymizedAt] 
/// * [createdAt] 
@BuiltValue()
abstract class ListBfDays200ResponseInner implements Built<ListBfDays200ResponseInner, ListBfDays200ResponseInnerBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'starts_at')
  String get startsAt;

  @BuiltValueField(wireName: r'ends_at')
  String get endsAt;

  @BuiltValueField(wireName: r'state')
  ListBfDays200ResponseInnerStateEnum get state;
  // enum stateEnum {  planning,  running,  ended,  };

  @BuiltValueField(wireName: r'anonymized_at')
  String? get anonymizedAt;

  @BuiltValueField(wireName: r'created_at')
  String get createdAt;

  ListBfDays200ResponseInner._();

  factory ListBfDays200ResponseInner([void updates(ListBfDays200ResponseInnerBuilder b)]) = _$ListBfDays200ResponseInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ListBfDays200ResponseInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ListBfDays200ResponseInner> get serializer => _$ListBfDays200ResponseInnerSerializer();
}

class _$ListBfDays200ResponseInnerSerializer implements PrimitiveSerializer<ListBfDays200ResponseInner> {
  @override
  final Iterable<Type> types = const [ListBfDays200ResponseInner, _$ListBfDays200ResponseInner];

  @override
  final String wireName = r'ListBfDays200ResponseInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ListBfDays200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'starts_at';
    yield serializers.serialize(
      object.startsAt,
      specifiedType: const FullType(String),
    );
    yield r'ends_at';
    yield serializers.serialize(
      object.endsAt,
      specifiedType: const FullType(String),
    );
    yield r'state';
    yield serializers.serialize(
      object.state,
      specifiedType: const FullType(ListBfDays200ResponseInnerStateEnum),
    );
    yield r'anonymized_at';
    yield object.anonymizedAt == null ? null : serializers.serialize(
      object.anonymizedAt,
      specifiedType: const FullType.nullable(String),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ListBfDays200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ListBfDays200ResponseInnerBuilder result,
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
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'starts_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.startsAt = valueDes;
          break;
        case r'ends_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.endsAt = valueDes;
          break;
        case r'state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ListBfDays200ResponseInnerStateEnum),
          ) as ListBfDays200ResponseInnerStateEnum;
          result.state = valueDes;
          break;
        case r'anonymized_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.anonymizedAt = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.createdAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ListBfDays200ResponseInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ListBfDays200ResponseInnerBuilder();
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

class ListBfDays200ResponseInnerStateEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'planning')
  static const ListBfDays200ResponseInnerStateEnum planning = _$listBfDays200ResponseInnerStateEnum_planning;
  @BuiltValueEnumConst(wireName: r'running')
  static const ListBfDays200ResponseInnerStateEnum running = _$listBfDays200ResponseInnerStateEnum_running;
  @BuiltValueEnumConst(wireName: r'ended')
  static const ListBfDays200ResponseInnerStateEnum ended = _$listBfDays200ResponseInnerStateEnum_ended;

  static Serializer<ListBfDays200ResponseInnerStateEnum> get serializer => _$listBfDays200ResponseInnerStateEnumSerializer;

  const ListBfDays200ResponseInnerStateEnum._(String name): super(name);

  static BuiltSet<ListBfDays200ResponseInnerStateEnum> get values => _$listBfDays200ResponseInnerStateEnumValues;
  static ListBfDays200ResponseInnerStateEnum valueOf(String name) => _$listBfDays200ResponseInnerStateEnumValueOf(name);
}

