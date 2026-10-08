/// Shared domain types, API wiring, auth session and theme for BF-Tag clients.
library bftag_core;

export 'src/api/api_config.dart';
export 'src/api/auth_interceptor.dart';
export 'src/api/dio_provider.dart';
export 'src/api/monitor_admin_repository.dart';
export 'src/api/person_admin_repository.dart';
export 'src/api/vehicle_admin_repository.dart';
export 'src/auth/auth_session_binding.dart';
export 'src/auth/paired_session.dart';
export 'src/auth/session.dart';
export 'src/auth/token_store.dart';
export 'src/domain/device.dart';
export 'src/domain/fms_status.dart';
export 'src/domain/monitor.dart';
export 'src/domain/pairing_code_item.dart';
export 'src/domain/permission.dart';
export 'src/domain/person.dart';
export 'src/domain/vehicle.dart';
export 'src/realtime/providers.dart';
export 'src/realtime/realtime_client.dart';
export 'src/realtime/realtime_event.dart';
export 'src/realtime/snapshot.dart';
export 'src/realtime/web_socket_connection.dart';
export 'src/theme.dart';
