// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'acknowledge_alarm200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AcknowledgeAlarm200Response extends AcknowledgeAlarm200Response {
  @override
  final GetSnapshot200ResponseAlarmsInnerRecipientsInner recipient;

  factory _$AcknowledgeAlarm200Response([
    void Function(AcknowledgeAlarm200ResponseBuilder)? updates,
  ]) => (AcknowledgeAlarm200ResponseBuilder()..update(updates))._build();

  _$AcknowledgeAlarm200Response._({required this.recipient}) : super._();
  @override
  AcknowledgeAlarm200Response rebuild(
    void Function(AcknowledgeAlarm200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AcknowledgeAlarm200ResponseBuilder toBuilder() =>
      AcknowledgeAlarm200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AcknowledgeAlarm200Response && recipient == other.recipient;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, recipient.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'AcknowledgeAlarm200Response',
    )..add('recipient', recipient)).toString();
  }
}

class AcknowledgeAlarm200ResponseBuilder
    implements
        Builder<
          AcknowledgeAlarm200Response,
          AcknowledgeAlarm200ResponseBuilder
        > {
  _$AcknowledgeAlarm200Response? _$v;

  GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder? _recipient;
  GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder get recipient =>
      _$this._recipient ??=
          GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder();
  set recipient(
    GetSnapshot200ResponseAlarmsInnerRecipientsInnerBuilder? recipient,
  ) => _$this._recipient = recipient;

  AcknowledgeAlarm200ResponseBuilder() {
    AcknowledgeAlarm200Response._defaults(this);
  }

  AcknowledgeAlarm200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _recipient = $v.recipient.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AcknowledgeAlarm200Response other) {
    _$v = other as _$AcknowledgeAlarm200Response;
  }

  @override
  void update(void Function(AcknowledgeAlarm200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AcknowledgeAlarm200Response build() => _build();

  _$AcknowledgeAlarm200Response _build() {
    _$AcknowledgeAlarm200Response _$result;
    try {
      _$result =
          _$v ?? _$AcknowledgeAlarm200Response._(recipient: recipient.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'recipient';
        recipient.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'AcknowledgeAlarm200Response',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
