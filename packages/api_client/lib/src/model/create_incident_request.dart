//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_incident_request.g.dart';

/// CreateIncidentRequest
///
/// Properties:
/// * [keyword] 
/// * [address] 
/// * [report] 
/// * [script] 
/// * [latitude] 
/// * [longitude] 
@BuiltValue()
abstract class CreateIncidentRequest implements Built<CreateIncidentRequest, CreateIncidentRequestBuilder> {
  @BuiltValueField(wireName: r'keyword')
  String get keyword;

  @BuiltValueField(wireName: r'address')
  String get address;

  @BuiltValueField(wireName: r'report')
  String? get report;

  @BuiltValueField(wireName: r'script')
  String? get script;

  @BuiltValueField(wireName: r'latitude')
  num? get latitude;

  @BuiltValueField(wireName: r'longitude')
  num? get longitude;

  CreateIncidentRequest._();

  factory CreateIncidentRequest([void updates(CreateIncidentRequestBuilder b)]) = _$CreateIncidentRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateIncidentRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateIncidentRequest> get serializer => _$CreateIncidentRequestSerializer();
}

class _$CreateIncidentRequestSerializer implements PrimitiveSerializer<CreateIncidentRequest> {
  @override
  final Iterable<Type> types = const [CreateIncidentRequest, _$CreateIncidentRequest];

  @override
  final String wireName = r'CreateIncidentRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateIncidentRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'keyword';
    yield serializers.serialize(
      object.keyword,
      specifiedType: const FullType(String),
    );
    yield r'address';
    yield serializers.serialize(
      object.address,
      specifiedType: const FullType(String),
    );
    if (object.report != null) {
      yield r'report';
      yield serializers.serialize(
        object.report,
        specifiedType: const FullType(String),
      );
    }
    if (object.script != null) {
      yield r'script';
      yield serializers.serialize(
        object.script,
        specifiedType: const FullType(String),
      );
    }
    if (object.latitude != null) {
      yield r'latitude';
      yield serializers.serialize(
        object.latitude,
        specifiedType: const FullType.nullable(num),
      );
    }
    if (object.longitude != null) {
      yield r'longitude';
      yield serializers.serialize(
        object.longitude,
        specifiedType: const FullType.nullable(num),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateIncidentRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateIncidentRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'keyword':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.keyword = valueDes;
          break;
        case r'address':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.address = valueDes;
          break;
        case r'report':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.report = valueDes;
          break;
        case r'script':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.script = valueDes;
          break;
        case r'latitude':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.latitude = valueDes;
          break;
        case r'longitude':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
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
  CreateIncidentRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateIncidentRequestBuilder();
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

