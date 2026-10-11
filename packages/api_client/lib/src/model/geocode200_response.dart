//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:bftag_api_client/src/model/geocode200_response_results_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'geocode200_response.g.dart';

/// Geocode200Response
///
/// Properties:
/// * [results] 
@BuiltValue()
abstract class Geocode200Response implements Built<Geocode200Response, Geocode200ResponseBuilder> {
  @BuiltValueField(wireName: r'results')
  BuiltList<Geocode200ResponseResultsInner> get results;

  Geocode200Response._();

  factory Geocode200Response([void updates(Geocode200ResponseBuilder b)]) = _$Geocode200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(Geocode200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Geocode200Response> get serializer => _$Geocode200ResponseSerializer();
}

class _$Geocode200ResponseSerializer implements PrimitiveSerializer<Geocode200Response> {
  @override
  final Iterable<Type> types = const [Geocode200Response, _$Geocode200Response];

  @override
  final String wireName = r'Geocode200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Geocode200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'results';
    yield serializers.serialize(
      object.results,
      specifiedType: const FullType(BuiltList, [FullType(Geocode200ResponseResultsInner)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Geocode200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required Geocode200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'results':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Geocode200ResponseResultsInner)]),
          ) as BuiltList<Geocode200ResponseResultsInner>;
          result.results.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Geocode200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = Geocode200ResponseBuilder();
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

