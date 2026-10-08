//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'monitor_pair200_response_monitor.g.dart';

/// MonitorPair200ResponseMonitor
///
/// Properties:
/// * [id] 
/// * [name] 
@BuiltValue()
abstract class MonitorPair200ResponseMonitor implements Built<MonitorPair200ResponseMonitor, MonitorPair200ResponseMonitorBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  MonitorPair200ResponseMonitor._();

  factory MonitorPair200ResponseMonitor([void updates(MonitorPair200ResponseMonitorBuilder b)]) = _$MonitorPair200ResponseMonitor;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MonitorPair200ResponseMonitorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MonitorPair200ResponseMonitor> get serializer => _$MonitorPair200ResponseMonitorSerializer();
}

class _$MonitorPair200ResponseMonitorSerializer implements PrimitiveSerializer<MonitorPair200ResponseMonitor> {
  @override
  final Iterable<Type> types = const [MonitorPair200ResponseMonitor, _$MonitorPair200ResponseMonitor];

  @override
  final String wireName = r'MonitorPair200ResponseMonitor';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MonitorPair200ResponseMonitor object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MonitorPair200ResponseMonitor object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MonitorPair200ResponseMonitorBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
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
  MonitorPair200ResponseMonitor deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MonitorPair200ResponseMonitorBuilder();
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

