import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/program_item.dart';
import 'dio_provider.dart';

ProgramItemType _typeFromApi(
  GetSnapshot200ResponseProgramItemsInnerTypeEnum type,
) {
  return ProgramItemType.fromWire(type.name);
}

CreateProgramItemRequestTypeEnum _createTypeToApi(ProgramItemType type) {
  switch (type) {
    case ProgramItemType.meal:
      return CreateProgramItemRequestTypeEnum.meal;
    case ProgramItemType.training:
      return CreateProgramItemRequestTypeEnum.training;
    case ProgramItemType.maintenance:
      return CreateProgramItemRequestTypeEnum.maintenance;
    case ProgramItemType.rest:
      return CreateProgramItemRequestTypeEnum.rest;
    case ProgramItemType.other:
      return CreateProgramItemRequestTypeEnum.other;
  }
}

UpdateProgramItemRequestTypeEnum _updateTypeToApi(ProgramItemType type) {
  switch (type) {
    case ProgramItemType.meal:
      return UpdateProgramItemRequestTypeEnum.meal;
    case ProgramItemType.training:
      return UpdateProgramItemRequestTypeEnum.training;
    case ProgramItemType.maintenance:
      return UpdateProgramItemRequestTypeEnum.maintenance;
    case ProgramItemType.rest:
      return UpdateProgramItemRequestTypeEnum.rest;
    case ProgramItemType.other:
      return UpdateProgramItemRequestTypeEnum.other;
  }
}

ProgramItem _programItemFromApi(GetSnapshot200ResponseProgramItemsInner p) {
  return ProgramItem(
    id: p.id,
    bfDayId: p.bfDayId,
    title: p.title,
    type: _typeFromApi(p.type),
    startsAt: DateTime.parse(p.startsAt),
    endsAt: DateTime.parse(p.endsAt),
  );
}

/// Access to Programmpunkte (ADR 0025): `GET/POST
/// /bf-days/{day}/program-items`, `PATCH/DELETE /program-items/{id}`.
///
/// An interface (rather than a concrete class) so tests can substitute a
/// fake without constructing a real [ProgramItemsApi]/`Dio`.
abstract class ProgramItemRepository {
  /// `GET /bf-days/{day}/program-items`: all Programmpunkte of [bfDayId],
  /// sorted by `starts_at`, `ends_at`, `id`.
  Future<List<ProgramItem>> list(String bfDayId);

  /// `POST /bf-days/{day}/program-items`.
  Future<ProgramItem> create(
    String bfDayId, {
    required String title,
    required ProgramItemType type,
    required DateTime startsAt,
    required DateTime endsAt,
  });

  /// `PATCH /program-items/{id}`: only the given fields are sent; the
  /// merged result is validated server-side.
  Future<ProgramItem> update(
    String id, {
    String? title,
    ProgramItemType? type,
    DateTime? startsAt,
    DateTime? endsAt,
  });

  /// `DELETE /program-items/{id}`.
  Future<void> delete(String id);
}

/// [ProgramItemRepository] backed by the generated [ProgramItemsApi].
class ApiProgramItemRepository implements ProgramItemRepository {
  const ApiProgramItemRepository(this._api);

  final ProgramItemsApi _api;

  @override
  Future<List<ProgramItem>> list(String bfDayId) async {
    final response = await _api.listProgramItems(day: bfDayId);
    final data =
        response.data ?? BuiltList<GetSnapshot200ResponseProgramItemsInner>();
    return data.map(_programItemFromApi).toList();
  }

  @override
  Future<ProgramItem> create(
    String bfDayId, {
    required String title,
    required ProgramItemType type,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final response = await _api.createProgramItem(
      day: bfDayId,
      createProgramItemRequest: CreateProgramItemRequest(
        (b) => b
          ..title = title
          ..type = _createTypeToApi(type)
          ..startsAt = startsAt.toUtc()
          ..endsAt = endsAt.toUtc(),
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('POST /bf-days/{day}/program-items returned no body');
    }
    return _programItemFromApi(data);
  }

  @override
  Future<ProgramItem> update(
    String id, {
    String? title,
    ProgramItemType? type,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final response = await _api.updateProgramItem(
      id: id,
      updateProgramItemRequest: UpdateProgramItemRequest(
        (b) => b
          ..title = title
          ..type = type == null ? null : _updateTypeToApi(type)
          ..startsAt = startsAt?.toUtc()
          ..endsAt = endsAt?.toUtc(),
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('PATCH /program-items/{id} returned no body');
    }
    return _programItemFromApi(data);
  }

  @override
  Future<void> delete(String id) async {
    await _api.deleteProgramItem(id: id);
  }
}

final programItemRepositoryProvider = Provider<ProgramItemRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiProgramItemRepository(apiClient.getProgramItemsApi());
});
