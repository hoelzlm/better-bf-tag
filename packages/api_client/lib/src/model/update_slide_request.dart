//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_slide_request.g.dart';

/// UpdateSlideRequest
///
/// Properties:
/// * [title] 
/// * [body] 
/// * [durationSeconds] 
/// * [active] 
@BuiltValue()
abstract class UpdateSlideRequest implements Built<UpdateSlideRequest, UpdateSlideRequestBuilder> {
  @BuiltValueField(wireName: r'title')
  String? get title;

  @BuiltValueField(wireName: r'body')
  String? get body;

  @BuiltValueField(wireName: r'duration_seconds')
  int? get durationSeconds;

  @BuiltValueField(wireName: r'active')
  bool? get active;

  UpdateSlideRequest._();

  factory UpdateSlideRequest([void updates(UpdateSlideRequestBuilder b)]) = _$UpdateSlideRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateSlideRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateSlideRequest> get serializer => _$UpdateSlideRequestSerializer();
}

class _$UpdateSlideRequestSerializer implements PrimitiveSerializer<UpdateSlideRequest> {
  @override
  final Iterable<Type> types = const [UpdateSlideRequest, _$UpdateSlideRequest];

  @override
  final String wireName = r'UpdateSlideRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateSlideRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.title != null) {
      yield r'title';
      yield serializers.serialize(
        object.title,
        specifiedType: const FullType(String),
      );
    }
    if (object.body != null) {
      yield r'body';
      yield serializers.serialize(
        object.body,
        specifiedType: const FullType(String),
      );
    }
    if (object.durationSeconds != null) {
      yield r'duration_seconds';
      yield serializers.serialize(
        object.durationSeconds,
        specifiedType: const FullType(int),
      );
    }
    if (object.active != null) {
      yield r'active';
      yield serializers.serialize(
        object.active,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateSlideRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateSlideRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'body':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.body = valueDes;
          break;
        case r'duration_seconds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.durationSeconds = valueDes;
          break;
        case r'active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.active = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateSlideRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateSlideRequestBuilder();
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

