//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'trigger_test_alarm200_response.g.dart';

/// TriggerTestAlarm200Response
///
/// Properties:
/// * [outcome] 
@BuiltValue()
abstract class TriggerTestAlarm200Response implements Built<TriggerTestAlarm200Response, TriggerTestAlarm200ResponseBuilder> {
  @BuiltValueField(wireName: r'outcome')
  TriggerTestAlarm200ResponseOutcomeEnum get outcome;
  // enum outcomeEnum {  delivered,  rejected,  invalid_token,  };

  TriggerTestAlarm200Response._();

  factory TriggerTestAlarm200Response([void updates(TriggerTestAlarm200ResponseBuilder b)]) = _$TriggerTestAlarm200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TriggerTestAlarm200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TriggerTestAlarm200Response> get serializer => _$TriggerTestAlarm200ResponseSerializer();
}

class _$TriggerTestAlarm200ResponseSerializer implements PrimitiveSerializer<TriggerTestAlarm200Response> {
  @override
  final Iterable<Type> types = const [TriggerTestAlarm200Response, _$TriggerTestAlarm200Response];

  @override
  final String wireName = r'TriggerTestAlarm200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TriggerTestAlarm200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'outcome';
    yield serializers.serialize(
      object.outcome,
      specifiedType: const FullType(TriggerTestAlarm200ResponseOutcomeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TriggerTestAlarm200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TriggerTestAlarm200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'outcome':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TriggerTestAlarm200ResponseOutcomeEnum),
          ) as TriggerTestAlarm200ResponseOutcomeEnum;
          result.outcome = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TriggerTestAlarm200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TriggerTestAlarm200ResponseBuilder();
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

class TriggerTestAlarm200ResponseOutcomeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'delivered')
  static const TriggerTestAlarm200ResponseOutcomeEnum delivered = _$triggerTestAlarm200ResponseOutcomeEnum_delivered;
  @BuiltValueEnumConst(wireName: r'rejected')
  static const TriggerTestAlarm200ResponseOutcomeEnum rejected = _$triggerTestAlarm200ResponseOutcomeEnum_rejected;
  @BuiltValueEnumConst(wireName: r'invalid_token')
  static const TriggerTestAlarm200ResponseOutcomeEnum invalidToken = _$triggerTestAlarm200ResponseOutcomeEnum_invalidToken;

  static Serializer<TriggerTestAlarm200ResponseOutcomeEnum> get serializer => _$triggerTestAlarm200ResponseOutcomeEnumSerializer;

  const TriggerTestAlarm200ResponseOutcomeEnum._(String name): super(name);

  static BuiltSet<TriggerTestAlarm200ResponseOutcomeEnum> get values => _$triggerTestAlarm200ResponseOutcomeEnumValues;
  static TriggerTestAlarm200ResponseOutcomeEnum valueOf(String name) => _$triggerTestAlarm200ResponseOutcomeEnumValueOf(name);
}

