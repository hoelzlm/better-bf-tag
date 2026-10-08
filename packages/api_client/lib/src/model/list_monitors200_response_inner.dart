//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'list_monitors200_response_inner.g.dart';

/// ListMonitors200ResponseInner
///
/// Properties:
/// * [id] 
/// * [name] 
/// * [paired] 
/// * [pairedAt] 
/// * [lastSeenAt] 
/// * [revokedAt] 
/// * [createdAt] 
@BuiltValue()
abstract class ListMonitors200ResponseInner implements Built<ListMonitors200ResponseInner, ListMonitors200ResponseInnerBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'paired')
  bool get paired;

  @BuiltValueField(wireName: r'paired_at')
  String? get pairedAt;

  @BuiltValueField(wireName: r'last_seen_at')
  String? get lastSeenAt;

  @BuiltValueField(wireName: r'revoked_at')
  String? get revokedAt;

  @BuiltValueField(wireName: r'created_at')
  String get createdAt;

  ListMonitors200ResponseInner._();

  factory ListMonitors200ResponseInner([void updates(ListMonitors200ResponseInnerBuilder b)]) = _$ListMonitors200ResponseInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ListMonitors200ResponseInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ListMonitors200ResponseInner> get serializer => _$ListMonitors200ResponseInnerSerializer();
}

class _$ListMonitors200ResponseInnerSerializer implements PrimitiveSerializer<ListMonitors200ResponseInner> {
  @override
  final Iterable<Type> types = const [ListMonitors200ResponseInner, _$ListMonitors200ResponseInner];

  @override
  final String wireName = r'ListMonitors200ResponseInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ListMonitors200ResponseInner object, {
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
    yield r'paired';
    yield serializers.serialize(
      object.paired,
      specifiedType: const FullType(bool),
    );
    yield r'paired_at';
    yield object.pairedAt == null ? null : serializers.serialize(
      object.pairedAt,
      specifiedType: const FullType.nullable(String),
    );
    yield r'last_seen_at';
    yield object.lastSeenAt == null ? null : serializers.serialize(
      object.lastSeenAt,
      specifiedType: const FullType.nullable(String),
    );
    yield r'revoked_at';
    yield object.revokedAt == null ? null : serializers.serialize(
      object.revokedAt,
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
    ListMonitors200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ListMonitors200ResponseInnerBuilder result,
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
        case r'paired':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.paired = valueDes;
          break;
        case r'paired_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.pairedAt = valueDes;
          break;
        case r'last_seen_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.lastSeenAt = valueDes;
          break;
        case r'revoked_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.revokedAt = valueDes;
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
  ListMonitors200ResponseInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ListMonitors200ResponseInnerBuilder();
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

