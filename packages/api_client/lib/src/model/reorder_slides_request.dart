//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reorder_slides_request.g.dart';

/// ReorderSlidesRequest
///
/// Properties:
/// * [slideIds] 
@BuiltValue()
abstract class ReorderSlidesRequest implements Built<ReorderSlidesRequest, ReorderSlidesRequestBuilder> {
  @BuiltValueField(wireName: r'slide_ids')
  BuiltList<String> get slideIds;

  ReorderSlidesRequest._();

  factory ReorderSlidesRequest([void updates(ReorderSlidesRequestBuilder b)]) = _$ReorderSlidesRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReorderSlidesRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReorderSlidesRequest> get serializer => _$ReorderSlidesRequestSerializer();
}

class _$ReorderSlidesRequestSerializer implements PrimitiveSerializer<ReorderSlidesRequest> {
  @override
  final Iterable<Type> types = const [ReorderSlidesRequest, _$ReorderSlidesRequest];

  @override
  final String wireName = r'ReorderSlidesRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReorderSlidesRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'slide_ids';
    yield serializers.serialize(
      object.slideIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReorderSlidesRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReorderSlidesRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'slide_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.slideIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReorderSlidesRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReorderSlidesRequestBuilder();
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

