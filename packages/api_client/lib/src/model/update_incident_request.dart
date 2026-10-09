//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_incident_request.g.dart';

/// UpdateIncidentRequest
///
/// Properties:
/// * [keyword] 
/// * [address] 
/// * [report] 
/// * [script] 
@BuiltValue()
abstract class UpdateIncidentRequest implements Built<UpdateIncidentRequest, UpdateIncidentRequestBuilder> {
  @BuiltValueField(wireName: r'keyword')
  String? get keyword;

  @BuiltValueField(wireName: r'address')
  String? get address;

  @BuiltValueField(wireName: r'report')
  String? get report;

  @BuiltValueField(wireName: r'script')
  String? get script;

  UpdateIncidentRequest._();

  factory UpdateIncidentRequest([void updates(UpdateIncidentRequestBuilder b)]) = _$UpdateIncidentRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateIncidentRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateIncidentRequest> get serializer => _$UpdateIncidentRequestSerializer();
}

class _$UpdateIncidentRequestSerializer implements PrimitiveSerializer<UpdateIncidentRequest> {
  @override
  final Iterable<Type> types = const [UpdateIncidentRequest, _$UpdateIncidentRequest];

  @override
  final String wireName = r'UpdateIncidentRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateIncidentRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.keyword != null) {
      yield r'keyword';
      yield serializers.serialize(
        object.keyword,
        specifiedType: const FullType(String),
      );
    }
    if (object.address != null) {
      yield r'address';
      yield serializers.serialize(
        object.address,
        specifiedType: const FullType(String),
      );
    }
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
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateIncidentRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateIncidentRequestBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateIncidentRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateIncidentRequestBuilder();
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

