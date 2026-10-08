import 'package:web_socket_channel/web_socket_channel.dart';

/// Minimal WebSocket-channel abstraction so [RealtimeClient] can be driven
/// by a fake in tests, without pulling in a real socket.
///
/// Mirrors the shape of `web_socket_channel`'s `WebSocketChannel`
/// (`stream`, `sink.add`, `sink.close`, `closeCode`) so the production
/// implementation is a thin wrapper.
abstract class WebSocketConnection {
  /// Incoming decoded messages (JSON strings).
  Stream<dynamic> get stream;

  WebSocketConnectionSink get sink;

  /// The close code the peer closed with, once [stream] is done.
  /// `null` while still open or if the close code is unknown.
  int? get closeCode;
}

abstract class WebSocketConnectionSink {
  void add(dynamic data);

  Future<void> close([int? closeCode, String? closeReason]);
}

/// Given a URI (including any query parameters, e.g. `?token=...`),
/// returns a connected (or connecting) [WebSocketConnection].
typedef WebSocketConnector = WebSocketConnection Function(Uri uri);

/// Production [WebSocketConnector] backed by `web_socket_channel`. Works on
/// web (via `WebSocketChannel.connect`, dart:html under the hood) and on
/// mobile/desktop (dart:io WebSocket).
WebSocketConnection connectWebSocket(Uri uri) {
  return _ChannelConnection(WebSocketChannel.connect(uri));
}

class _ChannelConnection implements WebSocketConnection {
  _ChannelConnection(this._channel) : sink = _ChannelSink(_channel.sink);

  final WebSocketChannel _channel;

  @override
  final WebSocketConnectionSink sink;

  @override
  Stream<dynamic> get stream => _channel.stream;

  @override
  int? get closeCode => _channel.closeCode;
}

class _ChannelSink implements WebSocketConnectionSink {
  _ChannelSink(this._sink);

  final WebSocketSink _sink;

  @override
  void add(dynamic data) => _sink.add(data);

  @override
  Future<void> close([int? closeCode, String? closeReason]) =>
      _sink.close(closeCode, closeReason);
}
