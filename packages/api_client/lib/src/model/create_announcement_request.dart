//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_announcement_request.g.dart';

/// CreateAnnouncementRequest
///
/// Properties:
/// * [text] 
/// * [shiftId] 
@BuiltValue()
abstract class CreateAnnouncementRequest implements Built<CreateAnnouncementRequest, CreateAnnouncementRequestBuilder> {
  @BuiltValueField(wireName: r'text')
  String get text;

  @BuiltValueField(wireName: r'shift_id')
  String? get shiftId;

  CreateAnnouncementRequest._();

  factory CreateAnnouncementRequest([void updates(CreateAnnouncementRequestBuilder b)]) = _$CreateAnnouncementRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateAnnouncementRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateAnnouncementRequest> get serializer => _$CreateAnnouncementRequestSerializer();
}

class _$CreateAnnouncementRequestSerializer implements PrimitiveSerializer<CreateAnnouncementRequest> {
  @override
  final Iterable<Type> types = const [CreateAnnouncementRequest, _$CreateAnnouncementRequest];

  @override
  final String wireName = r'CreateAnnouncementRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateAnnouncementRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'text';
    yield serializers.serialize(
      object.text,
      specifiedType: const FullType(String),
    );
    if (object.shiftId != null) {
      yield r'shift_id';
      yield serializers.serialize(
        object.shiftId,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateAnnouncementRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateAnnouncementRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.text = valueDes;
          break;
        case r'shift_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.shiftId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateAnnouncementRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateAnnouncementRequestBuilder();
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

