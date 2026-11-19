import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/telemetry_data.dart';
import 'telemetry_source.dart';

class TelemetryWebSocketService implements TelemetrySource {
  TelemetryWebSocketService({this.url = 'ws://127.0.0.1:8181/telemetry'});

  final String url;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  bool _isRunning = false;

  @override
  bool get isRunning => _isRunning;

  @override
  void start({required void Function(TelemetryData data) onData}) {
    if (_isRunning) {
      return;
    }

    _isRunning = true;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _subscription = _channel!.stream.listen(
        (message) {
          try {
            if (message is! String) {
              return;
            }

            final decoded = jsonDecode(message);

            if (decoded is! Map<String, dynamic>) {
              return;
            }

            final gearValue = decoded['gear'];

            final gear = switch (gearValue) {
              -1 => 'R',
              0 => 'N',
              int value => value.toString(),
              num value => value.toInt().toString(),
              _ => 'N',
            };

            final data = TelemetryData(
              timestamp: _asDateTime(decoded['timestamp']),
              source: _asString(decoded['source']),
              vehicleId: _asInt(decoded['vehicleId']),
              speed: _asDouble(decoded['speedKmh']),
              rpm: _asDouble(decoded['rpm']).round(),
              maxRpm: _asDouble(decoded['maxRpm']),
              gear: gear,

              throttle: _asDouble(decoded['throttle']),
              brake: _asDouble(decoded['brake']),
              steering: _asDouble(decoded['steering']),
              clutch: _asDouble(decoded['clutch']),
              delta: _asDouble(decoded['deltaBest']),

              vehicle: _asString(decoded['vehicle']),
              vehicleModel: _asString(decoded['model']),
              track: _asString(decoded['track']),

              lap: _asInt(decoded['lap']),
              sector: _asInt(decoded['sector']),

              fuel: _asDouble(decoded['fuel']),
              fuelCapacity: _asDouble(decoded['fuelCapacity']),

              tc: _asInt(decoded['tc']),
              tcMax: _asInt(decoded['tcMax']),
              tcActive: _asBool(decoded['tcActive']),

              abs: _asInt(decoded['abs']),
              absMax: _asInt(decoded['absMax']),
              absActive: _asBool(decoded['absActive']),

              stateOfCharge: _asDouble(decoded['stateOfCharge']),
              regenKw: _asDouble(decoded['regenKw']),
              virtualEnergy: _asDouble(decoded['virtualEnergy']),

              lapInvalidated: _asBool(decoded['lapInvalidated']),

              gapAhead: _asDouble(decoded['gapAhead']),
              gapBehind: _asDouble(decoded['gapBehind']),

              activeVehicles: _asInt(decoded['activeVehicles']),
            );

            onData(data);
          } catch (_) {
            // Egy hibás frame-et figyelmen kívül hagyunk.
            // A következő WebSocket frame továbbra is feldolgozható.
          }
        },
        onError: (_) {
          _cleanupConnection();
        },
        onDone: () {
          _cleanupConnection();
        },
        cancelOnError: false,
      );
    } catch (_) {
      _cleanupConnection();
    }
  }

  double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return 0.0;
  }

  int _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    return false;
  }

  String _asString(dynamic value) {
    if (value is String) {
      return value;
    }

    return '';
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  void _cleanupConnection() {
    _isRunning = false;

    _subscription = null;
    _channel = null;
  }

  @override
  void stop() {
    _isRunning = false;

    _subscription?.cancel();
    _subscription = null;

    _channel?.sink.close();
    _channel = null;
  }

  @override
  void dispose() {
    stop();
  }
}
