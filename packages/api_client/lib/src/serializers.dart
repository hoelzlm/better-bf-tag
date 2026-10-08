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

import 'package:bftag_api_client/src/model/get_health200_response.dart';
import 'package:bftag_api_client/src/model/get_health503_response.dart';
import 'package:bftag_api_client/src/model/get_me200_response.dart';
import 'package:bftag_api_client/src/model/login200_response.dart';
import 'package:bftag_api_client/src/model/login200_response_person.dart';
import 'package:bftag_api_client/src/model/login401_response.dart';
import 'package:bftag_api_client/src/model/login401_response_error.dart';
import 'package:bftag_api_client/src/model/login_request.dart';

part 'serializers.g.dart';

@SerializersFor([
  GetHealth200Response,
  GetHealth503Response,
  GetMe200Response,
  Login200Response,
  Login200ResponsePerson,
  Login401Response,
  Login401ResponseError,
  LoginRequest,
])
Serializers serializers = (_$serializers.toBuilder()
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer())
    ).build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
