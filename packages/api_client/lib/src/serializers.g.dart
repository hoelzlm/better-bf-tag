// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers =
    (Serializers().toBuilder()
          ..add(CreateVehicleRequest.serializer)
          ..add(GetHealth200Response.serializer)
          ..add(GetHealth200ResponseDatabaseEnum.serializer)
          ..add(GetHealth200ResponseStatusEnum.serializer)
          ..add(GetHealth503Response.serializer)
          ..add(GetHealth503ResponseDatabaseEnum.serializer)
          ..add(GetHealth503ResponseStatusEnum.serializer)
          ..add(GetMe200Response.serializer)
          ..add(GetSnapshot200Response.serializer)
          ..add(GetVehicleStatusHistory200ResponseInner.serializer)
          ..add(GetVehicleStatusHistory200ResponseInnerSource_Enum.serializer)
          ..add(ListVehicles200ResponseInner.serializer)
          ..add(Login200Response.serializer)
          ..add(Login200ResponsePerson.serializer)
          ..add(Login200ResponsePersonPermissionEnum.serializer)
          ..add(Login200ResponsePersonPersonTypeEnum.serializer)
          ..add(Login401Response.serializer)
          ..add(Login401ResponseError.serializer)
          ..add(LoginRequest.serializer)
          ..add(ReorderVehiclesRequest.serializer)
          ..add(SetVehicleStatusRequest.serializer)
          ..add(UpdateVehicleRequest.serializer)
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(ListVehicles200ResponseInner),
            ]),
            () => ListBuilder<ListVehicles200ResponseInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          ))
        .build();

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
