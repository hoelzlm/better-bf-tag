//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'set_participants_request.g.dart';

/// SetParticipantsRequest
///
/// Properties:
/// * [personIds] 
@BuiltValue()
abstract class SetParticipantsRequest implements Built<SetParticipantsRequest, SetParticipantsRequestBuilder> {
  @BuiltValueField(wireName: r'person_ids')
  BuiltList<String> get personIds;

  SetParticipantsRequest._();

  factory SetParticipantsRequest([void updates(SetParticipantsRequestBuilder b)]) = _$SetParticipantsRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SetParticipantsRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SetParticipantsRequest> get serializer => _$SetParticipantsRequestSerializer();
}

class _$SetParticipantsRequestSerializer implements PrimitiveSerializer<SetParticipantsRequest> {
  @override
  final Iterable<Type> types = const [SetParticipantsRequest, _$SetParticipantsRequest];

  @override
  final String wireName = r'SetParticipantsRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SetParticipantsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'person_ids';
    yield serializers.serialize(
      object.personIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SetParticipantsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SetParticipantsRequestBuilder result,
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
  SetParticipantsRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SetParticipantsRequestBuilder();
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

