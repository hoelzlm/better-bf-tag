import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/device.dart';
import '../domain/pairing_code_item.dart';
import '../domain/permission.dart';
import '../domain/person.dart';
import 'dio_provider.dart';

PersonType _personTypeFromList(ListPersons200ResponseInnerPersonTypeEnum v) {
  return v == ListPersons200ResponseInnerPersonTypeEnum.supervisor
      ? PersonType.supervisor
      : PersonType.youth;
}

Permission _permissionFromList(ListPersons200ResponseInnerPermissionEnum v) {
  if (v == ListPersons200ResponseInnerPermissionEnum.preparation) {
    return Permission.preparation;
  }
  if (v == ListPersons200ResponseInnerPermissionEnum.dispatch) {
    return Permission.dispatch;
  }
  if (v == ListPersons200ResponseInnerPermissionEnum.admin) {
    return Permission.admin;
  }
  return Permission.crew;
}

Person _personFromApi(ListPersons200ResponseInner p) {
  return Person(
    id: p.id,
    displayName: p.displayName,
    personType: _personTypeFromList(p.personType),
    permission: _permissionFromList(p.permission),
    active: p.active,
    hasWebAccess: p.hasWebAccess,
    username: p.username,
  );
}

CreatePersonRequestPersonTypeEnum _personTypeToCreate(PersonType t) {
  return t == PersonType.supervisor
      ? CreatePersonRequestPersonTypeEnum.supervisor
      : CreatePersonRequestPersonTypeEnum.youth;
}

CreatePersonRequestPermissionEnum _permissionToCreate(Permission p) {
  switch (p) {
    case Permission.preparation:
      return CreatePersonRequestPermissionEnum.preparation;
    case Permission.dispatch:
      return CreatePersonRequestPermissionEnum.dispatch;
    case Permission.admin:
      return CreatePersonRequestPermissionEnum.admin;
    case Permission.crew:
      return CreatePersonRequestPermissionEnum.crew;
  }
}

UpdatePersonRequestPersonTypeEnum _personTypeToUpdate(PersonType t) {
  return t == PersonType.supervisor
      ? UpdatePersonRequestPersonTypeEnum.supervisor
      : UpdatePersonRequestPersonTypeEnum.youth;
}

UpdatePersonRequestPermissionEnum _permissionToUpdate(Permission p) {
  switch (p) {
    case Permission.preparation:
      return UpdatePersonRequestPermissionEnum.preparation;
    case Permission.dispatch:
      return UpdatePersonRequestPermissionEnum.dispatch;
    case Permission.admin:
      return UpdatePersonRequestPermissionEnum.admin;
    case Permission.crew:
      return UpdatePersonRequestPermissionEnum.crew;
  }
}

DevicePlatform _platformFromApi(
  ListPersonDevices200ResponseInnerPlatformEnum v,
) {
  return v == ListPersonDevices200ResponseInnerPlatformEnum.ios
      ? DevicePlatform.ios
      : DevicePlatform.android;
}

Device _deviceFromApi(ListPersonDevices200ResponseInner d) {
  return Device(
    id: d.id,
    platform: _platformFromApi(d.platform),
    deviceName: d.deviceName,
    appVersion: d.appVersion,
    createdAt: DateTime.parse(d.createdAt),
    lastSeenAt: DateTime.parse(d.lastSeenAt),
    revokedAt: d.revokedAt == null ? null : DateTime.parse(d.revokedAt!),
  );
}

PairingCodeItem _pairingCodeFromApi(CreatePairingCode201Response r) {
  return PairingCodeItem(
    personId: r.personId,
    displayName: r.displayName,
    code: r.code,
    expiresAt: DateTime.parse(r.expiresAt),
  );
}

/// Admin access to Personen, deren Web-Zugang, Kopplungscodes und Geräte
/// (`GET/POST/PATCH /persons`, `PUT`/`DELETE /persons/{id}/web-access`,
/// `POST /persons/{id}/pairing-code`, `POST /persons/pairing-codes`,
/// `GET /persons/{id}/devices`, `DELETE /devices/{id}`).
///
/// An interface (rather than a concrete class) so tests can substitute a
/// fake without constructing a real [PersonsApi]/[DevicesApi]/`Dio`.
abstract class PersonAdminRepository {
  /// `GET /persons`: all persons (incl. inactive).
  Future<List<Person>> listPersons();

  /// `POST /persons`.
  Future<Person> createPerson({
    required String displayName,
    required PersonType personType,
    required Permission permission,
  });

  /// `PATCH /persons/{id}`: only the given fields are sent.
  Future<Person> updatePerson(
    String id, {
    String? displayName,
    PersonType? personType,
    Permission? permission,
    bool? active,
  });

  /// `PUT /persons/{id}/web-access`.
  Future<Person> setWebAccess(
    String id, {
    required String username,
    required String password,
  });

  /// `DELETE /persons/{id}/web-access`.
  Future<void> removeWebAccess(String id);

  /// `POST /persons/{id}/pairing-code`.
  Future<PairingCodeItem> createPairingCode(String id);

  /// `POST /persons/pairing-codes`: for the given person ids, or all active
  /// persons if `personIds` is null/omitted.
  Future<List<PairingCodeItem>> createPairingCodes({List<String>? personIds});

  /// `GET /persons/{id}/devices`.
  Future<List<Device>> listPersonDevices(String id);

  /// `DELETE /devices/{id}`.
  Future<void> revokeDevice(String id);
}

/// [PersonAdminRepository] backed by the generated [PersonsApi]/[DevicesApi].
class ApiPersonAdminRepository implements PersonAdminRepository {
  const ApiPersonAdminRepository(this._personsApi, this._devicesApi);

  final PersonsApi _personsApi;
  final DevicesApi _devicesApi;

  @override
  Future<List<Person>> listPersons() async {
    final response = await _personsApi.listPersons();
    final data = response.data ?? BuiltList<ListPersons200ResponseInner>();
    return data.map(_personFromApi).toList();
  }

  @override
  Future<Person> createPerson({
    required String displayName,
    required PersonType personType,
    required Permission permission,
  }) async {
    final response = await _personsApi.createPerson(
      createPersonRequest: CreatePersonRequest(
        (b) => b
          ..displayName = displayName
          ..personType = _personTypeToCreate(personType)
          ..permission = _permissionToCreate(permission),
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('POST /persons returned no body');
    }
    return _personFromApi(data);
  }

  @override
  Future<Person> updatePerson(
    String id, {
    String? displayName,
    PersonType? personType,
    Permission? permission,
    bool? active,
  }) async {
    final response = await _personsApi.updatePerson(
      id: id,
      updatePersonRequest: UpdatePersonRequest(
        (b) => b
          ..displayName = displayName
          ..personType =
              personType == null ? null : _personTypeToUpdate(personType)
          ..permission =
              permission == null ? null : _permissionToUpdate(permission)
          ..active = active,
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('PATCH /persons/{id} returned no body');
    }
    return _personFromApi(data);
  }

  @override
  Future<Person> setWebAccess(
    String id, {
    required String username,
    required String password,
  }) async {
    final response = await _personsApi.setWebAccess(
      id: id,
      setWebAccessRequest: SetWebAccessRequest(
        (b) => b
          ..username = username
          ..password = password,
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('PUT /persons/{id}/web-access returned no body');
    }
    return _personFromApi(data);
  }

  @override
  Future<void> removeWebAccess(String id) async {
    await _personsApi.removeWebAccess(id: id);
  }

  @override
  Future<PairingCodeItem> createPairingCode(String id) async {
    final response = await _personsApi.createPairingCode(id: id);
    final data = response.data;
    if (data == null) {
      throw StateError(
        'POST /persons/{id}/pairing-code returned no body',
      );
    }
    return _pairingCodeFromApi(data);
  }

  @override
  Future<List<PairingCodeItem>> createPairingCodes({
    List<String>? personIds,
  }) async {
    final response = await _personsApi.createPairingCodes(
      createPairingCodesRequest: CreatePairingCodesRequest(
        (b) {
          if (personIds != null) {
            b.personIds.addAll(personIds);
          }
        },
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('POST /persons/pairing-codes returned no body');
    }
    return data.items.map(_pairingCodeFromApi).toList();
  }

  @override
  Future<List<Device>> listPersonDevices(String id) async {
    final response = await _personsApi.listPersonDevices(id: id);
    final data =
        response.data ?? BuiltList<ListPersonDevices200ResponseInner>();
    return data.map(_deviceFromApi).toList();
  }

  @override
  Future<void> revokeDevice(String id) async {
    await _devicesApi.revokeDevice(id: id);
  }
}

final personAdminRepositoryProvider = Provider<PersonAdminRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiPersonAdminRepository(
    apiClient.getPersonsApi(),
    apiClient.getDevicesApi(),
  );
});
