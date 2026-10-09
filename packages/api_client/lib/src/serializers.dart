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

import 'package:bftag_api_client/src/model/acknowledge_alarm200_response.dart';
import 'package:bftag_api_client/src/model/close_incident200_response.dart';
import 'package:bftag_api_client/src/model/create_bf_day_request.dart';
import 'package:bftag_api_client/src/model/create_incident_request.dart';
import 'package:bftag_api_client/src/model/create_monitor_pairing_code201_response.dart';
import 'package:bftag_api_client/src/model/create_monitor_request.dart';
import 'package:bftag_api_client/src/model/create_pairing_code201_response.dart';
import 'package:bftag_api_client/src/model/create_pairing_codes201_response.dart';
import 'package:bftag_api_client/src/model/create_pairing_codes_request.dart';
import 'package:bftag_api_client/src/model/create_person_request.dart';
import 'package:bftag_api_client/src/model/create_slide_request.dart';
import 'package:bftag_api_client/src/model/create_vehicle_request.dart';
import 'package:bftag_api_client/src/model/device_refresh_request.dart';
import 'package:bftag_api_client/src/model/get_health200_response.dart';
import 'package:bftag_api_client/src/model/get_health503_response.dart';
import 'package:bftag_api_client/src/model/get_incident200_response.dart';
import 'package:bftag_api_client/src/model/get_me200_response.dart';
import 'package:bftag_api_client/src/model/get_me200_response_crew_assignments_inner.dart';
import 'package:bftag_api_client/src/model/get_snapshot200_response.dart';
import 'package:bftag_api_client/src/model/get_snapshot200_response_alarms_inner.dart';
import 'package:bftag_api_client/src/model/get_snapshot200_response_alarms_inner_recipients_inner.dart';
import 'package:bftag_api_client/src/model/get_snapshot200_response_bf_day.dart';
import 'package:bftag_api_client/src/model/get_snapshot200_response_incidents_inner.dart';
import 'package:bftag_api_client/src/model/get_snapshot200_response_shifts_inner.dart';
import 'package:bftag_api_client/src/model/get_snapshot200_response_shifts_inner_crew_inner.dart';
import 'package:bftag_api_client/src/model/get_snapshot200_response_slides_inner.dart';
import 'package:bftag_api_client/src/model/get_snapshot200_response_slides_inner_image.dart';
import 'package:bftag_api_client/src/model/get_vehicle_status_history200_response_inner.dart';
import 'package:bftag_api_client/src/model/list_bf_days200_response_inner.dart';
import 'package:bftag_api_client/src/model/list_monitors200_response_inner.dart';
import 'package:bftag_api_client/src/model/list_participants200_response_inner.dart';
import 'package:bftag_api_client/src/model/list_person_devices200_response_inner.dart';
import 'package:bftag_api_client/src/model/list_persons200_response_inner.dart';
import 'package:bftag_api_client/src/model/list_vehicles200_response_inner.dart';
import 'package:bftag_api_client/src/model/login200_response.dart';
import 'package:bftag_api_client/src/model/login200_response_person.dart';
import 'package:bftag_api_client/src/model/login401_response.dart';
import 'package:bftag_api_client/src/model/login401_response_error.dart';
import 'package:bftag_api_client/src/model/login_request.dart';
import 'package:bftag_api_client/src/model/monitor_pair200_response.dart';
import 'package:bftag_api_client/src/model/monitor_pair200_response_monitor.dart';
import 'package:bftag_api_client/src/model/monitor_pair_request.dart';
import 'package:bftag_api_client/src/model/pair200_response.dart';
import 'package:bftag_api_client/src/model/pair_request.dart';
import 'package:bftag_api_client/src/model/reorder_slides_request.dart';
import 'package:bftag_api_client/src/model/reorder_vehicles_request.dart';
import 'package:bftag_api_client/src/model/set_participants_request.dart';
import 'package:bftag_api_client/src/model/set_shift_crew_request.dart';
import 'package:bftag_api_client/src/model/set_shift_crew_request_assignments_inner.dart';
import 'package:bftag_api_client/src/model/set_vehicle_status_request.dart';
import 'package:bftag_api_client/src/model/set_web_access_request.dart';
import 'package:bftag_api_client/src/model/trigger_alarm200_response.dart';
import 'package:bftag_api_client/src/model/trigger_alarm200_response_double_crewed_inner.dart';
import 'package:bftag_api_client/src/model/trigger_alarm_request.dart';
import 'package:bftag_api_client/src/model/update_bf_day_request.dart';
import 'package:bftag_api_client/src/model/update_incident_request.dart';
import 'package:bftag_api_client/src/model/update_person_request.dart';
import 'package:bftag_api_client/src/model/update_push_token_request.dart';
import 'package:bftag_api_client/src/model/update_slide_request.dart';
import 'package:bftag_api_client/src/model/update_vehicle_request.dart';

part 'serializers.g.dart';

@SerializersFor([
  AcknowledgeAlarm200Response,
  CloseIncident200Response,
  CreateBfDayRequest,
  CreateIncidentRequest,
  CreateMonitorPairingCode201Response,
  CreateMonitorRequest,
  CreatePairingCode201Response,
  CreatePairingCodes201Response,
  CreatePairingCodesRequest,
  CreatePersonRequest,
  CreateSlideRequest,
  CreateVehicleRequest,
  DeviceRefreshRequest,
  GetHealth200Response,
  GetHealth503Response,
  GetIncident200Response,
  GetMe200Response,
  GetMe200ResponseCrewAssignmentsInner,
  GetSnapshot200Response,
  GetSnapshot200ResponseAlarmsInner,
  GetSnapshot200ResponseAlarmsInnerRecipientsInner,
  GetSnapshot200ResponseBfDay,
  GetSnapshot200ResponseIncidentsInner,
  GetSnapshot200ResponseShiftsInner,
  GetSnapshot200ResponseShiftsInnerCrewInner,
  GetSnapshot200ResponseSlidesInner,
  GetSnapshot200ResponseSlidesInnerImage,
  GetVehicleStatusHistory200ResponseInner,
  ListBfDays200ResponseInner,
  ListMonitors200ResponseInner,
  ListParticipants200ResponseInner,
  ListPersonDevices200ResponseInner,
  ListPersons200ResponseInner,
  ListVehicles200ResponseInner,
  Login200Response,
  Login200ResponsePerson,
  Login401Response,
  Login401ResponseError,
  LoginRequest,
  MonitorPair200Response,
  MonitorPair200ResponseMonitor,
  MonitorPairRequest,
  Pair200Response,
  PairRequest,
  ReorderSlidesRequest,
  ReorderVehiclesRequest,
  SetParticipantsRequest,
  SetShiftCrewRequest,
  SetShiftCrewRequestAssignmentsInner,
  SetVehicleStatusRequest,
  SetWebAccessRequest,
  TriggerAlarm200Response,
  TriggerAlarm200ResponseDoubleCrewedInner,
  TriggerAlarmRequest,
  UpdateBfDayRequest,
  UpdateIncidentRequest,
  UpdatePersonRequest,
  UpdatePushTokenRequest,
  UpdateSlideRequest,
  UpdateVehicleRequest,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(GetSnapshot200ResponseIncidentsInner)]),
        () => ListBuilder<GetSnapshot200ResponseIncidentsInner>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ListBfDays200ResponseInner)]),
        () => ListBuilder<ListBfDays200ResponseInner>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ListParticipants200ResponseInner)]),
        () => ListBuilder<ListParticipants200ResponseInner>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ListPersons200ResponseInner)]),
        () => ListBuilder<ListPersons200ResponseInner>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(GetSnapshot200ResponseSlidesInner)]),
        () => ListBuilder<GetSnapshot200ResponseSlidesInner>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ListMonitors200ResponseInner)]),
        () => ListBuilder<ListMonitors200ResponseInner>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ListVehicles200ResponseInner)]),
        () => ListBuilder<ListVehicles200ResponseInner>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(GetSnapshot200ResponseShiftsInner)]),
        () => ListBuilder<GetSnapshot200ResponseShiftsInner>(),
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
