//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_snapshot200_response_station.g.dart';

/// GetSnapshot200ResponseStation
///
/// Properties:
/// * [latitude] 
/// * [longitude] 
@BuiltValue()
abstract class GetSnapshot200ResponseStation implements Built<GetSnapshot200ResponseStation, GetSnapshot200ResponseStationBuilder> {
  @BuiltValueField(wireName: r'latitude')
  num get latitude;

  @BuiltValueField(wireName: r'longitude')
  num get longitude;

  GetSnapshot200ResponseStation._();

  factory GetSnapshot200ResponseStation([void updates(GetSnapshot200ResponseStationBuilder b)]) = _$GetSnapshot200ResponseStation;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetSnapshot200ResponseStationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetSnapshot200ResponseStation> get serializer => _$GetSnapshot200ResponseStationSerializer();
}

class _$GetSnapshot200ResponseStationSerializer implements PrimitiveSerializer<GetSnapshot200ResponseStation> {
  @override
  final Iterable<Type> types = const [GetSnapshot200ResponseStation, _$GetSnapshot200ResponseStation];

  @override
  final String wireName = r'GetSnapshot200ResponseStation';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetSnapshot200ResponseStation object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'latitude';
    yield serializers.serialize(
      object.latitude,
      specifiedType: const FullType(num),
    );
    yield r'longitude';
    yield serializers.serialize(
      object.longitude,
      specifiedType: const FullType(num),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetSnapshot200ResponseStation object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetSnapshot200ResponseStationBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'latitude':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.latitude = valueDes;
          break;
        case r'longitude':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.longitude = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetSnapshot200ResponseStation deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetSnapshot200ResponseStationBuilder();
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

