//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_pairing_codes_request.g.dart';

/// CreatePairingCodesRequest
///
/// Properties:
/// * [personIds] 
@BuiltValue()
abstract class CreatePairingCodesRequest implements Built<CreatePairingCodesRequest, CreatePairingCodesRequestBuilder> {
  @BuiltValueField(wireName: r'person_ids')
  BuiltList<String>? get personIds;

  CreatePairingCodesRequest._();

  factory CreatePairingCodesRequest([void updates(CreatePairingCodesRequestBuilder b)]) = _$CreatePairingCodesRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreatePairingCodesRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreatePairingCodesRequest> get serializer => _$CreatePairingCodesRequestSerializer();
}

class _$CreatePairingCodesRequestSerializer implements PrimitiveSerializer<CreatePairingCodesRequest> {
  @override
  final Iterable<Type> types = const [CreatePairingCodesRequest, _$CreatePairingCodesRequest];

  @override
  final String wireName = r'CreatePairingCodesRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreatePairingCodesRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.personIds != null) {
      yield r'person_ids';
      yield serializers.serialize(
        object.personIds,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreatePairingCodesRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreatePairingCodesRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'person_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.personIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreatePairingCodesRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreatePairingCodesRequestBuilder();
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

