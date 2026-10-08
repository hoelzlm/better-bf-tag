// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_vehicle_status_history200_response_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const GetVehicleStatusHistory200ResponseInnerSource_Enum
_$getVehicleStatusHistory200ResponseInnerSourceEnum_app =
    const GetVehicleStatusHistory200ResponseInnerSource_Enum._('app');
const GetVehicleStatusHistory200ResponseInnerSource_Enum
_$getVehicleStatusHistory200ResponseInnerSourceEnum_dispatch =
    const GetVehicleStatusHistory200ResponseInnerSource_Enum._('dispatch');
const GetVehicleStatusHistory200ResponseInnerSource_Enum
_$getVehicleStatusHistory200ResponseInnerSourceEnum_system =
    const GetVehicleStatusHistory200ResponseInnerSource_Enum._('system');

GetVehicleStatusHistory200ResponseInnerSource_Enum
_$getVehicleStatusHistory200ResponseInnerSourceEnumValueOf(String name) {
  switch (name) {
    case 'app':
      return _$getVehicleStatusHistory200ResponseInnerSourceEnum_app;
    case 'dispatch':
      return _$getVehicleStatusHistory200ResponseInnerSourceEnum_dispatch;
    case 'system':
      return _$getVehicleStatusHistory200ResponseInnerSourceEnum_system;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<GetVehicleStatusHistory200ResponseInnerSource_Enum>
_$getVehicleStatusHistory200ResponseInnerSourceEnumValues =
    BuiltSet<GetVehicleStatusHistory200ResponseInnerSource_Enum>(
      const <GetVehicleStatusHistory200ResponseInnerSource_Enum>[
        _$getVehicleStatusHistory200ResponseInnerSourceEnum_app,
        _$getVehicleStatusHistory200ResponseInnerSourceEnum_dispatch,
        _$getVehicleStatusHistory200ResponseInnerSourceEnum_system,
      ],
    );

Serializer<GetVehicleStatusHistory200ResponseInnerSource_Enum>
_$getVehicleStatusHistory200ResponseInnerSourceEnumSerializer =
    _$GetVehicleStatusHistory200ResponseInnerSource_EnumSerializer();

class _$GetVehicleStatusHistory200ResponseInnerSource_EnumSerializer
    implements
        PrimitiveSerializer<
          GetVehicleStatusHistory200ResponseInnerSource_Enum
        > {
  static const Map<String, Object> _toWire = const <String, Object>{
    'app': 'app',
    'dispatch': 'dispatch',
    'system': 'system',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'app': 'app',
    'dispatch': 'dispatch',
    'system': 'system',
  };

  @override
  final Iterable<Type> types = const <Type>[
    GetVehicleStatusHistory200ResponseInnerSource_Enum,
  ];
  @override
  final String wireName = 'GetVehicleStatusHistory200ResponseInnerSource_Enum';

  @override
  Object serialize(
    Serializers serializers,
    GetVehicleStatusHistory200ResponseInnerSource_Enum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  GetVehicleStatusHistory200ResponseInnerSource_Enum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => GetVehicleStatusHistory200ResponseInnerSource_Enum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$GetVehicleStatusHistory200ResponseInner
    extends GetVehicleStatusHistory200ResponseInner {
  @override
  final int? status;
  @override
  final GetVehicleStatusHistory200ResponseInnerSource_Enum source_;
  @override
  final String? personId;
  @override
  final String at;

  factory _$GetVehicleStatusHistory200ResponseInner([
    void Function(GetVehicleStatusHistory200ResponseInnerBuilder)? updates,
  ]) => (GetVehicleStatusHistory200ResponseInnerBuilder()..update(updates))
      ._build();

  _$GetVehicleStatusHistory200ResponseInner._({
    this.status,
    required this.source_,
    this.personId,
    required this.at,
  }) : super._();
  @override
  GetVehicleStatusHistory200ResponseInner rebuild(
    void Function(GetVehicleStatusHistory200ResponseInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetVehicleStatusHistory200ResponseInnerBuilder toBuilder() =>
      GetVehicleStatusHistory200ResponseInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetVehicleStatusHistory200ResponseInner &&
        status == other.status &&
        source_ == other.source_ &&
        personId == other.personId &&
        at == other.at;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, at.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'GetVehicleStatusHistory200ResponseInner',
          )
          ..add('status', status)
          ..add('source_', source_)
          ..add('personId', personId)
          ..add('at', at))
        .toString();
  }
}

class GetVehicleStatusHistory200ResponseInnerBuilder
    implements
        Builder<
          GetVehicleStatusHistory200ResponseInner,
          GetVehicleStatusHistory200ResponseInnerBuilder
        > {
  _$GetVehicleStatusHistory200ResponseInner? _$v;

  int? _status;
  int? get status => _$this._status;
  set status(int? status) => _$this._status = status;

  GetVehicleStatusHistory200ResponseInnerSource_Enum? _source_;
  GetVehicleStatusHistory200ResponseInnerSource_Enum? get source_ =>
      _$this._source_;
  set source_(GetVehicleStatusHistory200ResponseInnerSource_Enum? source_) =>
      _$this._source_ = source_;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(String? personId) => _$this._personId = personId;

  String? _at;
  String? get at => _$this._at;
  set at(String? at) => _$this._at = at;

  GetVehicleStatusHistory200ResponseInnerBuilder() {
    GetVehicleStatusHistory200ResponseInner._defaults(this);
  }

  GetVehicleStatusHistory200ResponseInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _source_ = $v.source_;
      _personId = $v.personId;
      _at = $v.at;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetVehicleStatusHistory200ResponseInner other) {
    _$v = other as _$GetVehicleStatusHistory200ResponseInner;
  }

  @override
  void update(
    void Function(GetVehicleStatusHistory200ResponseInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  GetVehicleStatusHistory200ResponseInner build() => _build();

  _$GetVehicleStatusHistory200ResponseInner _build() {
    final _$result =
        _$v ??
        _$GetVehicleStatusHistory200ResponseInner._(
          status: status,
          source_: BuiltValueNullFieldError.checkNotNull(
            source_,
            r'GetVehicleStatusHistory200ResponseInner',
            'source_',
          ),
          personId: personId,
          at: BuiltValueNullFieldError.checkNotNull(
            at,
            r'GetVehicleStatusHistory200ResponseInner',
            'at',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
