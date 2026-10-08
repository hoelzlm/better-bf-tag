//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_vehicle_status_history200_response_inner.g.dart';

/// GetVehicleStatusHistory200ResponseInner
///
/// Properties:
/// * [status] 
/// * [source_] 
/// * [personId] 
/// * [at] 
@BuiltValue()
abstract class GetVehicleStatusHistory200ResponseInner implements Built<GetVehicleStatusHistory200ResponseInner, GetVehicleStatusHistory200ResponseInnerBuilder> {
  @BuiltValueField(wireName: r'status')
  int? get status;

  @BuiltValueField(wireName: r'source')
  GetVehicleStatusHistory200ResponseInnerSource_Enum get source_;
  // enum source_Enum {  app,  dispatch,  system,  };

  @BuiltValueField(wireName: r'person_id')
  String? get personId;

  @BuiltValueField(wireName: r'at')
  String get at;

  GetVehicleStatusHistory200ResponseInner._();

  factory GetVehicleStatusHistory200ResponseInner([void updates(GetVehicleStatusHistory200ResponseInnerBuilder b)]) = _$GetVehicleStatusHistory200ResponseInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetVehicleStatusHistory200ResponseInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetVehicleStatusHistory200ResponseInner> get serializer => _$GetVehicleStatusHistory200ResponseInnerSerializer();
}

class _$GetVehicleStatusHistory200ResponseInnerSerializer implements PrimitiveSerializer<GetVehicleStatusHistory200ResponseInner> {
  @override
  final Iterable<Type> types = const [GetVehicleStatusHistory200ResponseInner, _$GetVehicleStatusHistory200ResponseInner];

  @override
  final String wireName = r'GetVehicleStatusHistory200ResponseInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetVehicleStatusHistory200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield object.status == null ? null : serializers.serialize(
      object.status,
      specifiedType: const FullType.nullable(int),
    );
    yield r'source';
    yield serializers.serialize(
      object.source_,
      specifiedType: const FullType(GetVehicleStatusHistory200ResponseInnerSource_Enum),
    );
    yield r'person_id';
    yield object.personId == null ? null : serializers.serialize(
      object.personId,
      specifiedType: const FullType.nullable(String),
    );
    yield r'at';
    yield serializers.serialize(
      object.at,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetVehicleStatusHistory200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GetVehicleStatusHistory200ResponseInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.status = valueDes;
          break;
        case r'source':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GetVehicleStatusHistory200ResponseInnerSource_Enum),
          ) as GetVehicleStatusHistory200ResponseInnerSource_Enum;
          result.source_ = valueDes;
          break;
        case r'person_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.personId = valueDes;
          break;
        case r'at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.at = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetVehicleStatusHistory200ResponseInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetVehicleStatusHistory200ResponseInnerBuilder();
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

class GetVehicleStatusHistory200ResponseInnerSource_Enum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'app')
  static const GetVehicleStatusHistory200ResponseInnerSource_Enum app = _$getVehicleStatusHistory200ResponseInnerSourceEnum_app;
  @BuiltValueEnumConst(wireName: r'dispatch')
  static const GetVehicleStatusHistory200ResponseInnerSource_Enum dispatch = _$getVehicleStatusHistory200ResponseInnerSourceEnum_dispatch;
  @BuiltValueEnumConst(wireName: r'system')
  static const GetVehicleStatusHistory200ResponseInnerSource_Enum system = _$getVehicleStatusHistory200ResponseInnerSourceEnum_system;

  static Serializer<GetVehicleStatusHistory200ResponseInnerSource_Enum> get serializer => _$getVehicleStatusHistory200ResponseInnerSourceEnumSerializer;

  const GetVehicleStatusHistory200ResponseInnerSource_Enum._(String name): super(name);

  static BuiltSet<GetVehicleStatusHistory200ResponseInnerSource_Enum> get values => _$getVehicleStatusHistory200ResponseInnerSourceEnumValues;
  static GetVehicleStatusHistory200ResponseInnerSource_Enum valueOf(String name) => _$getVehicleStatusHistory200ResponseInnerSourceEnumValueOf(name);
}

