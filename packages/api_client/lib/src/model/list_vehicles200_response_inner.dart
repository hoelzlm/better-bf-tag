//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'list_vehicles200_response_inner.g.dart';

/// ListVehicles200ResponseInner
///
/// Properties:
/// * [id] 
/// * [callSign] 
/// * [shortName] 
/// * [type] 
/// * [status] 
/// * [statusChangedAt] 
/// * [sortOrder] 
/// * [active] 
@BuiltValue()
abstract class ListVehicles200ResponseInner implements Built<ListVehicles200ResponseInner, ListVehicles200ResponseInnerBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'call_sign')
  String get callSign;

  @BuiltValueField(wireName: r'short_name')
  String get shortName;

  @BuiltValueField(wireName: r'type')
  String get type;

  @BuiltValueField(wireName: r'status')
  int get status;

  @BuiltValueField(wireName: r'status_changed_at')
  String? get statusChangedAt;

  @BuiltValueField(wireName: r'sort_order')
  int get sortOrder;

  @BuiltValueField(wireName: r'active')
  bool get active;

  ListVehicles200ResponseInner._();

  factory ListVehicles200ResponseInner([void updates(ListVehicles200ResponseInnerBuilder b)]) = _$ListVehicles200ResponseInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ListVehicles200ResponseInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ListVehicles200ResponseInner> get serializer => _$ListVehicles200ResponseInnerSerializer();
}

class _$ListVehicles200ResponseInnerSerializer implements PrimitiveSerializer<ListVehicles200ResponseInner> {
  @override
  final Iterable<Type> types = const [ListVehicles200ResponseInner, _$ListVehicles200ResponseInner];

  @override
  final String wireName = r'ListVehicles200ResponseInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ListVehicles200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'call_sign';
    yield serializers.serialize(
      object.callSign,
      specifiedType: const FullType(String),
    );
    yield r'short_name';
    yield serializers.serialize(
      object.shortName,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(int),
    );
    yield r'status_changed_at';
    yield object.statusChangedAt == null ? null : serializers.serialize(
      object.statusChangedAt,
      specifiedType: const FullType.nullable(String),
    );
    yield r'sort_order';
    yield serializers.serialize(
      object.sortOrder,
      specifiedType: const FullType(int),
    );
    yield r'active';
    yield serializers.serialize(
      object.active,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ListVehicles200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ListVehicles200ResponseInnerBuilder result,
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
        case r'call_sign':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.callSign = valueDes;
          break;
        case r'short_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.shortName = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.type = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.status = valueDes;
          break;
        case r'status_changed_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.statusChangedAt = valueDes;
          break;
        case r'sort_order':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.sortOrder = valueDes;
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
  ListVehicles200ResponseInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ListVehicles200ResponseInnerBuilder();
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

