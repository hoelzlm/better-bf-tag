// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_incident_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateIncidentRequest extends UpdateIncidentRequest {
  @override
  final String? keyword;
  @override
  final String? address;
  @override
  final String? report;
  @override
  final String? script;

  factory _$UpdateIncidentRequest([
    void Function(UpdateIncidentRequestBuilder)? updates,
  ]) => (UpdateIncidentRequestBuilder()..update(updates))._build();

  _$UpdateIncidentRequest._({
    this.keyword,
    this.address,
    this.report,
    this.script,
  }) : super._();
  @override
  UpdateIncidentRequest rebuild(
    void Function(UpdateIncidentRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateIncidentRequestBuilder toBuilder() =>
      UpdateIncidentRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateIncidentRequest &&
        keyword == other.keyword &&
        address == other.address &&
        report == other.report &&
        script == other.script;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, keyword.hashCode);
    _$hash = $jc(_$hash, address.hashCode);
    _$hash = $jc(_$hash, report.hashCode);
    _$hash = $jc(_$hash, script.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateIncidentRequest')
          ..add('keyword', keyword)
          ..add('address', address)
          ..add('report', report)
          ..add('script', script))
        .toString();
  }
}

class UpdateIncidentRequestBuilder
    implements Builder<UpdateIncidentRequest, UpdateIncidentRequestBuilder> {
  _$UpdateIncidentRequest? _$v;

  String? _keyword;
  String? get keyword => _$this._keyword;
  set keyword(String? keyword) => _$this._keyword = keyword;

  String? _address;
  String? get address => _$this._address;
  set address(String? address) => _$this._address = address;

  String? _report;
  String? get report => _$this._report;
  set report(String? report) => _$this._report = report;

  String? _script;
  String? get script => _$this._script;
  set script(String? script) => _$this._script = script;

  UpdateIncidentRequestBuilder() {
    UpdateIncidentRequest._defaults(this);
  }

  UpdateIncidentRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _keyword = $v.keyword;
      _address = $v.address;
      _report = $v.report;
      _script = $v.script;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateIncidentRequest other) {
    _$v = other as _$UpdateIncidentRequest;
  }

  @override
  void update(void Function(UpdateIncidentRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateIncidentRequest build() => _build();

  _$UpdateIncidentRequest _build() {
    final _$result =
        _$v ??
        _$UpdateIncidentRequest._(
          keyword: keyword,
          address: address,
          report: report,
          script: script,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
