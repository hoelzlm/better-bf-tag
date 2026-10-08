//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_monitor_request.g.dart';

/// CreateMonitorRequest
///
/// Properties:
/// * [name] 
@BuiltValue()
abstract class CreateMonitorRequest implements Built<CreateMonitorRequest, CreateMonitorRequestBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  CreateMonitorRequest._();

  factory CreateMonitorRequest([void updates(CreateMonitorRequestBuilder b)]) = _$CreateMonitorRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateMonitorRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateMonitorRequest> get serializer => _$CreateMonitorRequestSerializer();
}

class _$CreateMonitorRequestSerializer implements PrimitiveSerializer<CreateMonitorRequest> {
  @override
  final Iterable<Type> types = const [CreateMonitorRequest, _$CreateMonitorRequest];

  @override
  final String wireName = r'CreateMonitorRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateMonitorRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateMonitorRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateMonitorRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateMonitorRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateMonitorRequestBuilder();
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

