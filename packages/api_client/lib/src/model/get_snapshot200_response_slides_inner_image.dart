//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_snapshot200_response_slides_inner_image.g.dart';

/// GetSnapshot200ResponseSlidesInnerImage
///
/// Properties:
/// * [contentType] 
/// * [sizeBytes] 
/// * [version] 
@BuiltValue()
abstract class GetSnapshot200ResponseSlidesInnerImage implements Built<GetSnapshot200ResponseSlidesInnerImage, GetSnapshot200ResponseSlidesInnerImageBuilder> {
  @BuiltValueField(wireName: r'content_type')
  String get contentType;

  @BuiltValueField(wireName: r'size_bytes')
  int get sizeBytes;

  @BuiltValueField(wireName: r'version')
  String get version;

  GetSnapshot200ResponseSlidesInnerImage._();

  factory GetSnapshot200ResponseSlidesInnerImage([void updates(GetSnapshot200ResponseSlidesInnerImageBuilder b)]) = _$GetSnapshot200ResponseSlidesInnerImage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetSnapshot200ResponseSlidesInnerImageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetSnapshot200ResponseSlidesInnerImage> get serializer => _$GetSnapshot200ResponseSlidesInnerImageSerializer();
}

class _$GetSnapshot200ResponseSlidesInnerImageSerializer implements PrimitiveSerializer<GetSnapshot200ResponseSlidesInnerImage> {
  @override
  final Iterable<Type> types = const [GetSnapshot200ResponseSlidesInnerImage, _$GetSnapshot200ResponseSlidesInnerImage];

  @override
  final String wireName = r'GetSnapshot200ResponseSlidesInnerImage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetSnapshot200ResponseSlidesInnerImage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'content_type';
    yield serializers.serialize(
      object.contentType,
      specifiedType: const FullType(String),
    );
    yield r'size_bytes';
    yield serializers.serialize(
      object.sizeBytes,
      specifiedType: const FullType(int),
    );
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetSnapshot200ResponseSlidesInnerImage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetSnapshot200ResponseSlidesInnerImageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'content_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.contentType = valueDes;
          break;
        case r'size_bytes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.sizeBytes = valueDes;
          break;
        case r'version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.version = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetSnapshot200ResponseSlidesInnerImage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetSnapshot200ResponseSlidesInnerImageBuilder();
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

