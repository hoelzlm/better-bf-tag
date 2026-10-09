// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_incident_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateIncidentRequest extends CreateIncidentRequest {
  @override
  final String keyword;
  @override
  final String address;
  @override
  final String? report;
  @override
  final String? script;

  factory _$CreateIncidentRequest([
    void Function(CreateIncidentRequestBuilder)? updates,
  ]) => (CreateIncidentRequestBuilder()..update(updates))._build();

  _$CreateIncidentRequest._({
    required this.keyword,
    required this.address,
    this.report,
    this.script,
  }) : super._();
  @override
  CreateIncidentRequest rebuild(
    void Function(CreateIncidentRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateIncidentRequestBuilder toBuilder() =>
      CreateIncidentRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateIncidentRequest &&
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
    return (newBuiltValueToStringHelper(r'CreateIncidentRequest')
          ..add('keyword', keyword)
          ..add('address', address)
          ..add('report', report)
          ..add('script', script))
        .toString();
  }
}

class CreateIncidentRequestBuilder
    implements Builder<CreateIncidentRequest, CreateIncidentRequestBuilder> {
  _$CreateIncidentRequest? _$v;

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

  CreateIncidentRequestBuilder() {
    CreateIncidentRequest._defaults(this);
  }

  CreateIncidentRequestBuilder get _$this {
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
  void replace(CreateIncidentRequest other) {
    _$v = other as _$CreateIncidentRequest;
  }

  @override
  void update(void Function(CreateIncidentRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateIncidentRequest build() => _build();

  _$CreateIncidentRequest _build() {
    final _$result =
        _$v ??
        _$CreateIncidentRequest._(
          keyword: BuiltValueNullFieldError.checkNotNull(
            keyword,
            r'CreateIncidentRequest',
            'keyword',
          ),
          address: BuiltValueNullFieldError.checkNotNull(
            address,
            r'CreateIncidentRequest',
            'address',
          ),
          report: report,
          script: script,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
