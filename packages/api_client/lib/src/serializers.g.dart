// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers =
    (Serializers().toBuilder()
          ..add(AcknowledgeAlarm200Response.serializer)
          ..add(CloseIncident200Response.serializer)
          ..add(CreateBfDayRequest.serializer)
          ..add(CreateIncidentRequest.serializer)
          ..add(CreateMonitorPairingCode201Response.serializer)
          ..add(CreateMonitorRequest.serializer)
          ..add(CreatePairingCode201Response.serializer)
          ..add(CreatePairingCodes201Response.serializer)
          ..add(CreatePairingCodesRequest.serializer)
          ..add(CreatePersonRequest.serializer)
          ..add(CreatePersonRequestPermissionEnum.serializer)
          ..add(CreatePersonRequestPersonTypeEnum.serializer)
          ..add(CreateSlideRequest.serializer)
          ..add(CreateVehicleRequest.serializer)
          ..add(DeviceRefreshRequest.serializer)
          ..add(GetHealth200Response.serializer)
          ..add(GetHealth200ResponseDatabaseEnum.serializer)
          ..add(GetHealth200ResponseStatusEnum.serializer)
          ..add(GetHealth503Response.serializer)
          ..add(GetHealth503ResponseDatabaseEnum.serializer)
          ..add(GetHealth503ResponseStatusEnum.serializer)
          ..add(GetIncident200Response.serializer)
          ..add(GetIncident200ResponseStateEnum.serializer)
          ..add(GetMe200Response.serializer)
          ..add(GetMe200ResponseCrewAssignmentsInner.serializer)
          ..add(GetSnapshot200Response.serializer)
          ..add(GetSnapshot200ResponseAlarmsInner.serializer)
          ..add(GetSnapshot200ResponseAlarmsInnerRecipientsInner.serializer)
          ..add(GetSnapshot200ResponseAlarmsInnerStateEnum.serializer)
          ..add(GetSnapshot200ResponseBfDay.serializer)
          ..add(GetSnapshot200ResponseBfDayStateEnum.serializer)
          ..add(GetSnapshot200ResponseIncidentsInner.serializer)
          ..add(GetSnapshot200ResponseIncidentsInnerStateEnum.serializer)
          ..add(GetSnapshot200ResponseShiftsInner.serializer)
          ..add(GetSnapshot200ResponseShiftsInnerCrewInner.serializer)
          ..add(GetSnapshot200ResponseSlidesInner.serializer)
          ..add(GetSnapshot200ResponseSlidesInnerImage.serializer)
          ..add(GetVehicleStatusHistory200ResponseInner.serializer)
          ..add(GetVehicleStatusHistory200ResponseInnerSource_Enum.serializer)
          ..add(ListBfDays200ResponseInner.serializer)
          ..add(ListBfDays200ResponseInnerStateEnum.serializer)
          ..add(ListMonitors200ResponseInner.serializer)
          ..add(ListParticipants200ResponseInner.serializer)
          ..add(ListParticipants200ResponseInnerPermissionEnum.serializer)
          ..add(ListParticipants200ResponseInnerPersonTypeEnum.serializer)
          ..add(ListPersonDevices200ResponseInner.serializer)
          ..add(ListPersonDevices200ResponseInnerPlatformEnum.serializer)
          ..add(ListPersons200ResponseInner.serializer)
          ..add(ListPersons200ResponseInnerPermissionEnum.serializer)
          ..add(ListPersons200ResponseInnerPersonTypeEnum.serializer)
          ..add(ListVehicles200ResponseInner.serializer)
          ..add(Login200Response.serializer)
          ..add(Login200ResponsePerson.serializer)
          ..add(Login200ResponsePersonPermissionEnum.serializer)
          ..add(Login200ResponsePersonPersonTypeEnum.serializer)
          ..add(Login401Response.serializer)
          ..add(Login401ResponseError.serializer)
          ..add(LoginRequest.serializer)
          ..add(MonitorPair200Response.serializer)
          ..add(MonitorPair200ResponseMonitor.serializer)
          ..add(MonitorPairRequest.serializer)
          ..add(Pair200Response.serializer)
          ..add(PairRequest.serializer)
          ..add(PairRequestPlatformEnum.serializer)
          ..add(ReorderSlidesRequest.serializer)
          ..add(ReorderVehiclesRequest.serializer)
          ..add(SetParticipantsRequest.serializer)
          ..add(SetShiftCrewRequest.serializer)
          ..add(SetShiftCrewRequestAssignmentsInner.serializer)
          ..add(SetVehicleStatusRequest.serializer)
          ..add(SetWebAccessRequest.serializer)
          ..add(TriggerAlarm200Response.serializer)
          ..add(TriggerAlarm200ResponseDoubleCrewedInner.serializer)
          ..add(TriggerAlarmRequest.serializer)
          ..add(UpdateBfDayRequest.serializer)
          ..add(UpdateIncidentRequest.serializer)
          ..add(UpdatePersonRequest.serializer)
          ..add(UpdatePersonRequestPermissionEnum.serializer)
          ..add(UpdatePersonRequestPersonTypeEnum.serializer)
          ..add(UpdatePushTokenRequest.serializer)
          ..add(UpdateSlideRequest.serializer)
          ..add(UpdateVehicleRequest.serializer)
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(CreatePairingCode201Response),
            ]),
            () => ListBuilder<CreatePairingCode201Response>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(GetMe200ResponseCrewAssignmentsInner),
            ]),
            () => ListBuilder<GetMe200ResponseCrewAssignmentsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(GetSnapshot200ResponseAlarmsInner),
            ]),
            () => ListBuilder<GetSnapshot200ResponseAlarmsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(GetSnapshot200ResponseShiftsInnerCrewInner),
            ]),
            () => ListBuilder<GetSnapshot200ResponseShiftsInnerCrewInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(ListVehicles200ResponseInner),
            ]),
            () => ListBuilder<ListVehicles200ResponseInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(GetSnapshot200ResponseSlidesInner),
            ]),
            () => ListBuilder<GetSnapshot200ResponseSlidesInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(GetSnapshot200ResponseShiftsInner),
            ]),
            () => ListBuilder<GetSnapshot200ResponseShiftsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(GetSnapshot200ResponseIncidentsInner),
            ]),
            () => ListBuilder<GetSnapshot200ResponseIncidentsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(GetSnapshot200ResponseAlarmsInner),
            ]),
            () => ListBuilder<GetSnapshot200ResponseAlarmsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(SetShiftCrewRequestAssignmentsInner),
            ]),
            () => ListBuilder<SetShiftCrewRequestAssignmentsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(GetSnapshot200ResponseAlarmsInnerRecipientsInner),
            ]),
            () =>
                ListBuilder<GetSnapshot200ResponseAlarmsInnerRecipientsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(TriggerAlarm200ResponseDoubleCrewedInner),
            ]),
            () => ListBuilder<TriggerAlarm200ResponseDoubleCrewedInner>(),
          ))
        .build();

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
