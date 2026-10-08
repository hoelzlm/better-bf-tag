//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:bftag_api_client/src/date_serializer.dart';
import 'package:bftag_api_client/src/model/date.dart';

import 'package:bftag_api_client/src/model/create_pairing_code201_response.dart';
import 'package:bftag_api_client/src/model/create_pairing_codes201_response.dart';
import 'package:bftag_api_client/src/model/create_pairing_codes_request.dart';
import 'package:bftag_api_client/src/model/create_person_request.dart';
import 'package:bftag_api_client/src/model/create_vehicle_request.dart';
import 'package:bftag_api_client/src/model/device_refresh_request.dart';
import 'package:bftag_api_client/src/model/get_health200_response.dart';
import 'package:bftag_api_client/src/model/get_health503_response.dart';
import 'package:bftag_api_client/src/model/get_me200_response.dart';
import 'package:bftag_api_client/src/model/get_snapshot200_response.dart';
import 'package:bftag_api_client/src/model/get_vehicle_status_history200_response_inner.dart';
import 'package:bftag_api_client/src/model/list_person_devices200_response_inner.dart';
import 'package:bftag_api_client/src/model/list_persons200_response_inner.dart';
import 'package:bftag_api_client/src/model/list_vehicles200_response_inner.dart';
import 'package:bftag_api_client/src/model/login200_response.dart';
import 'package:bftag_api_client/src/model/login200_response_person.dart';
import 'package:bftag_api_client/src/model/login401_response.dart';
import 'package:bftag_api_client/src/model/login401_response_error.dart';
import 'package:bftag_api_client/src/model/login_request.dart';
import 'package:bftag_api_client/src/model/pair200_response.dart';
import 'package:bftag_api_client/src/model/pair_request.dart';
import 'package:bftag_api_client/src/model/reorder_vehicles_request.dart';
import 'package:bftag_api_client/src/model/set_vehicle_status_request.dart';
import 'package:bftag_api_client/src/model/set_web_access_request.dart';
import 'package:bftag_api_client/src/model/update_person_request.dart';
import 'package:bftag_api_client/src/model/update_vehicle_request.dart';

part 'serializers.g.dart';

@SerializersFor([
  CreatePairingCode201Response,
  CreatePairingCodes201Response,
  CreatePairingCodesRequest,
  CreatePersonRequest,
  CreateVehicleRequest,
  DeviceRefreshRequest,
  GetHealth200Response,
  GetHealth503Response,
  GetMe200Response,
  GetSnapshot200Response,
  GetVehicleStatusHistory200ResponseInner,
  ListPersonDevices200ResponseInner,
  ListPersons200ResponseInner,
  ListVehicles200ResponseInner,
  Login200Response,
  Login200ResponsePerson,
  Login401Response,
  Login401ResponseError,
  LoginRequest,
  Pair200Response,
  PairRequest,
  ReorderVehiclesRequest,
  SetVehicleStatusRequest,
  SetWebAccessRequest,
  UpdatePersonRequest,
  UpdateVehicleRequest,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ListPersons200ResponseInner)]),
        () => ListBuilder<ListPersons200ResponseInner>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ListVehicles200ResponseInner)]),
        () => ListBuilder<ListVehicles200ResponseInner>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(GetVehicleStatusHistory200ResponseInner)]),
        () => ListBuilder<GetVehicleStatusHistory200ResponseInner>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ListPersonDevices200ResponseInner)]),
        () => ListBuilder<ListPersonDevices200ResponseInner>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer())
    ).build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
