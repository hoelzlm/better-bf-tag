//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:bftag_api_client/src/model/list_vehicles200_response_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_snapshot200_response.g.dart';

/// GetSnapshot200Response
///
/// Properties:
/// * [seq] 
/// * [vehicles] 
@BuiltValue()
abstract class GetSnapshot200Response implements Built<GetSnapshot200Response, GetSnapshot200ResponseBuilder> {
  @BuiltValueField(wireName: r'seq')
  int get seq;

  @BuiltValueField(wireName: r'vehicles')
  BuiltList<ListVehicles200ResponseInner> get vehicles;

  GetSnapshot200Response._();

  factory GetSnapshot200Response([void updates(GetSnapshot200ResponseBuilder b)]) = _$GetSnapshot200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetSnapshot200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetSnapshot200Response> get serializer => _$GetSnapshot200ResponseSerializer();
}

class _$GetSnapshot200ResponseSerializer implements PrimitiveSerializer<GetSnapshot200Response> {
  @override
  final Iterable<Type> types = const [GetSnapshot200Response, _$GetSnapshot200Response];

  @override
  final String wireName = r'GetSnapshot200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetSnapshot200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'seq';
    yield serializers.serialize(
      object.seq,
      specifiedType: const FullType(int),
    );
    yield r'vehicles';
    yield serializers.serialize(
      object.vehicles,
      specifiedType: const FullType(BuiltList, [FullType(ListVehicles200ResponseInner)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetSnapshot200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetSnapshot200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'seq':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.seq = valueDes;
          break;
        case r'vehicles':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ListVehicles200ResponseInner)]),
          ) as BuiltList<ListVehicles200ResponseInner>;
          result.vehicles.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetSnapshot200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetSnapshot200ResponseBuilder();
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

