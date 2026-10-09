//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bftag_api_client/src/model/get_bf_day_anonymization_preview200_response.dart';
import 'package:bftag_api_client/src/model/list_bf_days200_response_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'anonymize_bf_day200_response.g.dart';

/// AnonymizeBfDay200Response
///
/// Properties:
/// * [bfDay] 
/// * [summary] 
@BuiltValue()
abstract class AnonymizeBfDay200Response implements Built<AnonymizeBfDay200Response, AnonymizeBfDay200ResponseBuilder> {
  @BuiltValueField(wireName: r'bf_day')
  ListBfDays200ResponseInner get bfDay;

  @BuiltValueField(wireName: r'summary')
  GetBfDayAnonymizationPreview200Response get summary;

  AnonymizeBfDay200Response._();

  factory AnonymizeBfDay200Response([void updates(AnonymizeBfDay200ResponseBuilder b)]) = _$AnonymizeBfDay200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AnonymizeBfDay200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AnonymizeBfDay200Response> get serializer => _$AnonymizeBfDay200ResponseSerializer();
}

class _$AnonymizeBfDay200ResponseSerializer implements PrimitiveSerializer<AnonymizeBfDay200Response> {
  @override
  final Iterable<Type> types = const [AnonymizeBfDay200Response, _$AnonymizeBfDay200Response];

  @override
  final String wireName = r'AnonymizeBfDay200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AnonymizeBfDay200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'bf_day';
    yield serializers.serialize(
      object.bfDay,
      specifiedType: const FullType(ListBfDays200ResponseInner),
    );
    yield r'summary';
    yield serializers.serialize(
      object.summary,
      specifiedType: const FullType(GetBfDayAnonymizationPreview200Response),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AnonymizeBfDay200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AnonymizeBfDay200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'bf_day':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ListBfDays200ResponseInner),
          ) as ListBfDays200ResponseInner;
          result.bfDay.replace(valueDes);
          break;
        case r'summary':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GetBfDayAnonymizationPreview200Response),
          ) as GetBfDayAnonymizationPreview200Response;
          result.summary.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AnonymizeBfDay200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AnonymizeBfDay200ResponseBuilder();
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

