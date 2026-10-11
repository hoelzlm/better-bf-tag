//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_snapshot200_response_announcements_inner.g.dart';

/// GetSnapshot200ResponseAnnouncementsInner
///
/// Properties:
/// * [id] 
/// * [bfDayId] 
/// * [shiftId] 
/// * [text] 
/// * [createdBy] 
/// * [createdAt] 
@BuiltValue()
abstract class GetSnapshot200ResponseAnnouncementsInner implements Built<GetSnapshot200ResponseAnnouncementsInner, GetSnapshot200ResponseAnnouncementsInnerBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'bf_day_id')
  String get bfDayId;

  @BuiltValueField(wireName: r'shift_id')
  String? get shiftId;

  @BuiltValueField(wireName: r'text')
  String get text;

  @BuiltValueField(wireName: r'created_by')
  String get createdBy;

  @BuiltValueField(wireName: r'created_at')
  String get createdAt;

  GetSnapshot200ResponseAnnouncementsInner._();

  factory GetSnapshot200ResponseAnnouncementsInner([void updates(GetSnapshot200ResponseAnnouncementsInnerBuilder b)]) = _$GetSnapshot200ResponseAnnouncementsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetSnapshot200ResponseAnnouncementsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetSnapshot200ResponseAnnouncementsInner> get serializer => _$GetSnapshot200ResponseAnnouncementsInnerSerializer();
}

class _$GetSnapshot200ResponseAnnouncementsInnerSerializer implements PrimitiveSerializer<GetSnapshot200ResponseAnnouncementsInner> {
  @override
  final Iterable<Type> types = const [GetSnapshot200ResponseAnnouncementsInner, _$GetSnapshot200ResponseAnnouncementsInner];

  @override
  final String wireName = r'GetSnapshot200ResponseAnnouncementsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetSnapshot200ResponseAnnouncementsInner object, {
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
    yield r'shift_id';
    yield object.shiftId == null ? null : serializers.serialize(
      object.shiftId,
      specifiedType: const FullType.nullable(String),
    );
    yield r'text';
    yield serializers.serialize(
      object.text,
      specifiedType: const FullType(String),
    );
    yield r'created_by';
    yield serializers.serialize(
      object.createdBy,
      specifiedType: const FullType(String),
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
    GetSnapshot200ResponseAnnouncementsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetSnapshot200ResponseAnnouncementsInnerBuilder result,
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
        case r'shift_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.shiftId = valueDes;
          break;
        case r'text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.text = valueDes;
          break;
        case r'created_by':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.createdBy = valueDes;
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
  GetSnapshot200ResponseAnnouncementsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetSnapshot200ResponseAnnouncementsInnerBuilder();
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

