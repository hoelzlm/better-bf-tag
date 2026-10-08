//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:bftag_api_client/src/model/create_pairing_code201_response.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_pairing_codes201_response.g.dart';

/// CreatePairingCodes201Response
///
/// Properties:
/// * [items] 
@BuiltValue()
abstract class CreatePairingCodes201Response implements Built<CreatePairingCodes201Response, CreatePairingCodes201ResponseBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<CreatePairingCode201Response> get items;

  CreatePairingCodes201Response._();

  factory CreatePairingCodes201Response([void updates(CreatePairingCodes201ResponseBuilder b)]) = _$CreatePairingCodes201Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreatePairingCodes201ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreatePairingCodes201Response> get serializer => _$CreatePairingCodes201ResponseSerializer();
}

class _$CreatePairingCodes201ResponseSerializer implements PrimitiveSerializer<CreatePairingCodes201Response> {
  @override
  final Iterable<Type> types = const [CreatePairingCodes201Response, _$CreatePairingCodes201Response];

  @override
  final String wireName = r'CreatePairingCodes201Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreatePairingCodes201Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(CreatePairingCode201Response)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreatePairingCodes201Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreatePairingCodes201ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CreatePairingCode201Response)]),
          ) as BuiltList<CreatePairingCode201Response>;
          result.items.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreatePairingCodes201Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreatePairingCodes201ResponseBuilder();
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

