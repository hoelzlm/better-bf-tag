// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trigger_test_alarm200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TriggerTestAlarm200ResponseOutcomeEnum
_$triggerTestAlarm200ResponseOutcomeEnum_delivered =
    const TriggerTestAlarm200ResponseOutcomeEnum._('delivered');
const TriggerTestAlarm200ResponseOutcomeEnum
_$triggerTestAlarm200ResponseOutcomeEnum_rejected =
    const TriggerTestAlarm200ResponseOutcomeEnum._('rejected');
const TriggerTestAlarm200ResponseOutcomeEnum
_$triggerTestAlarm200ResponseOutcomeEnum_invalidToken =
    const TriggerTestAlarm200ResponseOutcomeEnum._('invalidToken');

TriggerTestAlarm200ResponseOutcomeEnum
_$triggerTestAlarm200ResponseOutcomeEnumValueOf(String name) {
  switch (name) {
    case 'delivered':
      return _$triggerTestAlarm200ResponseOutcomeEnum_delivered;
    case 'rejected':
      return _$triggerTestAlarm200ResponseOutcomeEnum_rejected;
    case 'invalidToken':
      return _$triggerTestAlarm200ResponseOutcomeEnum_invalidToken;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<TriggerTestAlarm200ResponseOutcomeEnum>
_$triggerTestAlarm200ResponseOutcomeEnumValues =
    BuiltSet<TriggerTestAlarm200ResponseOutcomeEnum>(
      const <TriggerTestAlarm200ResponseOutcomeEnum>[
        _$triggerTestAlarm200ResponseOutcomeEnum_delivered,
        _$triggerTestAlarm200ResponseOutcomeEnum_rejected,
        _$triggerTestAlarm200ResponseOutcomeEnum_invalidToken,
      ],
    );

Serializer<TriggerTestAlarm200ResponseOutcomeEnum>
_$triggerTestAlarm200ResponseOutcomeEnumSerializer =
    _$TriggerTestAlarm200ResponseOutcomeEnumSerializer();

class _$TriggerTestAlarm200ResponseOutcomeEnumSerializer
    implements PrimitiveSerializer<TriggerTestAlarm200ResponseOutcomeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'delivered': 'delivered',
    'rejected': 'rejected',
    'invalidToken': 'invalid_token',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'delivered': 'delivered',
    'rejected': 'rejected',
    'invalid_token': 'invalidToken',
  };

  @override
  final Iterable<Type> types = const <Type>[
    TriggerTestAlarm200ResponseOutcomeEnum,
  ];
  @override
  final String wireName = 'TriggerTestAlarm200ResponseOutcomeEnum';

  @override
  Object serialize(
    Serializers serializers,
    TriggerTestAlarm200ResponseOutcomeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  TriggerTestAlarm200ResponseOutcomeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => TriggerTestAlarm200ResponseOutcomeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$TriggerTestAlarm200Response extends TriggerTestAlarm200Response {
  @override
  final TriggerTestAlarm200ResponseOutcomeEnum outcome;

  factory _$TriggerTestAlarm200Response([
    void Function(TriggerTestAlarm200ResponseBuilder)? updates,
  ]) => (TriggerTestAlarm200ResponseBuilder()..update(updates))._build();

  _$TriggerTestAlarm200Response._({required this.outcome}) : super._();
  @override
  TriggerTestAlarm200Response rebuild(
    void Function(TriggerTestAlarm200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  TriggerTestAlarm200ResponseBuilder toBuilder() =>
      TriggerTestAlarm200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TriggerTestAlarm200Response && outcome == other.outcome;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, outcome.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'TriggerTestAlarm200Response',
    )..add('outcome', outcome)).toString();
  }
}

class TriggerTestAlarm200ResponseBuilder
    implements
        Builder<
          TriggerTestAlarm200Response,
          TriggerTestAlarm200ResponseBuilder
        > {
  _$TriggerTestAlarm200Response? _$v;

  TriggerTestAlarm200ResponseOutcomeEnum? _outcome;
  TriggerTestAlarm200ResponseOutcomeEnum? get outcome => _$this._outcome;
  set outcome(TriggerTestAlarm200ResponseOutcomeEnum? outcome) =>
      _$this._outcome = outcome;

  TriggerTestAlarm200ResponseBuilder() {
    TriggerTestAlarm200Response._defaults(this);
  }

  TriggerTestAlarm200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _outcome = $v.outcome;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TriggerTestAlarm200Response other) {
    _$v = other as _$TriggerTestAlarm200Response;
  }

  @override
  void update(void Function(TriggerTestAlarm200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TriggerTestAlarm200Response build() => _build();

  _$TriggerTestAlarm200Response _build() {
    final _$result =
        _$v ??
        _$TriggerTestAlarm200Response._(
          outcome: BuiltValueNullFieldError.checkNotNull(
            outcome,
            r'TriggerTestAlarm200Response',
            'outcome',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
